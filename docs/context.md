# cert-manager: project context

Last updated: 2026-10-12

Read this first. It explains what the project is, how it works and where things are.

## What it is

A small SAP CAP app that tracks which employees hold which SAP certifications, and when
each one expires.

- Employees record certifications they plan to do, are studying for, or have passed.
- Managers can see their team's certifications.
- An admin checks the evidence and approves (Verified) or rejects the record.
- The app shows how many days are left before each certification expires, coloured
  green, orange or red.

Built by Ranjan Ghimire as a learning project for the SAP CAP backend (C_CPE) and Fiori
(C_FIORD) certifications. Keep it simple: plain CAP and Fiori elements, no extra
frameworks.

## Tech stack

| Part | What we use |
| --- | --- |
| Backend | SAP CAP (`@sap/cds` 10), Node.js 22 or higher (currently 24.21.0) |
| Database | SQLite in memory for local dev (`@cap-js/sqlite`) |
| UI | Fiori elements List Report + Object Page, OData V4, UI5 1.153, theme `sap_horizon` |
| Login | CAP "mocked" users for local dev (no real login yet) |

## How to run it

```powershell
cd C:\Users\RanjanGhimire\Projects\cert-manager
npm install
npx cds watch
```

Open <http://localhost:4004/certifications/webapp/index.html> and log in with one of these
users. The password is the same as the username.

| User | Role | Manager | Use it to test |
| --- | --- | --- | --- |
| `chris` | admin | none | Sees and changes everything |
| `dan` | normal | chris | Manager view: sees ranjan's and erik's records |
| `ranjan` | normal | dan | Normal employee |
| `erik` | normal | dan | Normal employee |

The seed data also has `john`, an inactive employee with no login.

## Words we use

| Word | Meaning |
| --- | --- |
| Certification | An item in the catalogue, e.g. `C_CPE`. Table `Certifications`. |
| Employee | A person. `userID` matches their login name. Table `Employees`. |
| Employee certification | One employee + one certification + dates + status. The main table: `EmployeeCertifications`. |
| `earnedOn` | Date the exam was passed. If empty, the certification is not earned yet. |
| `plannedFor` | Target exam date, used before the certification is earned. |
| `validUntil` | Expiry date. Always calculated as `earnedOn` + 12 months. Users cannot type it. |
| Days left | `daysUntilExpiry`, calculated on every read. Not stored. |
| Criticality | The colour of "Days left": green over 90 days, neutral 46-90, orange 16-45, red 15 or less. |
| Approve | Admin action: `Pending` -> `Verified`. |
| Reject | Admin action: `Pending` -> `Rejected`. No reason is recorded (yet). |
| Revoke | Admin action: `Verified` or `Rejected` -> `Pending`. Undoes a decision and re-opens the record so the employee can edit it. |

## Status flow

```text
Planned  ->  LearningJourney  ->  Pending  --approve-->  Verified
                                     |                      |
                                     +----reject--->  Rejected
                                                            |
                       Pending  <--------revoke-------------+  (from Verified or Rejected)
```

- **Planned** / **LearningJourney**: not earned yet. Needs a `plannedFor` date.
- **Pending**: the employee entered an `earnedOn` date. Waiting for the admin.
- **Verified** / **Rejected**: set by the admin only, with Approve or Reject.
- Approve and Reject work only on `Pending`. Revoke works only on `Verified` or
  `Rejected`. Any other status gives an error.
- Approve does not check the evidence link.
- To fix a rejected record: the admin revokes it (back to `Pending`), then the employee
  edits it, then the admin approves it.

## Business rules

These live in `srv/cert-service.js`, in the `applyRules` function and the handlers.

1. If `earnedOn` is filled in, `validUntil` = `earnedOn` + 1 year and the status becomes
   `Pending`. A record already `Verified` or `Rejected` keeps its status.
2. If `earnedOn` is empty, `validUntil` is cleared, the status must be `Planned` or
   `LearningJourney`, and `plannedFor` is required.
3. When a normal user creates a record, it is always linked to their own employee
   record. If they have no employee record they get a 403 error.
4. A normal user cannot move a record to another employee, and cannot edit their own
   record once it is `Verified` or `Rejected`.
5. 29 February + 1 year = 28 February.
6. All SAP certifications are treated as valid for 12 months.

## Who can do what

Defined with `@restrict`. You must be logged in to use any service.

**CertService** (`srv/cert-service.cds`, the existing "Certifications" app, for everyone):

