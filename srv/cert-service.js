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
    const { EmployeeCertifications } = this.entities;

    this.before("CREATE", EmployeeCertifications, (req) => {
      applyRules(req, req.data);
    });

    this.before("UPDATE", EmployeeCertifications, async (req) => {
      const stored = await SELECT.one.from(req.subject);
      const merged = { ...stored, ...req.data };
      console.log(req)
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

    return super.init();
  }
};
