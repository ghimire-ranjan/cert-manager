const { today, daysUntil, criticality } = require("./expiry.js");

// Adds daysUntilExpiry and expiryCriticality to every read of an entity.
// Used by CertService and AdminService, so the logic lives in one place.
function addExpiryFields(srv, entity) {
  // Virtual fields are calculated from validUntil, so always read it
  srv.before("READ", entity, (req) => {
    const columns = req.query.SELECT.columns;
    if (columns && !columns.some((c) => c.ref?.[0] === "validUntil")) {
      columns.push({ ref: ["validUntil"] });
    }
  });

  // Fill the virtual fields on every read
  srv.after("READ", entity, (rows) => {
    const now = today();
    for (const row of rows) {
      if (!row.validUntil) continue;
      row.daysUntilExpiry = daysUntil(row.validUntil, now);
      row.expiryCriticality = criticality(row.daysUntilExpiry);
    }
  });
}

module.exports = { addExpiryFields };
