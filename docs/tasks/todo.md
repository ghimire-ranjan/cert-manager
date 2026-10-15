# To do

Last updated: 2026-10-14

## 1. Done: saving with an `earnedOn` date was broken (fixed 12 Oct)

`applyRules` used `stored` but did not receive it. Fixed by changing the signature to
`function applyRules(req, data, stored)`.

- [x] Add `stored` to the `applyRules` parameters
- [x] Test: as `ranjan`, create a record with an `earnedOn` date. Saves as `Pending`,
      `validUntil` = +1 year. (Only works if `employee_ID` is sent, see the `@mandatory`
      item in section 3.)
- [x] Test: as `chris`, edit a `Verified` record. Stays `Verified`.
- [x] Test: as `ranjan`, edit a `Pending` record. Stays `Pending`.

## 2. Next steps (in order)

Design agreed 12 Oct 2026. Rules are in [../context.md](../context.md) (status flow, who
can do what).

### Step 7: AdminService (backend only)

- [x] **7a** `srv/cert-service.cds`: employees can update own records only while
      `Planned`, `LearningJourney` or `Pending`; managers no longer see `Rejected` team
      records. (Done and tested 12 Oct.)
- [x] **7b** New `srv/admin-service.cds` + `srv/admin-service.js`, admin role only:
      `Employees` (editable), `EmployeeCertifications` (read-only, bound actions
      `approve`, `reject`, `revoke`), `Certifications` (read-only).
  - [x] Part 1: `admin-service.cds` (done and tested 12 Oct)
  - [x] Part 2: `admin-service.js`, the action logic (done and tested 12 Oct)
- [x] **7c** `test/admin.http`: test 7a and 7b (right status works, wrong status errors,
      non-admin gets 403). Done 12 Oct. Run with the REST Client extension, requests 1-9
      in order, right after starting the server.

### Step 8: Approvals app (admin)

Branch `story/approvals-app`.

- [x] **8a** Generate the app (`app/approvals`, on AdminService), clear the generated
      annotations.
- [x] **8b** Table columns, filter bar, labels (share labels with the first app).
- [x] **8c** Object page with Approve / Reject / Revoke buttons, enabled by status
      (`@Core.OperationAvailable`, done 13 Oct).
- [x] **8d** Tabs All / Pending / Verified / Rejected (done 14 Oct: `"views"` in
      `manifest.json`, one `UI.SelectionVariant` per tab).
- [x] **8e** "Days left" in AdminService (done 14 Oct: shared
      `srv/lib/expiry-fields.js`, coloured column in table and Review section).

Original goal: Fiori elements app on AdminService, tabs All / Pending / Verified / Rejected
      (`UI.SelectionPresentationVariant`), Approve / Reject / Revoke buttons.
      Annotations only, no JavaScript.

### Step 10: Status as a code list (value help)

Branch `story/status-codelist` (from `main`). Decided 14 Oct: option B (code list), not a
separate value-list entity next to the enum. Goal: a Status dropdown in the filter bars
of both apps that shows readable names ("Learning Journey").

How it works: `status` becomes an association to a new `Statuses` code list. The database
column becomes `status_code`; the codes stay the same text (`Planned`, `Pending`, ...), so
no data changes, only names. CAP adds the value help to `Statuses` by itself.

Prototype on a copy (14 Oct) passed: counts erik 3 / dan 9 / chris 10, filter on
`status_code`, create plan -> Planned, create earned -> Pending + validUntil, unknown
status -> 400 "Target with this key doesn't exist", self-verify -> 400, approve works
and approve twice -> 400, erik edit of Verified -> 403.

- [x] **10a** `db/schema.cds`: replace `type Status … enum` with
      `entity Statuses : sap.common.CodeList { key code : String(20); }` (add `sap` to the
      `using` line); `status : Association to Statuses default 'Planned' @assert.target;`
- [x] **10b** `db/data`: new `cert.manager-Statuses.csv` (`code,name`, 5 rows);
      `cert.manager-EmployeeCertifications.csv` header `status` -> `status_code`.
- [x] **10c** `srv/cert-service.cds` and `srv/admin-service.cds`: expose
      `@readonly entity Statuses as projection on my.Statuses;`. In the three `@restrict`
      `where` texts: `status` -> `status_code`.
- [x] **10d** `srv/cert-service.js` (`applyRules` and the UPDATE handler) and
      `srv/admin-service.js` (`changeStatus`): `.status` -> `.status_code`.
