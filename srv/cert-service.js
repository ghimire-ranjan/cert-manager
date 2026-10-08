const cds = require("@sap/cds");
const { today, daysUntil, criticality } = require("./lib/expiry.js");

module.exports = class CertService extends cds.ApplicationService {
  init() {
    const { EmployeeCertifications } = this.entities;

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

