const cds = require("@sap/cds");

// Every person who gets into the app has an employee record (decided 28 Oct, see
// docs/context.md). On each request:
//   1. found by login ID         -> nothing to do (never changed, even if inactive)
//   2. else prepared by an admin -> same e-mail and an empty Login: fill in the Login
//   3. else                      -> create one from the company login, without a manager
async function ensureEmployee(req) {
  const login = req.user.id;
  // Technical calls (e.g. the database deployer) have no person behind them
  if (!login || req.user.is("system-user")) return;

  // The table itself, not a service's view of it: no @restrict rules apply here
  const { Employees } = cds.entities("cert.manager");
  if (await SELECT.one.from(Employees).where({ userID: login })) return;

  const { email, givenName, familyName } = req.user.attr ?? {};
  if (email) {
    const prepared = await SELECT.one.from(Employees).where({ email, userID: null });
    if (prepared) return UPDATE(Employees, prepared.ID).with({ userID: login });
    // The e-mail belongs to another login: never take it over, leave it to an admin
    if (await SELECT.one.from(Employees).where({ email })) return;
  }

  const name = [givenName, familyName].filter(Boolean).join(" ") || login;
  try {
    await INSERT.into(Employees).entries({ userID: login, name, email });
  } catch (err) {
    // A parallel request of the same person was faster (Fiori sends several at once)
    if (!(await SELECT.one.from(Employees).where({ userID: login }))) throw err;
  }
}

// Runs before every request of the given service
function addFirstLogin(srv) {
  srv.before("*", ensureEmployee);
}

module.exports = { addFirstLogin };
