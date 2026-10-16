const cds = require("@sap/cds");
const { addExpiryFields } = require("./lib/expiry-fields.js");

// Move one record from an allowed status to a new one (used by all approve / reject / revoke)
async function changeStatus(req, EmployeeCertifications, ID, oldStatus, newStatus) {
  const record = await SELECT.one.from(EmployeeCertifications, ID);
  if (!record) return req.error(404, "Record not found");
  if (!oldStatus.includes(record.status_code)) {
    return req.error(
      400,
      `Only ${oldStatus.join(" or ")} records can be changed to ${newStatus}`,
    );
  }

  await UPDATE(EmployeeCertifications, ID).with({ status_code: newStatus });
  return SELECT.one.from(EmployeeCertifications, ID);
}

// Readable checks before an employee is saved.
// (The database also blocks a duplicate userID, but only with a technical 500 error.)
async function checkEmployee(req, Employees) {
  // On UPDATE, req.data holds only the changed fields, so merge with the stored record
  const stored = req.event === "UPDATE" ? await SELECT.one.from(req.subject) : {};
  const employee = { ...stored, ...req.data };

  if (employee.manager_ID && employee.manager_ID === employee.ID) {
    return req.error(400, "An employee can't be their own manager", "manager_ID");
  }

  const sameLogin = await SELECT.one
    .from(Employees)
    .where({ userID: employee.userID, ID: { "!=": employee.ID } });
  if (sameLogin) {
    return req.error(
      400,
      `Login '${employee.userID}' is already used by ${sameLogin.name}`,
      "userID",
    );
  }
}

module.exports = class AdminService extends cds.ApplicationService {
  init() {
    const { EmployeeCertifications, Employees } = this.entities;

    this.before(["CREATE", "UPDATE"], Employees, (req) =>
      checkEmployee(req, Employees),
    );

    // Bound actions (the buttons in the Approvals and Employees apps): the record they are
    // called on comes in req.params
    const recordID = (req) => req.params[0].ID ?? req.params[0];

    this.on("approve", EmployeeCertifications, (req) =>
      changeStatus(req, EmployeeCertifications, recordID(req), ["Pending"], "Verified"),
    );

    this.on("reject", EmployeeCertifications, (req) =>
      changeStatus(req, EmployeeCertifications, recordID(req), ["Pending"], "Rejected"),
    );

    this.on("revoke", EmployeeCertifications, (req) =>
      changeStatus(req, EmployeeCertifications, recordID(req), ["Verified", "Rejected"], "Pending"),
    );

    addExpiryFields(this, EmployeeCertifications);

    // Unbound actions for AI assistants: find the record by employee login + exam code
    const byEmployeeAndCode = async (req, statuses) => {
      const { userID, code } = req.data;
      const record = await SELECT.one.from(EmployeeCertifications).where({
        "employee.userID": userID,
        "certificate.code": code,
        status_code: { in: statuses },
      });
      if (!record) {
        req.error(404, `No ${statuses.join(" or ")} certification ${code} for '${userID}'`);
      }
      return record;
    };
  

    this.on("approveCertification", async (req) => {
      const record = await byEmployeeAndCode(req, ["Pending"]);
      if (record) return changeStatus(req, EmployeeCertifications, record.ID, ["Pending"], "Verified");
    });

    this.on("rejectCertification", async (req) => {
      const record = await byEmployeeAndCode(req, ["Pending"]);
      if (record) return changeStatus(req, EmployeeCertifications, record.ID, ["Pending"], "Rejected");
    });

    this.on("revokeCertification", async (req) => {
      const record = await byEmployeeAndCode(req, ["Verified", "Rejected"]);
      if (record) return changeStatus(req, EmployeeCertifications, record.ID, ["Verified", "Rejected"], "Pending");
    });

    return super.init();
  }
};
