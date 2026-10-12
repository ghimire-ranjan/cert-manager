const cds = require("@sap/cds");

async function changeStatus(req, oldStatus, newStatus) {
  const record = await SELECT.one.from(req.subject);
  if (!record) return req.error(404, "Record not found");
  if (!oldStatus.includes(record.status)) {
    return req.error(
      400,
      `Only ${oldStatus.join(" or ")} records can be changed to ${newStatus}`,
    );
  }

  await UPDATE(req.subject).with({ status: newStatus });
  return SELECT.one.from(req.subject);
}

module.exports = class AdminService extends cds.ApplicationService {
  init() {
    const { EmployeeCertifications } = this.entities;
    this.on("approve", EmployeeCertifications, (req) =>
      changeStatus(req, ["Pending"], "Verified"),
    );

    this.on("reject", EmployeeCertifications, (req) =>
      changeStatus(req, ["Pending"], "Rejected"),
    );

    this.on("revoke", EmployeeCertifications, (req) =>
      changeStatus(req, ["Verified", "Rejected"], "Pending"),
    );
    return super.init();
  }
};
