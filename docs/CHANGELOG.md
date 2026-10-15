# Changelog

Every change to cert-manager, newest first.

**How to add an entry:** after each change, add one line under **Unreleased**: what
changed and why. When you commit, replace "Unreleased" with the date and commit
step, and start a new empty Unreleased section on top.

---

## Unreleased

Branch `story/mcp` (from `main`).

- **12b, switch** (15 Oct) The hand-made `mcp/` server (below) is **removed** and replaced
  by SAP's official plugin **`@cap-js/mcp`** (beta, 1.5.x), as taught in SAP's "CAP in the
  Age of AI" video series (Ranjan's study guide). Changes: dependency `@cap-js/mcp`; new
  `srv/cert-mcp.cds` with `annotate CertService with @mcp @odata;` (`@odata` must stay,
  otherwise only MCP is served); `cds.mcp.autowire` user `ranjan` in `package.json` (the
  plugin writes `cds:CertService` into `~/.claude.json` while `cds watch` runs; its default
  user `alice` is disabled here). Endpoint `/mcp/cert`, tools `describe` and `query`
  (read-only CQL). Why: one annotation instead of ~120 lines and two libraries, runs inside
  CAP with the same rules and handlers, moves to BTP with the app, and `@cap-js/agents`
  (A2A, step 13) reuses its tools. Tested as erik (3), dan (9), chris (10), no login (401);
  Ranjan checked it in the MCP Inspector (ranjan: 3 own records with Days Left; `DELETE`
  rejected by the CQL parser). Lesson: a CAP plugin is only loaded when it is listed in
  `package.json`.
- **12a/12b, first version** (15 Oct, replaced the same day) New `mcp/` folder: an MCP server (`server.js`, own `package.json`
  with `@modelcontextprotocol/sdk` 1.31.0 and `zod` 4; libraries agreed by Ranjan) with
  read-only tools `who_am_i`, `list_certifications` and `list_catalogue`. It calls
  CertService over HTTP as one user (`CERT_USER` / `CERT_PASSWORD`), so the app's
  `@restrict` rules decide what each user sees; no security code in the MCP server.
  Filters use the stored `validUntil` (days left is virtual and cannot be filtered).
  Written by Claude at Ranjan's request (exception to the CLAUDE.md rule). Tested as erik
  (3 own records), dan (9: own + team), chris (all), unknown user (401). Decisions: demo
  on the laptop now, built so it can move to BTP later; reading first, writing next;
  employees and admins both use it.

## 15 Oct 2026: step 9, Employees app

Branch `story/employees-app` (from `main`). Merged into `main` (`91a6a1b`).

