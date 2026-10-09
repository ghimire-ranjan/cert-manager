const cds = require("@sap/cds");
const {
  today,
  daysUntil,
  criticality,
  addOneYear,
} = require("./lib/expiry.js");

// Server-side rules for one certification record (used by CREATE and UPDATE)
function applyRules(req, data) {
  if (data.earnedOn) {
    data.validUntil = addOneYear(data.earnedOn);
    data.status = "Pending";
  } else {
    data.validUntil = null;
    if (!data.status) data.status = "Planned";
    if (!["Planned", "LearningJourney"].includes(data.status)) {
      return req.error(400, `Status '${data.status}' needs an earnedOn date`);
    }
    if (!data.plannedFor) {
      return req.error(400, `Status '${data.status}' needs a plannedFor date`);
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
        );
      }
      const merged = { ...stored, ...req.data };
      applyRules(req, merged);
      req.data.validUntil = merged.validUntil;
      req.data.status = merged.status;
    });

    //Fill the virtual fields on every read
    this.after("READ", EmployeeCertifications, (rows) => {
      const now = today();
      for (const row of rows) {
        if (!row.validUntil) continue;
        row.daysUntilExpiry = daysUntil(row.validUntil, now);
        row.expiryCriticality = criticality(row.daysUntilExpiry);
      }
    });

        // Virtual fields are calculated from validUntil, so always read it
    this.before("READ", EmployeeCertifications, (req) => {
      const columns = req.query.SELECT.columns;
      if (columns && !columns.some((c) => c.ref?.[0] === "validUntil")) {
        columns.push({ ref: ["validUntil"] });
      }
    });


    return super.init();
  }
};
