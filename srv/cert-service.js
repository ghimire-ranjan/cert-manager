const cds = require("@sap/cds");
const { addOneYear } = require("./lib/expiry.js");
const { addExpiryFields } = require("./lib/expiry-fields.js");
const { addFirstLogin } = require("./lib/first-login.js");


// The set of status_codes that only admins can set
const ADMIN_SET = ["Verified", "Rejected"];

// Server-side rules for one certification record (used by CREATE and UPDATE)
function applyRules(req, data, stored) {
  if (data.earnedOn) {
    data.validUntil = addOneYear(data.earnedOn);
    data.status_code = ADMIN_SET.includes(stored?.status_code)
      ? stored.status_code
      : "Pending";
  } else {
    data.validUntil = null;
    if (!data.status_code) data.status_code = "Planned";
    if (!["Planned", "LearningJourney"].includes(data.status_code)) {
      return req.error(
        400,
        `Status  '${data.status_code}' needs an earnedOn date`,
        "earnedOn",
      );
    }
    if (!data.plannedFor) {
      return req.error(
        400,
        `Status  '${data.status_code}' needs a plannedFor date`,
        "plannedFor",
      );
    }
  }
}

module.exports = class CertService extends cds.ApplicationService {
  init() {
    const { EmployeeCertifications, Employees } = this.entities;
        // Make sure the logged-in person has an employee record (first login)
    addFirstLogin(this);


    // New draft: fill in the logged-in employee straight away
    this.before("NEW", EmployeeCertifications.drafts, async (req) => {
      const self = await SELECT.one
        .from(Employees)
        .where({ userID: req.user.id });
      if (self) req.data.employee_ID = self.ID;
    });

    this.before("CREATE", EmployeeCertifications, async (req) => {
      if (!req.user.is("admin")) {
        const self = await SELECT.one
          .from(Employees)
          .where({ userID: req.user.id });
        if (!self)
          return req.error(403, `No employee record for user '${req.user.id}'`);
        req.data.employee_ID = self.ID;
      }
      // The Employee field is read-only on screen, and CAP lets read-only win over
      // @mandatory, so check it here (e.g. an admin whose login has no employee record)
      if (!req.data.employee_ID) {
        return req.error(
          400,
          `Your login '${req.user.id}' is not linked to an employee. Ask an admin to set it as Login in the Employees app.`,
          "employee_ID",
        );
      }
      applyRules(req, req.data);
    });

    this.before("UPDATE", EmployeeCertifications, async (req) => {
      const stored = await SELECT.one.from(req.subject);
      if (
        !req.user.is("admin") &&
        req.data.employee_ID &&
        req.data.employee_ID !== stored.employee_ID
      ) {
        return req.error(
          403,
          "You can't move a certification to another employee",
          "employee_ID",
        );
      }
      const merged = { ...stored, ...req.data };
      applyRules(req, merged, stored);
      req.data.validUntil = merged.validUntil;
      req.data.status_code = merged.status_code;
    });

    addExpiryFields(this, EmployeeCertifications);

    // --- Actions for AI assistants ---------------------------------------------
    const { Certifications } = this.entities;

    // Find a catalogue entry by its exam code, or report a clear error
    const findCertificate = async (req, code) => {
      const cert = await SELECT.one.from(Certifications).where({ code });
      if (!cert) req.error(404, `No certification with code '${code}'`, "code");
      return cert;
    };

    this.on("planCertification", async (req) => {
      const { code, plannedFor } = req.data;
      const cert = await findCertificate(req, code);
      if (!cert) return;
      const self = await SELECT.one
        .from(Employees)
        .where({ userID: req.user.id });
      const ID = cds.utils.uuid();
      await this.run(
        INSERT.into(EmployeeCertifications).entries({
          ID,
          employee_ID: self?.ID,
          certificate_ID: cert.ID,
          plannedFor,
          status_code: "Planned",
        }),
      );
      return this.run(SELECT.one.from(EmployeeCertifications).where({ ID }));
    });

    this.on("submitCertification", async (req) => {
      const { code, earnedOn, evidenceUrl } = req.data;
      if (evidenceUrl && !evidenceUrl.startsWith("https://")) {
        return req.error(
          400,
          "evidenceUrl must start with https://",
          "evidenceUrl",
        );
      }
      const cert = await findCertificate(req, code);
      if (!cert) return;
      const self = await SELECT.one
        .from(Employees)
        .where({ userID: req.user.id });

      // A plan for this certification? Then update it instead of creating a second record
      const plan = await this.run(
        SELECT.one.from(EmployeeCertifications).where({
          certificate_ID: cert.ID,
          employee_ID: self?.ID,
          status_code: { in: ["Planned", "LearningJourney"] },
        }),
      );
      if (plan) {
        await this.run(
          UPDATE(EmployeeCertifications, plan.ID).with({
            earnedOn,
            evidenceUrl,
          }),
        );
        return this.run(
          SELECT.one.from(EmployeeCertifications).where({ ID: plan.ID }),
        );
      }

      const ID = cds.utils.uuid();
      await this.run(
        INSERT.into(EmployeeCertifications).entries({
          ID,
          employee_ID: self?.ID,
          certificate_ID: cert.ID,
          earnedOn,
          evidenceUrl,
        }),
      );
      return this.run(SELECT.one.from(EmployeeCertifications).where({ ID }));
    });

    return super.init();
  }
};
