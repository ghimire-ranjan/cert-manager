const cds = require("@sap/cds");
const { addOneYear } = require("./lib/expiry.js");
const { addExpiryFields } = require("./lib/expiry-fields.js");

// The set of status_codes that only admins can set
const ADMIN_SET = ["Verified", "Rejected"];

// Server-side rules for one certification record (used by CREATE and UPDATE)
function applyRules(req, data, stored) {
  if (data.earnedOn) {
    data.validUntil = addOneYear(data.earnedOn);
    data.status_code  = ADMIN_SET.includes(stored?.status_code )
      ? stored.status_code 
      : "Pending";
  } else {
    data.validUntil = null;
    if (!data.status_code ) data.status_code  = "Planned";
    if (!["Planned", "LearningJourney"].includes(data.status_code )) {
      return req.error(
        400,
        `status  '${data.status_code }' needs an earnedOn date`,
        "earnedOn",
      );
    }
    if (!data.plannedFor) {
      return req.error(
        400,
        `Status  '${data.status_code }' needs a plannedFor date`,
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
      req.data.status_code  = merged.status_code ;
    });

    addExpiryFields(this, EmployeeCertifications);


    return super.init();
  }
};
