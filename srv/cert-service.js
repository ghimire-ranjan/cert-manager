const cds = require("@sap/cds");
const {
  today,
  daysUntil,
  criticality,
  addOneYear,
} = require("./lib/expiry.js");

module.exports = class CertService extends cds.ApplicationService {
  init() {
    const { EmployeeCertifications } = this.entities;

    this.before("CREATE", EmployeeCertifications, (req) => {
      const data = req.data;

      if (data.earnedOn) {
        data.validUntil = addOneYear(data.earnedOn);
        data.status = "Pending";
      } else {
        data.validUntil = null;
        if (!data.status) data.status = "Planned";

        if (!["Planned", "LearningJourney"].includes(data.status)) {
          return req.error(400, `Status '${data.status}' needs an earnedOn date`);
        }
      }
    });

    //Fill the virtual fields on every read
    this.after("READ", EmployeeCertifications, (rows) => {
      const now = today();
      for (const row of [].concat(rows)) {
        if (!row.validUntil) continue;
        row.daysUntilExpiry = daysUntil(row.validUntil, now);
        row.expiryCriticality = criticality(row.daysUntilExpiry);
      }
    });

    return super.init();
  }
};
