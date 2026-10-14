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

### Step 9: Employees app (admin)

- [ ] Add a "to many" link from `Employees` to `EmployeeCertifications` in
      `db/schema.cds`.
- [ ] Fiori elements app on AdminService: employee list, and on each employee's page a
      table of their certifications (with the same action buttons). Draft
      (`@odata.draft.enabled`) and a value help on `manager`.
- [ ] **Change history** with `@cap-js/change-tracking`, shown on the object page.
- [ ] **README**: replace the "Welcome to your new CAP project" text.
- [ ] **Deploy to BTP**: real login (XSUAA), `xs-security.json`, MTA build.

## 3. Parked on purpose

These were spotted and left alone on purpose.

| Item | Why it waits |
| --- | --- |
| Put mocked users under `[development]` and add XSUAA under `[production]` | Only matters when deploying. Until then a deployed app would accept `chris` / `chris` from anyone. |
| `@Capabilities` so the UI hides buttons the user can't use | `$metadata` is the same for every user, so a fixed `Deletable: false` would hide Delete from the admin too. Needs a per-row field instead. |
| `@mandatory` on `employee` fires before the CREATE handler fills in `employee_ID` | CAP runs checks in this order. Ask a senior before working around it. Confirmed 12 Oct: a normal user who leaves out `employee_ID` gets `400 ASSERT_MANDATORY` on `employee_ID`. This matters for the "create" button in the Fiori app. |
| Comment in `srv/lib/expiry.js` saying "12 months is a scope decision" | Small; do it next time that file is touched. |
| Reject reason (e.g. a `rejectionReason` field, required on Reject) | Decided 12 Oct: not now. |
| Server warning: action `reject` clashes with CAP's built-in `reject` method | Harmless: the action works over HTTP (tested). CAP only skips creating a typed JS shortcut. Renaming (e.g. `rejectRecord`) would silence it, but changes the button and URL. |
| "My Team" app for managers: read-only, direct reports, `Verified` only, on its own `TeamService` | Decided 12 Oct: not now. Keep admin and manager apps separate so no buttons need hiding. |
