const cds = require("@sap/cds");
const { addOneYear } = require("./lib/expiry.js");
const { addExpiryFields } = require("./lib/expiry-fields.js");

// The set of statuses that only admins can set
const ADMIN_SET = ["Verified", "Rejected"];

// Server-side rules for one certification record (used by CREATE and UPDATE)
function applyRules(req, data, stored) {
  if (data.earnedOn) {
    data.validUntil = addOneYear(data.earnedOn);
    data.status = ADMIN_SET.includes(stored?.status)
      ? stored.status
      : "Pending";
  } else {
    data.validUntil = null;
    if (!data.status) data.status = "Planned";
    if (!["Planned", "LearningJourney"].includes(data.status)) {
      return req.error(
        400,
        `Status '${data.status}' needs an earnedOn date`,
        "earnedOn",
      );
    }
    if (!data.plannedFor) {
      return req.error(
        400,
        `Status '${data.status}' needs a plannedFor date`,
        "plannedFor",
      );
    }
  }
}

module.exports = class CertService extends cds.ApplicationService {
  init() {
    const { EmployeeCertifications, Employees } = this.entities;

    this.before("CREATE", EmployeeCertifications, async (req) => {
      if (!req.user.is("admin")) {
        const self = await SELECT.one
          .from(Employees)
          .where({ userID: req.user.id });
        if (!self)
          return req.error(403, `No employee record for user '${req.user.id}'`);
        req.data.employee_ID = self.ID;
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
      req.data.status = merged.status;
    });

    addExpiryFields(this, EmployeeCertifications);


    return super.init();
  }
};
