# Change record

As of 2026-10-12.

cert-manager went from not starting at all to a working list report and object page,
across four commits on 10 and 12 October 2026. One change is unfinished and currently
breaks every create or update that carries an `earnedOn` date, which is the first thing
to fix.

## Changes made

Newest first.

| Date | Change | Why it mattered |
| --- | --- | --- |
| 12 Oct | `applyRules` keeps an admin-set status instead of forcing `Pending` | Without it, approving a record then editing it would silently demote it back. **Incomplete, see below.** |
| 10 Oct | Object page: `UI.HeaderInfo`, two facets, two field groups | Clicking any row gave a blank detail page |
| 10 Oct | Evidence URL rendered as `UI.DataFieldWithUrl` | The link was plain text and could not be clicked |
| 10 Oct | Six missing i18n keys added to `_i18n/i18n.properties` | Table headers read `CertCode`, `CertName`, `EmployeeName` as raw keys |
| 10 Oct | Catalogue replaced with 10 current SAP certifications | Microsoft, AWS and Scrum entries contradicted the 12-month validity rule |
| 10 Oct | Certification titles corrected to "SAP Certified Associate - ..." | The old "SAP Certified - ..." form is pre-2023 naming |
| 10 Oct | Seed row 10 `validUntil` corrected to 2027-08-01 | It contradicted the service's own `addOneYear` logic |
| 10 Oct | `@readonly` on `validUntil`, `daysUntilExpiry`, `expiryCriticality` | Server-derived values were offered to the user as editable inputs |
| 10 Oct | Target element added to three `req.error` calls | Fiori elements could not highlight which field was wrong |
| 10 Oct | `@sap/cds-dk` added as a devDependency | The `cds` CLI was gone; installing it locally survives the next Node upgrade |
| 10 Oct | Node upgraded from 20.19.4 to 24.21.0 | `@sap/cds` 10 requires Node 22 or higher and refused to start |

## Needs finishing

Commit `f0e8f7f` changed the body of `applyRules` to read `stored?.status`, but left the
signature as `function applyRules(req, data)`. `stored` is not a parameter and not in
scope, so the line throws a `ReferenceError` on every create or update that carries an
`earnedOn` date.

The fix is one word in `srv/cert-service.js`:

```javascript
function applyRules(req, data, stored) {
```

The `before UPDATE` handler already passes `stored` as the third argument, so nothing
else changes. The `before CREATE` handler passes only two arguments, which is correct:
`stored` is `undefined` there, and `stored?.status` handles that.

## Deferred by decision

These were found and left alone on purpose, not overlooked.

| Item | Why it was parked |
| --- | --- |
| Auth profile: wrap mocked auth in `[development]`, add `[production]` with `xsuaa` | Only matters at deploy time, and deployment is the last phase. As it stands a deployed app would accept `chris` / `chris` from anyone |
| `@Capabilities` annotations so the UI reflects the restrict rules | `$metadata` is byte-identical for admin and normal users, so a static `Deletable: false` would hide Delete from the admin too. Needs a per-row virtual field instead |
| `@mandatory` on `employee` fires before the `before CREATE` handler can auto-fill `employee_ID` | CAP handler ordering. Worth raising with a senior rather than working around quietly |
| One-line comment in `srv/lib/expiry.js` recording the 12-month assumption | Turns a hard-coded `+1 year` from an apparent oversight into a stated scope decision |
| README still says "Welcome to your new CAP project" | Easier to write once there is a finished thing to describe |

## Next steps

1. Add `stored` to the `applyRules` signature. Everything below is blocked until writes
   work again.
2. New `AdminService` requiring the `admin` role, exposing `approve` and `reject` as
   bound actions. Backend only, verifiable with curl before any UI exists. A separate
   service keeps the admin annotations off the employee-facing app.
3. Admin Fiori app over that service, with tabs for All, Pending, Verified and Rejected
   driven by `UI.SelectionPresentationVariant`. Annotations only, no JavaScript.
4. Employees master data app. This one wants `@odata.draft.enabled` and a value help on
   `manager`.
5. Change history via `@cap-js/change-tracking`, which adds an audit facet to the object
   page for a few lines of annotation.
6. README.
7. Deployment: auth profile, `xs-security.json`, and an MTA build for BTP.
