const cds = require("@sap/cds");
const { addExpiryFields } = require("./lib/expiry-fields.js");

async function changeStatus (req, oldStatus , newStatus ) {
  const record = await SELECT.one.from(req.subject);
  if (!record) return req.error(404, "Record not found");
  if (!oldStatus .includes(record.status_code )) {
    return req.error(
      400,
      `Only ${oldStatus .join(" or ")} records can be changed to ${newStatus }`,
    );
  }

  await UPDATE(req.subject).with({ status_code : newStatus  });
  return SELECT.one.from(req.subject);
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

    this.on("approve", EmployeeCertifications, (req) =>
      changeStatus (req, ["Pending"], "Verified"),
    );

    this.on("reject", EmployeeCertifications, (req) =>
      changeStatus (req, ["Pending"], "Rejected"),
    );

    this.on("revoke", EmployeeCertifications, (req) =>
      changeStatus (req, ["Verified", "Rejected"], "Pending"),
    );
    addExpiryFields(this, EmployeeCertifications);

    return super.init();
  }
};
