# Changelog

Every change to cert-manager, newest first.

**How to add an entry:** after each change, add one line under **Unreleased**: what
changed and why. When you commit, replace "Unreleased" with the date and commit
step, and start a new empty Unreleased section on top.

---

## Unreleased

Branch `story/approvals-app` (from `story/admin-service`).

- **8a** Approvals app generated with Fiori tools 1.25.0 in `app/approvals`: List Report
  V4 on `AdminService`, main entity `EmployeeCertifications`, no virtual endpoints (real
  `webapp/index.html`, like the first app). Generated annotations cleared, as in step 5.
  Adds `watch-approvals` script and `app/approvals` to `sapux` in `package.json`.
- **8b part 1** Labels moved from `app/certifications/annotations.cds` (on CertService)
  to new `app/labels.cds` (on the `cert.manager.*` database entities), loaded from
  `app/services.cds`. Both services now get the same 15 labels without copying them.
  Checked: CertService `$metadata` identical before and after.

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