| Table | Normal user | Manager | Admin |
| --- | --- | --- | --- |
| Certifications | Read | Read | Everything |
| Employees | Read | Read | Everything |
| EmployeeCertifications | Read and create **own** records. Update own only while `Planned`, `LearningJourney` or `Pending`. Delete own only while `Planned` or `LearningJourney` | Also reads direct reports' records, **except `Rejected`** | Everything |

**AdminService** (`srv/admin-service.cds` + `.js`, at `/odata/v4/admin`, admin role only):

| Table | Admin can |
| --- | --- |
| Employees | Everything |
| EmployeeCertifications | Read all, plus the Approve, Reject and Revoke actions. No direct edits here. |
| Certifications | Read (for drop-down lists) |

Managers do not use AdminService. A read-only "My Team" app for managers is parked.

## Where things are

| File | What it does |
| --- | --- |
| `db/schema.cds` | Data model: 3 tables and the `Status` list |
| `db/data/*.csv` | Seed data: 10 SAP certifications, 5 employees, 10 records |
| `srv/cert-service.cds` | The OData service `CertService` and who can do what |
| `srv/cert-service.js` | Business rules (before CREATE/UPDATE) and the days-left calculation (READ) |
| `srv/admin-service.cds` | `AdminService` for the admin apps: entities and the approve / reject / revoke actions |
| `srv/admin-service.js` | The action logic: one `changeStatus` helper that checks the current status |
| `srv/lib/expiry.js` | Date helpers: `today`, `addOneYear`, `daysUntil`, `criticality` |
| `app/certifications/annotations.cds` | Fiori UI: table columns, filter bar, object page |
| `app/certifications/webapp/` | Generated Fiori app (`manifest.json` etc.). Usually no need to edit. |
| `app/approvals/annotations.cds` | Fiori UI for the admin **Approvals** app (on AdminService) |
| `app/approvals/webapp/` | Generated Approvals app. Open at `/approvals/webapp/index.html` |
| `app/labels.cds` | Field labels (`@Common.Label`) on the database entities, shared by every service and app |
| `app/services.cds` | Pulls the labels and the UI annotations of both apps into the build |
| `_i18n/i18n.properties` | All UI texts. Label keys used by `app/labels.cds` live here |
| `package.json` | Dependencies, scripts, mocked users |
| `test/admin.http` | Manual API tests (REST Client extension). Run requests 1-9 in order after starting the server |
| `docs/CHANGELOG.md` | Every change, newest first |
| `docs/tasks/todo.md` | Open bug, next steps, things parked on purpose |

The OData service runs at `http://localhost:4004/odata/v4/cert/`.

## Decisions made

| Decision | Why |
| --- | --- |
| No `validMonths` field; every certification lasts 12 months | All current SAP certifications are 12 months. Simpler. |
| `validUntil` is stored, but days left and colour are calculated on read | Days left changes every day, so it cannot be stored |
| The READ handler always fetches `validUntil` | Without it, days left is empty when the UI does not ask for that column |
| Catalogue is SAP-only, with "SAP Certified Associate - ..." names | Non-SAP certifications broke the 12-month rule; the names match current SAP naming |
| Labels via `@Common.Label` + i18n, not inside `UI.LineItem` | One label per field, reused by the table, filter and object page |
| Labels live on the database entities (`app/labels.cds`), not on a service | Every service built on the entities inherits them, so both apps share one set |
| Error messages name the field (`req.error(400, msg, "earnedOn")`) | Fiori highlights the wrong field in red |
| Approve / reject / revoke go in a separate `AdminService` (admin only) | Keeps admin-only things out of the employee app |
| One audience per service: admin apps on `AdminService`, a future manager app on its own `TeamService` | The UI shows the same buttons to every user of a service, so mixing roles shows buttons that fail with 403 |
| Employees cannot edit `Verified` or `Rejected` records | Stops an employee changing dates on an approved record without review |
| Managers do not see their team's `Rejected` records | Decided by Ranjan, 12 Oct 2026 |

## Git

- Remote: `https://github.com/ghimire-ranjan/cert-manager.git`
- `main` on GitHub: up to step 5d (9 Oct). Local `main` is at step 6 but not pushed.
- `fixes`: step 6 (6a-6c and the first changelog).
- `story/admin-service` (from `fixes`): step 7, AdminService + docs. Pushed, finished.
- `story/approvals-app` (from `story/admin-service`): step 8, the Approvals Fiori app.
  Current work.
- New work goes on a `story/<short-name>` branch.
- Commit messages follow the step numbers: `1`, `2`, `3a`, `3b` ... `6c`.
- Pushing needs the `ghimire-ranjan` GitHub account. The `ranjan-ghimire` work account gets
  a 403 error.