- **9a-9c** (15 Oct, `81b2b1f`) `db/schema.cds`: `Employees` gets
  `certifications : Association to many EmployeeCertifications on certifications.employee = $self`
  (no new column) and `@assert.unique` on `userID`. `srv/admin-service.cds`: draft on
  `Employees`, `@Capabilities.DeleteRestrictions.Deletable: false` (the server answers 405,
  not just a hidden button). `srv/cert-service.cds`: `Employees … excluding { certifications }`
  (**security**: without it erik could `$expand` anyone's records; `@restrict` on
  `EmployeeCertifications` does not cover rows pulled in through another entity's link).
  `srv/admin-service.js`: `checkEmployee` gives readable 400s for "own manager" and
  "login already used" (`@assert.unique` alone gives a database 500). Written by Claude at
  Ranjan's request (one-off exception to the CLAUDE.md rule), checked by Ranjan.
- **9d** (`9a2c2b9`) Employees app generated in `app/employees` (List Report V4 on
  AdminService); annotations started empty this time.
- **9e** (`a99e795`, `8d96707`, `fe5f92f`) List page (name, login, email, manager,
  active; filters), object page Details section, manager value help with only active
  employees (`ValueListParameterConstant` on `active`), and a Certifications section
  (`certifications/@UI.LineItem#ForEmployee`) with Days Left and Approve / Reject /
  Revoke buttons (`UI.DataFieldForAction` in the table; `@Core.OperationAvailable` from
  step 8 applies here too). Labels for the employee fields; i18n key `EmployeeLogin`.
  Lessons: the i18n key `UserID` clashes with CAP's built-in text (`User ID` won);
  `@Common.Text` on the key `ID` of an entity that is created in the app makes Fiori ask
  for the key (a GUID) in a "New Object" dialog, so it was removed.
- **9f** (15 Oct) Browser tests passed as chris (approve / revoke from the employee page,
  same status in Approvals, duplicate login and own-manager errors, John Doe not in the
  manager picker, no Delete); erik and dan get 403.

## 15 Oct 2026: step 11, draft in the Certifications app

Branch `story/draft` (from `main`). Merged into `main` (`2624807`).

- **11a/11b** (15 Oct, `71f75ed`) `@odata.draft.enabled` on `EmployeeCertifications` in
  `srv/cert-service.cds`: the Certifications app now has Create and Edit. New handler
  `before('NEW', EmployeeCertifications.drafts)` in `cert-service.js` fills in the
  logged-in employee when a draft starts, for everyone. This solves the parked
  `@mandatory` item (`ASSERT_MANDATORY` on `employee_ID` when saving a new draft).
  The existing `before CREATE` / `before UPDATE` rules run on Save, unchanged.
- **11c** (15 Oct, `61c27ce`) Object page shows `certificate_ID` with a value help on
  `Certifications` (code, name) and `@Common.Text: certificate.name`, and `employee_ID`
  with `@Common.Text: employee.name` and `@Common.FieldControl: #ReadOnly`.
  `Certifications.ID` gets `@Common.Text: name` so the value help shows names. Lesson: a
  path like `certificate.code` can only be shown, not picked; the editable field is the
  link itself (`certificate_ID`).
- **11d** (15 Oct) Tested in the browser: ranjan created a plan (Planned) and an earned
  cert (Pending, valid until +1 year, 364 days); edit, self-verify message, 403 on
  editing a Verified record, delete of a Planned record; chris gets himself filled in;
  dan gets 403 on Edit of a team record. The Status filter shows "Learning Journey"
  (closes 10g).
- **11c+** prototyped and dropped: admin-only editable Employee field (dynamic
  `FieldControl`). Not needed by the concept; notes kept in `docs/tasks/todo.md`.
- **11e** Docs: parked `@mandatory` item removed, draft decisions in `docs/context.md`.

## 15 Oct 2026: step 10, status as a code list

Branch `story/status-codelist` (from `main`). Merged into `main` (`d79a20a`).

- **10** (14 Oct, `5874b43`) Status is now a code list. `db/schema.cds`: the `Status` enum
  became `entity Statuses : sap.common.CodeList { key code }`, and
  `status : Association to Statuses default 'Planned' @assert.target` (column
  `status_code`). New `db/data/cert.manager-Statuses.csv` (5 codes, readable names). Both
  services expose `Statuses` read-only; `@restrict` rules, `applyRules`, `changeStatus` and
  all annotations use `status_code`. `app/labels.cds` adds `@Common.Text: status.name`,
  `#TextOnly` and `@Common.ValueListWithFixedValues`, so both filter bars get a Status
  dropdown and tables show "Learning Journey". CAP adds the value help itself (CodeList).
  Gotchas: annotation expressions need `$self.status.code`; an unknown name in `Value:` is
  only a warning (a typo `status_` compiled); after the rename the browser needed Ctrl+F5
  before the action buttons worked. Tested: compile clean, erik 3 / dan 9 / chris 10,
  self-verify 400, unknown code 400, approve works (API and browser).
- **10f/10h** (15 Oct, `250ad6b`, `24d58b5`, and the next commit) `test/admin.http`
  request 1 filters on `status_code`; `changeStatus` / `oldStatus` / `newStatus` names
  restored after a Replace All renamed them; error message starts with "Status" again.
  (The two messages still have a double space: `Status  'X'`. Cosmetic.)

## 14 Oct 2026: step 8, Approvals app

Branch `story/approvals-app` (from `story/admin-service`). Merged into `main` (`86c14ac`).

- **8a** Approvals app generated with Fiori tools 1.25.0 in `app/approvals`: List Report
  V4 on `AdminService`, main entity `EmployeeCertifications`, no virtual endpoints (real
  `webapp/index.html`, like the first app). Generated annotations cleared, as in step 5.
  Adds `watch-approvals` script and `app/approvals` to `sapux` in `package.json`.
- **8b part 1** Labels moved from `app/certifications/annotations.cds` (on CertService)
  to new `app/labels.cds` (on the `cert.manager.*` database entities), loaded from
  `app/services.cds`. Both services now get the same 15 labels without copying them.
  Checked: CertService `$metadata` identical before and after.
- **8b part 2** Approvals list page: columns employee, code, certification, status,
  earned on, evidence link, valid until; filters on status and earned on.
- **8c** Approvals object page: header (employee name + certification), "Review" section,
  and Approve / Reject / Revoke buttons (`UI.Identification` with `DataFieldForAction`).
  New i18n texts `Approve`, `Reject`, `Revoke`, `ReviewSection`. All three buttons always
  show; a wrong-status click gets the 400 message from `admin-service.js`.
- `CLAUDE.md`: Claude may also edit i18n `.properties` text files when Ranjan asks.
- **8c+** (13 Oct) Buttons follow the status: `@Core.OperationAvailable` on each action.
  Pending -> Approve, Reject; Verified/Rejected -> Revoke; Planned/LearningJourney ->
  none. Uses `$self.status` (`in.status` does not compile: `in` is a reserved word). The
  server check in `admin-service.js` stays as the safety net.
- **8d** (14 Oct, `4baa17c`) Approvals list page has tabs All / Pending / Verified /
  Rejected with counts. Four `UI.SelectionVariant`s (filter on `status`; All has no
  filter) in `app/approvals/annotations.cds`, tab texts `TabAll`…`TabRejected` in i18n.
  `manifest.json` uses `"views"` (multiple table mode: one table per tab, each needs a
  `key`), not `quickVariantSelection` inside `tableSettings`: with more than 3 variants
  that shows a dropdown, not tabs. Tested with the dropdown version (counts right, a
  Reject moved a record from Pending to Rejected), then the tabs version in the browser.
  Counts refresh only for tabs already opened (SAP docs).
- **8e** (14 Oct, `2be4c20`) The two READ handlers for Days Left (`before` adds
  `validUntil` to the columns, `after` fills `daysUntilExpiry` and `expiryCriticality`)
  moved from `cert-service.js` to new `srv/lib/expiry-fields.js` as
  `addExpiryFields(srv, entity)`. `cert-service.js` and `admin-service.js` each call it
  once, so AdminService gets Days Left without copying code. `expiry.js` stays pure date
  maths (no CAP). Tested: both services return the same values; erik still 3 records on
  CertService and 403 on AdminService; approve and create-with-`earnedOn` still work.
- **8e** (14 Oct, `6e33f69`, `be16852`) Approvals app shows Days Left with colour in the
  table and the Review section (`Criticality: expiryCriticality`). `expiryCriticality`
  gets `@UI.Hidden` in `app/labels.cds`, so neither app offers the raw colour code in the
  column/filter settings. Lesson: a column added through the table settings (gear) shows
  the raw value only; colour needs the `Criticality` link in an annotation.

## 12 Oct 2026: step 7, AdminService and approval flow

Branch `story/admin-service` (from `fixes`).

| Commit | Change | Why |
| --- | --- | --- |
| `fe05d5c` | Project docs: `CLAUDE.md`, `docs/context.md`, `docs/tasks/todo.md`; changelog moved to `docs/` and back-filled to the first commit. `CLAUDE.md` rule: Claude writes docs only, Ranjan writes all code | New sessions can pick up the project; all docs in one place |
| `fe05d5c` | Step 7 design agreed: Approve / Reject / Revoke, AdminService, admin-only Approvals and Employees apps, employee edit lock, managers don't see `Rejected` | Recorded in `docs/context.md` and `docs/tasks/todo.md` |
| `11680f4` | **7c** `test/admin.http`: 9 REST Client requests replaying the approval story. Run in order after a fresh `npx cds watch` | Repeatable manual test anyone can click through |
| `5f6ab16` | **7b** `srv/admin-service.js`: one `changeStatus` helper for `approve` (Pending -> Verified), `reject` (Pending -> Rejected), `revoke` (Verified/Rejected -> Pending). Wrong status 400, unknown ID 404 | Admin decisions with a fixed set of allowed moves |
| `5f6ab16` | **7b** `srv/admin-service.cds`: `AdminService` at `/odata/v4/admin`, admin only. `Employees` editable; `Certifications`, `EmployeeCertifications` `@readonly`; bound actions `approve`, `reject`, `revoke` | Keeps admin-only features out of the employee app. Tested: no login 401, non-admin 403, direct edit 405 |
| `60261d2` | **7a** `@restrict`: `UPDATE` only while `Planned`, `LearningJourney` or `Pending`; manager `READ` skips `Rejected` | Employees could change dates on approved records without review. Tested: employee edit of Verified/Rejected 403, admin still edits |
| `efeee13` | **6d** `applyRules(req, data, stored)` now receives `stored` | Saving with an `earnedOn` date threw `ReferenceError: stored is not defined` |

## 12 Oct 2026: fixes after step 6

Branch `fixes`.

| Commit | Change | Why |
| --- | --- | --- |
| `6a3c2a7` | First version of this changelog | Record of the step 6 work |
| `f0e8f7f` | `applyRules` keeps a `Verified` or `Rejected` status instead of resetting it to `Pending` | Editing an approved record would quietly un-approve it. Broke saving until fixed in `efeee13` (6d). |

## 10 Oct 2026: step 6, clean-up and object page

Branch `fixes`.

| Commit | Change | Why |
| --- | --- | --- |
| `a94f169` | Object page: header (certification name + employee), "General" and "Validity" sections | Clicking a row opened an empty page |
| `a94f169` | Evidence URL is now a clickable link (`UI.DataFieldWithUrl`) | It was plain text |
| `a94f169` | Missing i18n labels added (`CertCode`, `CertName`, `EmployeeName`, `EarnedOn`, `Issuer`, `EvidenceUrl`, section titles) | Columns showed raw keys like `CertCode` |
| `6407617` | `validUntil`, `daysUntilExpiry`, `expiryCriticality` marked `@readonly` | The UI let users type values the server calculates |
| `6407617` | Error messages now name the field (`earnedOn`, `plannedFor`, `employee_ID`) | Fiori can highlight the wrong field |
| `6407617` | Catalogue replaced with 10 current SAP certifications, named "SAP Certified Associate - ..." | Microsoft, AWS and Scrum entries broke the 12-month rule; old names were out of date |
| `6407617` | Seed record 10: `validUntil` fixed to 2027-08-01 | Did not match `earnedOn` + 1 year |
| `6141344` | `@sap/cds-dk` added as a devDependency | The `cds` command was missing after the Node upgrade |
| (no commit) | Node upgraded from 20.19.4 to 24.21.0 | `@sap/cds` 10 needs Node 22 or higher and would not start |

## 9 Oct 2026: steps 3c to 5d, security and Fiori app

Branch `main` (pushed).

| Commit | Change | Why |
| --- | --- | --- |
| `29be893` | **5d** Labels moved out of `UI.LineItem` into `@Common.Label` per field, for all three tables | One label per field, reused everywhere |
| `4261542` | **5c** Filter bar on `status`, `validUntil`, `isEarned`. First `_i18n/i18n.properties` file | Users can filter the list; texts are translatable |
| `36f5694` | **5b** Table columns defined (`UI.LineItem`), days left coloured by criticality | First usable list |
| `36f5694` | **5b** READ handler always fetches `validUntil` | Days left was empty when the UI did not request `validUntil` |
| `39b0152` | **5** Fiori elements List Report app generated in `app/certifications` (Fiori tools, UI5 1.153). Added `cds-plugin-ui5` and the `watch-certifications` script | Start of the UI |
| `70a5b02` | **4** Mocked users `chris` (admin), `dan`, `ranjan`, `erik`; default CAP users switched off | Test different roles locally |
| `70a5b02` | **4** `@requires: 'authenticated-user'` and `@restrict` rules: own records, manager reads team, delete only while Planned / LearningJourney, admin does all | Each user only sees and changes what they should |
| `70a5b02` | **4** CREATE links the record to the logged-in user's employee record; UPDATE blocks moving a record to someone else | Users can't create records for other people |
| `4f5bfe0` | **3c** Rules moved into a shared `applyRules` function, now used by CREATE and UPDATE. UPDATE merges the stored row with the changes first | Same rules for new and edited records |
| `4f5bfe0` | **3c** `plannedFor` required when not yet earned | A plan needs a target date |
| `4f5bfe0` | **3c** New calculated field `isEarned` (`earnedOn is not null`) | Easy filter for earned / not earned |

## 8 Oct 2026: steps 1 to 3b, model, service and rules

Branch `main` (pushed).

| Commit | Change | Why |
| --- | --- | --- |
| `fa94a38` | **3b** Before CREATE: `earnedOn` sets `validUntil` (+1 year) and status `Pending`; without `earnedOn` only `Planned` / `LearningJourney` allowed | Server decides expiry and status, not the user |
| `ff161c2` | **3a** `srv/lib/expiry.js`: `today`, `addOneYear` (29 Feb -> 28 Feb), `daysUntil`, `criticality` | Date logic in one testable place |
| `ff161c2` | **3a** After READ: fills `daysUntilExpiry` and `expiryCriticality` | Days left changes daily, so it is calculated, not stored |
| `ff161c2` | **3a** `validMonths` removed from `Certifications`; `cert-services.cds` renamed to `cert-service.cds` | Every certification is 12 months; file name matches `cert-service.js` |
| `8b48d19` | **2** `CertService` exposing the three tables. Seed CSVs for certifications, employees, records | Something to query and test with |
| `2ca5457` | **1** Data model: `Certifications`, `Employees` (with `manager`), `EmployeeCertifications`, `Status` list. CAP project set up with SQLite | Starting point |