- [x] **10e** Annotations, both apps: `status` -> `status_code` in `LineItem`,
      `SelectionFields`, `FieldGroup`, tab `PropertyName`s. In `@Core.OperationAvailable`
      write `$self.status.code` (`$self.status_code` does not compile there).
      `app/labels.cds`: on `status` add `@Common.Text: status.name`,
      `@Common.TextArrangement: #TextOnly`, `@Common.ValueListWithFixedValues` (all
      checked: they reach `status_code` in `$metadata`).
- [x] **10f** `test/admin.http`: `$filter=status eq` -> `$filter=status_code eq`.
- [x] **10g** Test in the browser: dropdown in both filter bars, names shown in tables,
      tabs and Approve / Reject / Revoke buttons still right; run `test/admin.http`.
      (14 Oct: buttons confirmed working after Ctrl+F5; API checks pass. Dropdown and
      `test/admin.http` run still to confirm.)
- [x] **10h** Tidy the Replace All leftovers: `srv/admin-service.js` names back to
      `changeStatus` / `oldStatus` / `newStatus`; `srv/cert-service.js` line 5 comment and
      line 21 message (`Status '...' needs an earnedOn date`, users see it).

### Step 11: Draft in the Certifications app (create and edit)

Branch `story/draft` (from `main`, after step 10 is merged). Goal: employees create plans,
submit earned certifications and edit their own records in the app. Today the app has no
Create or Edit button: Fiori elements V4 needs draft for that.

Prototype on a copy (15 Oct) passed: the existing `before('CREATE')` / `before('UPDATE')`
handlers run when a draft is saved, so all rules work unchanged. New draft without help:
`ASSERT_MANDATORY` on `employee_ID` (the parked `@mandatory` item). Fixed with a
`before('NEW')` handler on the drafts that fills in the logged-in employee. Then: save
plan -> Planned; save earned + "Verified" -> Pending, validUntil +1 year; self-verify on
edit -> 400; erik edits own Verified -> 403; dan edits erik's -> 403; admin approve
unchanged.

Decisions (15 Oct, Ranjan agreed to Claude's suggestions):

- Status dropdown offers all 5; the server rejects wrong choices with a message. A
  filtered dropdown (Planned / Learning Journey only) can come later.
- The employee is filled in for everyone (admins too) and is read-only in this app. This
  is the employee's own app; assigning to someone else waits for the Employees app.
- Managers see an Edit button on their team's records and get 403 if they click it.
  Accepted for now (server blocks it); the "My Team" app stays parked.

- [x] **11a** `srv/cert-service.cds`: `@odata.draft.enabled` on `EmployeeCertifications`.
- [x] **11b** `srv/cert-service.js`: `before('NEW', EmployeeCertifications.drafts, …)` fills
      `employee_ID` with the logged-in employee (no admin exception).
- [x] **11c** `app/certifications/annotations.cds`, object page: show `certificate_ID`
      (not `certificate.code`) so it can be picked: `@Common.ValueList` on `Certifications`
      (code, name) + `@Common.Text: certificate.name`. Show `employee_ID` with
      `@Common.Text: employee.name` and `@Common.FieldControl: #ReadOnly` (UI only).
- ~~**11c+**~~ **Dropped 15 Oct** (Ranjan and Claude agreed): Employee field editable for
      admins only. Not needed by the concept: employees file their own records here;
      assigning or correcting the person belongs in the Employees app (step 9). Kept as a
      note in case it is needed later: virtual `employeeFieldControl` (1 = read-only,
      7 = required) filled per user in `after('READ', [EmployeeCertifications,
      EmployeeCertifications.drafts], (rows, req) => …)`, `@Common.FieldControl:
      employeeFieldControl`, a value help on `Employees`, `@UI.Hidden` on the helper field.
      Prototype passed (erik 1, chris 7, chris could save a record for dan, erik could not).
- [x] **11d** Test in the browser as erik: Create a plan, Create an earned cert (becomes
      Pending), Edit own Planned, Edit button on own Verified fails, Delete own Planned.
      As chris: Create gets Chris filled in. As dan: Edit on a team record fails (403).
- [x] **11e** Remove the parked `@mandatory` item (solved by 11b); update docs.
- [ ] **Open question (15 Oct, for Ranjan):** may an employee delete their own `Pending`
      record (withdraw a submission)? `srv/cert-service.cds` (DELETE rule) allows it;
      `docs/context.md` says only `Planned` / `LearningJourney`. Decide, then make the
      code or the docs match.

### Step 9: Employees app (admin)

Branch `story/employees-app` (from `main`, 15 Oct). Admin-only app on AdminService: list
of employees; employee page with their details (editable, draft) and a table of their
certifications with Approve / Reject / Revoke buttons.

Decisions (15 Oct): certifications stay an **association** (independent records, not a
composition); employees are **not deleted**, only deactivated (`active = false`);
`userID` must be **unique**; manager picked from a value help by name, and nobody can be
their own manager; Approve / Reject / Revoke **on the employee page's table** (Ranjan's
request; cheap because the actions already exist).

