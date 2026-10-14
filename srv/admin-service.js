const cds = require("@sap/cds");
const { addExpiryFields } = require("./lib/expiry-fields.js");

async function changestatus (req, oldstatus , newstatus ) {
  const record = await SELECT.one.from(req.subject);
  if (!record) return req.error(404, "Record not found");
  if (!oldstatus .includes(record.status_code )) {
    return req.error(
      400,
      `Only ${oldstatus .join(" or ")} records can be changed to ${newstatus }`,
    );
  }

  await UPDATE(req.subject).with({ status_code : newstatus  });
  return SELECT.one.from(req.subject);
}

module.exports = class AdminService extends cds.ApplicationService {
  init() {
    const { EmployeeCertifications } = this.entities;
    this.on("approve", EmployeeCertifications, (req) =>
      changestatus (req, ["Pending"], "Verified"),
    );

    this.on("reject", EmployeeCertifications, (req) =>
      changestatus (req, ["Pending"], "Rejected"),
    );

    this.on("revoke", EmployeeCertifications, (req) =>
      changestatus (req, ["Verified", "Rejected"], "Pending"),
    );
    addExpiryFields(this, EmployeeCertifications);

    return super.init();
  }
};