Prototype on a copy (15 Oct) passed: certifications through
`Employees(…)/certifications`; approve and revoke through that link; edit + save an
employee (draft); the certifications table still loads and approve still works while
the employee is being edited; Approvals app unchanged; erik 403.

- [x] **9a** `db/schema.cds`: on `Employees` add
      `certifications : Association to many EmployeeCertifications on certifications.employee = $self;`
      (no new column) and `@assert.unique` on `userID`.
- [x] **9b** `srv/admin-service.cds`: `@odata.draft.enabled` on `Employees`; no delete
      (`@Capabilities.DeleteRestrictions.Deletable: false`, check the server enforces it).
      **Required, security:** `srv/cert-service.cds`:
      `entity Employees as projection on my.Employees excluding { certifications };`.
      Found 15 Oct: without it, erik reads anyone's records with
      `/cert/Employees(dan)?$expand=certifications` (`@restrict` on
      `EmployeeCertifications` does not cover rows pulled in through another entity's
      link). Tested fix: erik gets 400, still sees his own 3 and all 5 employees; admin
      link still works.
- [x] **9c** `srv/admin-service.js`: before CREATE / UPDATE on `Employees`, 400 if
      `manager_ID` is the employee's own `ID`, and 400 (on field `userID`) if another
      employee already has that `userID`. Tested 15 Oct: `@assert.unique` alone does
      block a duplicate, but as a database error (`UNIQUE constraint failed…`, HTTP 500);
      keep it as the safety net, the handler gives the readable message.
- [ ] **9d** Generate `app/employees` with the Fiori wizard (List Report V4, local CAP,
      AdminService, main entity `Employees`, no virtual endpoints), clear the generated
      annotations, restart `cds watch`.
- [ ] **9e** `app/employees/annotations.cds`: list columns and filters; object page
      header and details; `manager` value help with names; a "Certifications" section
      showing `certifications` with its own `UI.LineItem #ForEmployee` (code, name,
      status, valid until, days left) + `UI.DataFieldForAction` approve / reject / revoke.
      Check what Fiori requests for that table: Days Left works through
      `Employees(…)/certifications` but is **empty through `$expand`** (the READ handlers
      only run for `EmployeeCertifications` itself). If Fiori uses `$expand`, extend the
      handler (prototype first). Manager value help: active employees only; list filter
      defaults to active.
- [ ] **9e+** Labels for `userID`, `email`, `active`, `manager` in `app/labels.cds` and
      `_i18n/i18n.properties` (Claude may write the i18n texts).
- [ ] **9f** Test as chris: list, edit an employee, self-manager error, duplicate userID
      error, no Delete, approve / reject / revoke from the employee page; Approvals app
      still fine; erik and dan get 403. Add requests for duplicate `userID`, own manager
      and blocked Delete to `test/admin.http`, so they can be re-run.

Later (own steps, not part of step 9):

- [ ] **Change history** with `@cap-js/change-tracking`, shown on the object page.
- [ ] **README**: replace the "Welcome to your new CAP project" text.
- [ ] **Deploy to BTP**: real login (XSUAA), `xs-security.json`, MTA build.

## 3. Parked on purpose

These were spotted and left alone on purpose.

| Item | Why it waits |
| --- | --- |
| Put mocked users under `[development]` and add XSUAA under `[production]` | Only matters when deploying. Until then a deployed app would accept `chris` / `chris` from anyone. |
| `@Capabilities` so the UI hides buttons the user can't use | `$metadata` is the same for every user, so a fixed `Deletable: false` would hide Delete from the admin too. Needs a per-row field instead. |
| Comment in `srv/lib/expiry.js` saying "12 months is a scope decision" | Small; do it next time that file is touched. |
| Reject reason (e.g. a `rejectionReason` field, required on Reject) | Decided 12 Oct: not now. |
| Server warning: action `reject` clashes with CAP's built-in `reject` method | Harmless: the action works over HTTP (tested). CAP only skips creating a typed JS shortcut. Renaming (e.g. `rejectRecord`) would silence it, but changes the button and URL. |
| "My Team" app for managers: read-only, direct reports, `Verified` only, on its own `TeamService` | Decided 12 Oct: not now. Keep admin and manager apps separate so no buttons need hiding. |
