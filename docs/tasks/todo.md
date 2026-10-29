# To do

Last updated: 2026-10-26

Two short lists first. The details, decisions and test results for each step are further
down ("Next steps", by step number).

## To do (in order)

### Catalogue app (done 26 Oct, branch `story/catalogue-app`)

- [x] Restart `cds watch`, open `/catalogue/webapp/index.html` as chris (Ctrl+F5): list
      with Code / Issuer filters, "Details" section, no Delete, duplicate code refused
      (26 Oct)
- [x] Update docs, commit, merge to `main`, push (26 Oct)

### Before deploying (Ranjan, in the BTP cockpit, subaccount Sandpit)

- [ ] Create space `cert-manager`; check you are Space Developer in it
- [x] Check you can assign role collections (Security > Users): **no** (27 Oct). Ranjan
      asked someone to assign CertManager Admin + CertManager Employee (and
      `Launchpad_Admin` for the Work Zone site)
- [ ] Check which login Sandpit uses (Security > Trust Configuration)
- [x] Check you have role collection `Launchpad_Admin`: **no** (27 Oct). Decided: open
      the apps one by one from the cockpit (HTML5 > HTML5 Applications, managed app
      router); the launchpad site with tiles waits until someone grants it
- [ ] Check HANA Cloud is mapped to space `cert-manager`

### Deploy round 1: the app in the cloud, no AI

- [ ] Mocked users for the laptop only; real login (XSUAA) in the cloud
- [ ] New role `employee`; services require it; `xs-security.json`; role collections
      "CertManager Employee" and "CertManager Admin"
- [x] Mocked users only under `[development]`; cloud uses real login (`jwt`) (26 Oct)
- [x] Role `employee` on CertService (`@requires: ['employee', 'admin']`); laptop users
      dan / ranjan / erik have it; a user without a role gets 403 (26 Oct)
- [x] `cds add hana` (driver `@cap-js/hana`; HANA in the cloud, SQLite on the laptop)
- **Changed 26 Oct (Ranjan): the test data goes to the Sandpit cloud too**, for learning
  the deployment (no real data yet). After deploying, the admin changes Ranjan's Login in
  the Employees app from `ranjan` to the real e-mail login, to test as an employee.
- [x] `cds add xsuaa` (`xs-security.json` + role collections "CertManager Admin" /
      "CertManager Employee"), `cds add mta`, `cds add html5-repo` (26 Oct)
- [x] Tools: `cf` CLI v8, `mbt`, GNU `make` (`winget install ezwinports.make`), `cf`
      plugin `multiapps`; `npm install` to sync `package-lock.json` (26 Oct)
- [x] **First deploy worked (27 Oct).** The shared HANA in Sandpit is not mapped to our
      space and Ranjan lacks "SAP HANA Cloud Administrator", so Claude created our **own
      free HANA** `cert-manager-hana` (`hana-cloud` / `hana-free`, 16 GB, generated
      password, Cloud Foundry IPs only) in space `Cert-manager`. **It stops every night**;
      start it before use. Sign: the apps say "Internal Server Error" and the server log
      says "Pool resource could not be acquired". To start it: a file `hana-start.json`
      with `{"data":{"serviceStopped":false}}` (outside the project), then
      `cf update-service cert-manager-hana -c hana-start.json` and wait about 4 minutes
      until `cf service cert-manager-hana` says "update succeeded". Checked: server runs on HANA with XSUAA, tables deployed (task
      SUCCEEDED), everything 401 without login, mocked `chris:chris` refused.
- [x] `cds add workzone` (destination service, `sap.cloud` service `certmanager.service`);
      fixed its mistake: all four apps had the same inbound `employees-display`, now
      one per app. Second deploy OK (27 Oct)
- [x] Certifications app opens from cockpit > HTML5 Applications; the server answers 403
      "lacking required roles: [employee, admin]" until role collections are assigned:
      the role check works in the cloud (27 Oct)
- [x] Role collections assigned to the CIS user (27 Oct): the Certifications app shows all
      10 records from HANA as admin
- [x] **Found 27 Oct, solved:** Ranjan Ghimire's Login set to the CIS user ID in the Employees app; Create now fills in Ranjan. In the cloud the user ID is a GUID (e.g. `0a41fa04-…`), not the
      e-mail. `Employees.userID` must match it. Check again once roles are assigned.
      Cause: Sandpit has two login systems. App logins go through Atturra's IAS ("CIS",
      `aalbksesi.accounts.cloud.sap`), where the user name is a GUID; the default
      identity provider (SAP ID) uses the e-mail. Role collections must be assigned to
      the **CIS** user (Nick Yang assigned them to the default-IdP user first; asked him
      to add them to the CIS user too, 27 Oct)
- [x] **HANA-only bugs found and fixed (27 Oct)**, both worked on SQLite: (1) `isEarned =
      (earnedOn is not null)` broke every draft read on HANA ("incorrect syntax near is");
      now `case when … then true else false end`. (2) `addExpiryFields` added
      `validUntil` to count queries (`count(1)` + column, refused by HANA); now skipped
      when the query has a `func`. Redeployed; Create and the list work in the cloud
- [x] Login errors in the browser after a deploy: use a private window (old cookies)
- [x] **Found and fixed 27 Oct:** a record saved in the cloud **without an employee**
      (admin, login not linked to an employee yet), although `employee` is `@mandatory`.
      Cause: `@Common.FieldControl: #ReadOnly` on the Employee field (UI annotation) also
      switches off `@mandatory`, because CAP lets read-only win over mandatory. Fix:
      readable 400 in `before CREATE` in `srv/cert-service.js` that names the login to
      link. Tested on the laptop (boss 400, chris and ranjan 201) and deployed
- [ ] `mbt build` can empty the laptop's `node_modules`: each app's build step runs
      `npm ci` inside its npm workspace, which resets the shared `node_modules` to that
      app's tools. Until fixed: run `npm install` after `mbt build` if `cds watch` says
      "Cannot find module '@sap/cds'"
- [ ] Before any real use: move `cert.manager-Employees.csv` and
      `cert.manager-EmployeeCertifications.csv` from `db/data` to `test/data` (laptop
      only), with `git mv`
- [ ] `mta.yaml` (server, database, login, HTML5 repository for the 4 apps)
- [ ] Deploy; assign yourself "CertManager Admin"; Work Zone site with 4 tiles; add
      yourself in the Employees app
- [ ] Test: log in, create a record, approve it; a user without a role can't get in

### Deploy round 2: AI in the cloud

- [ ] Destination `cert-manager-aicore` in Sandpit (from the AI Core key)
- [ ] AI settings for the cloud; agent chat reachable from the launchpad; test

### Step 14: SAP exam search (design agreed, see below)

- [ ] Check Atturra allows Tavily; sign up; key in `.env`
- [ ] `SapExamService` with `searchSapSites(question)` (only `learning.sap.com`,
      `training.sap.com`); agent rules; tests

**Step 15: SAP exam agent** (later): `@agent` on `SapExamService`, true agent-to-agent

### Later / open

- [ ] Sizes (S / M / L / XL) for Catalogue app, round 1, round 2, step 14: question for
      the architect
- [ ] Change history (`@cap-js/change-tracking`)
- [ ] README: replace the "Welcome to your new CAP project" text

## Done

- **Step 1** (12 Oct): saving with an `earnedOn` date fixed
- **Step 7** (12 Oct): AdminService with approve / reject / revoke; `test/admin.http`
- **Step 8** (13-14 Oct): Approvals app (tabs, buttons, days left)
- **Step 10** (14 Oct): status as a code list (dropdowns with readable names)
- **Step 11** (15 Oct): draft in the Certifications app (create and edit)
- **Step 9** (15 Oct): Employees app (draft, no delete, unique login, manager picker)
- **Step 12** (15 Oct): MCP with SAP's `@cap-js/mcp` plugin
- **Step 13** (15-22 Oct): A2A agents (`@cap-js/agents`), AI actions for employees and
  admins, agent instructions and human in the loop (`srv/agent-rules.cds`); SAP AI Core
  (`mistralai--mistral-small`) answers
- **22 Oct:** tidy-up (delete own Pending allowed, docs), deploy design agreed
- **Catalogue app** (23-26 Oct): exam code unique, admins edit
  the catalogue with draft, no delete, readable duplicate-code message; app generated and
  annotated (`app/catalogue`)

## Where we left off

**Starting on another laptop:**

1. `git clone https://github.com/ghimire-ranjan/cert-manager.git` (or `git pull` on `main`),
   then `npm install` in the project folder.
2. `.env` is **not** in git (it holds secrets). Create it again: copy `.env.example` to
   `.env`, then fill in `OPENAI_API_KEY` (Groq) and/or `AICORE_SERVICE_KEY` (SAP AI Core,
   one line of JSON). Keep exactly one model block active.
3. `cds watch`. Check the model with `cds env requires.llm`.
4. Never delete `node_modules` with PowerShell `Remove-Item -Recurse` (npm workspace
   junctions point into `app/`).

**What works:** 3 Fiori apps (Certifications with draft, Approvals, Employees); MCP on
CertService (`/mcp/cert`) and AdminService (`/mcp/admin`) with tools describe / query /
call; A2A agents at `/a2a/cert` and `/a2a/admin` with instructions and human in the loop
(`srv/agent-rules.cds`); employee AI actions (plan / submit) and admin AI actions
(approve / reject / revoke).

**If the agent says "content safety check is temporarily unavailable":** the key in
`.env` must be on **one** line, and VS Code must be restarted if it still holds an old
`AICORE_SERVICE_KEY` (an existing env var wins over `.env`). The AI Core instance is
`gen-ai-a2a` (plan `extended`, Cloud Foundry space `default`, resource group `default`).

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
- [x] **Open question (15 Oct, for Ranjan):** may an employee delete their own `Pending`
      record (withdraw a submission)? **Decided 22 Oct: yes.** The code already allows
      it; `docs/context.md` updated to match.

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
- [x] **9d** Generate `app/employees` with the Fiori wizard (List Report V4, local CAP,
      AdminService, main entity `Employees`, no virtual endpoints), clear the generated
      annotations, restart `cds watch`.
- [x] **9e** `app/employees/annotations.cds`: list columns and filters; object page
      header and details; `manager` value help with names; a "Certifications" section
      showing `certifications` with its own `UI.LineItem #ForEmployee` (code, name,
      status, valid until, days left) + `UI.DataFieldForAction` approve / reject / revoke.
      Check what Fiori requests for that table: Days Left works through
      `Employees(…)/certifications` but is **empty through `$expand`** (the READ handlers
      only run for `EmployeeCertifications` itself). If Fiori uses `$expand`, extend the
      handler (prototype first). Manager value help: active employees only; list filter
      defaults to active.
- [x] **9e+** Labels for `userID`, `email`, `active`, `manager` in `app/labels.cds` and
      `_i18n/i18n.properties` (Claude may write the i18n texts).
- [x] **9f** (browser tests passed 15 Oct; `test/admin.http` requests 10-13 added and
      checked the same day: delete 405, duplicate login 400, own manager 400, erik's
      `$expand` 400) Test as chris: list, edit an employee, self-manager error, duplicate userID
      error, no Delete, approve / reject / revoke from the employee page; Approvals app
      still fine; erik and dan get 403. Add requests for duplicate `userID`, own manager
      and blocked Delete to `test/admin.http`, so they can be re-run.

Later (own steps, not part of step 9):

- [ ] **Change history** with `@cap-js/change-tracking`, shown on the object page.
- [ ] **README**: replace the "Welcome to your new CAP project" text.
- [ ] **Deploy to BTP**: real login (XSUAA), `xs-security.json`, MTA build.

### Step 12: MCP (AI assistant tools on top of the app)

Ranjan's plan (14 Oct). MCP (Model Context Protocol) lets an AI assistant call the app as
"tools", e.g. "which of my certifications expire soon?" or "submit my C_CPE pass". Order
agreed 14 Oct: draft first (done, step 11), then MCP, then A2A, because each builds on
the one before.

- [x] **12a** Short design (15 Oct): Ranjan chose "set it up and get it running first"
      over a full design session. Answers in the table below.
- [x] **12b** Read-only MCP (15 Oct). First a hand-made server in `mcp/` (written by
      Claude); **replaced the same day** by SAP's official plugin `@cap-js/mcp`, after
      Ranjan pointed to his study guide of SAP's "CAP in the Age of AI" video series.
      Now: `npm add @cap-js/mcp` + `srv/cert-mcp.cds` (`annotate CertService with @mcp
      @odata;`) + autowire user `ranjan` in `package.json`. Tools `describe` and `query`
      (read-only CQL). Tested as erik (3), dan (9), chris (10), no login (401) on a copy;
      Ranjan tried it in the MCP Inspector as ranjan (3 own records with Days Left;
      `DELETE` rejected).
- [x] **12c** (done as 13b) Doc comments (`/** … */`) on CertService entities and fields so the AI
      understands the data (e.g. what `Pending` means). Decided 15 Oct: do this during
      the A2A work.
- [x] **12d** (done as 13c and 13d) Write tools (after reading works well): e.g. plan / submit a certification
      (employee), approve / reject (admin). The plugin only exposes **unbound** actions
      (`call` tool); our approve / reject are bound, so this needs a small design.
      Prototype first.

Open questions (owner: Ranjan, raised 14 Oct):

| Question | Answer |
| --- | --- |
| What is the goal: learning the technology, a demo for Atturra, or a real feature for the team? | **A demo now, built so it can become a real team feature later** (Ranjan, 15 Oct) |
| Which tools first (read-only like "my expiring certs", or also writes like "submit a cert")? | **Reading first; changing data (submit, approve) only after reading works** (Ranjan, 15 Oct) |
| Who uses it: employees only, or also the admin (e.g. "approve all Pending")? | **Both employees and admins**, each seeing only what the app already allows them (Ranjan, 15 Oct) |
| Where does it run: locally with Claude Code / Claude Desktop, or deployed with the app on BTP? | **Laptop for the demo** (agreed 15 Oct). With `@cap-js/mcp` the MCP endpoint is part of the CAP app itself (`/mcp/cert`), so it moves to BTP together with the app; only the login changes (mocked users -> XSUAA) |

### Step 13: A2A (agent-to-agent)

A2A lets other AI agents talk to an agent that uses the step 12 tools, e.g. an HR or
learning agent asking "who in Dan's team needs to renew this quarter?". Needs step 12
first: the agent needs tools before other agents can use it.

- [x] **13a** Agent set up (15 Oct, branch `story/a2a`): `@cap-js/agents` 0.9.8 (beta) and
      `@agent` next to `@mcp @odata` on CertService. Endpoint `/a2a/cert`, agent card
      `/a2a/cert/.well-known/agent-card.json`, chat preview `/a2a/cert/preview`. Login
      applies (401 without). Plugin bug (0.9.7 and 0.9.8): the default `llm: "auto"`
      resolves to kind `mock`, but the plugin registers it as `llm-mock`, so the agent
      fails with "No service implementation found for llm". Fix: `"[development]": {
      "llm": { "kind": "llm-mock" } }`. With the mock, the full loop runs (tool call ->
      data -> fixed answer). Real model: local models (Ollama) not allowed on the
      company laptop; AI Core not in the DalRae AI subaccount (only AI Launchpad; ask
      the BTP admin for an `extended` AI Core instance). Free cloud tier tried:
      Gemini 3 fails (the plugin's `openai` kind drops Gemini's "thought signatures" on
      tool calls), Gemini 2.5 Flash is no longer available to new users. Next to try:
      Groq (profile `[free-llm]`, kind `openai`, model `openai/gpt-oss-120b`, key and
      base URL only as terminal env vars `OPENAI_API_KEY` / `OPENAI_BASE_URL`).

Features (agreed 15 Oct, in this order; A-C can be tested in the MCP Inspector without a
real model):

- [x] **13b (A)** Doc comments on CertService entities and fields (was 12c), so the AI
      understands the data (status meanings, validUntil = earnedOn + 1 year, negative
      days left = expired). Check with the Inspector's `describe`.
- [x] **13c (B)** Employee actions for the AI: unbound `planCertification(code,
      plannedFor)` and `submitCertification(code, earnedOn, evidenceUrl)`. The MCP plugin
      only exposes **unbound** actions (`call` tool), so these are new; they must run
      through the existing rules (`applyRules`, `@restrict`, own employee only).
- [x] **13d (C)** Admin actions for the AI (agreed 15 Oct; written by Claude at Ranjan's request, tested 15 Oct):
  - [x] In `srv/protocols.cds` (renamed from `srv/cert-mcp.cds` on 15 Oct: one file for all
        protocol settings, Ranjan's choice): `annotate AdminService with @agent @mcp @odata;`
        (Ranjan: AdminService needs all three - OData for the Approvals and Employees
        apps, MCP for AI tools, A2A for an admin agent at `/a2a/admin`). Admin only
        (`@requires: 'admin'` already on the service).
  - [x] `srv/admin-service.cds`: unbound `approveCertification(userID, code)`,
        `rejectCertification(userID, code)`, `revokeCertification(userID, code)` with doc
        comments for the AI.
  - [x] `srv/admin-service.js`: `changeStatus` takes the record's ID instead of
        `req.subject` (unbound actions have no subject); the bound approve / reject /
        revoke pass `req.params[0]`. New handlers find the record by employee login +
        exam code (+ the right status) and reuse `changeStatus`.
  - [x] Test: as chris approve / reject / revoke via MCP; wrong status and unknown person
        give clear errors; erik gets nothing; the Approvals app buttons still work
        (regression after the `changeStatus` change).
- [x] **13e (D)** Agent instructions (the agent's job and rules). 20 Oct, written by
      Claude at Ranjan's request: a doc comment on each service in the new
      `srv/agent-rules.cds` becomes that agent's instructions (system prompt).
- [x] **13f (E)** Human in the loop: `@agent.hitl` on the five AI actions in
      `srv/agent-rules.cds`. The agent stops with state `input-required` and the user
      answers `approve` (or `yes` / `ok`), anything else rejects. Bound Fiori buttons
      unchanged. Tested 20 Oct with SAP AI Core (`mistralai--mistral-small`):
  - [x] ranjan plans a new exam -> gate -> approve -> Planned record created
  - [x] ranjan plans C_FIORD he already has -> agent says so, creates nothing
  - [x] chris approves erik C_SAC -> gate -> declines -> "Nothing was changed", still
        Pending; asks again -> approve -> Verified
  - [x] ranjan on `/a2a/admin` -> 403
- [x] Ranjan tried it in the preview chat (22 Oct). Found: `@hitl` (without `agent.`) is
      silently ignored, so the gate disappeared; fixed back to `@agent.hitl`.

### Deploy to BTP (design in progress, 22 Oct)

Decided so far:

- **Where:** Atturra BTP, subaccount **DalRae Free Tier (Sandpit)** (Cloud Foundry).
  Changed 23 Oct: first planned for DalRae Dev, which is shared with other projects
  (spaces `coffeeconnect`, `eam`, `ventia-pocs`). AI Core stays in subaccount
  **DalRae AI** (instance `gen-ai-a2a`); nothing new is created there.
- **AI Core connection:** a **destination** `cert-manager-aicore` in Sandpit, filled
  from the existing AI Core service key (Ranjan can create destinations in Sandpit).
  Not bound directly: an app can only bind services in its own subaccount.
- **Database:** SAP HANA Cloud, our own HDI container (`hdi-shared`). Sandpit already has
  HANA Cloud (other projects use `hdi-shared` there, e.g. `demo-tcp-wb-db`; don't touch
  them). Sandpit is shared too (180 service instances), so name everything `cert-manager-…`.
- **Space:** own space **`cert-manager`**. A space is free; running app memory counts
  against the org quota (stop the app when not in use).

- [ ] Ranjan: in Sandpit, create space `cert-manager` and check he is Space Developer
- [x] Sandpit has a HANA Cloud database (23 Oct)
- [ ] Check HANA is mapped to space `cert-manager` (HANA Cloud Central > instance >
      Instance Mapping), at the latest when the first deploy fails without it
- **Login (decided 23 Oct):** only people given access. New role `employee`; the
  services require `employee` instead of `authenticated-user` (in a shared subaccount
  "anyone who can log in" is too open). Two role collections in Sandpit:
  "CertManager Employee" and "CertManager Admin". Mocked users stay for the laptop only.
- **Data (decided 23 Oct):** the cloud starts nearly empty: only the catalogue and the
  status list. The test data (`ranjan`, `chris`, `erik`, `dan` and their records) stays
  on the laptop. In the cloud, logins are probably e-mails, so `Employees.userID` must be
  the real login. The admin adds the real employees in the Employees app.
- **Catalogue app (decided 23 Oct):** before deploying, add a small admin "Catalogue" app
  (list + edit page on `Certifications` in AdminService), so new SAP exams can be added
  without a redeploy. Admins still don't create records for other employees.
- [ ] Ranjan: check whether he can assign role collections in Sandpit (Subaccount
      Administrator or User and Role Administrator), and which login Sandpit uses
      (Security > Trust Configuration: SAP ID only, or a company one)
- **Fiori apps (decided 23 Oct):** SAP Build Work Zone, standard edition (subscribed in
  Sandpit) + HTML5 Application Repository + managed app router. A launchpad site with
  tiles; admin tiles only for admins.
- [ ] Ranjan: check he has role collection `Launchpad_Admin` in Sandpit (to create the
      site)
- **AI in the cloud (decided 23 Oct): two rounds.** Round 1: launchpad, 4 apps, HANA,
  login; no AI. Round 2: AI Core destination + the agent chat reachable from the
  launchpad. MCP stays on the laptop (it's only for AI assistants like Claude Code, via
  autowire); MCP from Claude Code to the cloud is parked (needs its own OAuth setup).
  Tavily key in the cloud: decide with step 14.

**Who writes (agreed 23 Oct, changed 26 Oct):** Ranjan types the Catalogue app and the
deploy files himself, Claude explains each step. A first deployment from Ranjan's other
device (not in git) was found in space `cert-manager` on 26 Oct and deleted by Ranjan. **Sizes** (Catalogue
app, round 1, round 2): open question for the architect.

**Order:** Catalogue app -> deploy round 1 -> deploy round 2 (AI) -> step 14 (SAP exam
search) -> step 15 (SAP exam agent).

### Step 16: employee record on first login (design agreed 28 Oct, not started)

Why: in the cloud, logins are IDs like `0a41fa04-…`; admins can't be expected to type
them. Rules are in `docs/context.md` ("Decided 28 Oct"). Ranjan writes the code, Claude
explains. Size: open question for the architect.

- [ ] Check first: which name / e-mail fields CAP gets from the company login token in
      the cloud (and how they look in `req.user`)
- [x] `db/schema.cds`: e-mail unique (`@assert.unique`), plus a readable duplicate-e-mail
      check next to the duplicate-login check in `srv/admin-service.js` (29 Oct, typed by
      Ranjan; tested: duplicate 400 on the E-mail field, empty e-mails allowed)
- [x] Login optional (`userID` no longer `@mandatory`; empty = not linked yet, decided 29
      Oct); duplicate-login check only when a Login is entered (29 Oct, typed by Ranjan;
      tested: two empty Logins OK, duplicate Login 400)
- [x] `srv/lib/first-login.js` (`addFirstLogin`, typed by Ranjan 29 Oct), registered
      first in `init()` of CertService and AdminService: find by login ID → else a
      prepared record with the same e-mail and empty Login → link; else create (name,
      e-mail, login ID, Active on, no manager). Never changes an existing record. Reads
      the `cert.manager.Employees` table directly (no `@restrict`); `try/catch` for
      parallel first requests
- [x] Laptop: mocked users without e-mail get name = login, no e-mail
- [x] Tests (29 Oct, laptop, made-up users via `CDS_CONFIG`): new user created with name
      and e-mail; prepared record linked by e-mail with manager kept; e-mail of another
      login not taken over (and Dan untouched); user without attributes; admin created on
      first admin request; 6 parallel first requests → exactly 1 record; the new user can
      create a plan; existing users unchanged
- [ ] Deploy and try with a colleague who has never logged in

### Step 14: SAP exam search (design agreed 22 Oct, not started)

Goal: the agent answers questions about **SAP exam details** (see `docs/context.md`) by
looking them up live on SAP's official sites, always with the source link. Anything else
(study plans, schedules, personal advice, off-topic) is politely refused. Decisions:
look up live, nobody types exam data in (not stored in our tables); search service
**Tavily**; only `learning.sap.com` and `training.sap.com`; open to everyone logged in
(the 1,000 free searches a month are shared).

- [ ] Ranjan: check Atturra allows Tavily; sign up at tavily.com; put `TAVILY_API_KEY` in
      `.env` (add an empty `TAVILY_API_KEY=` to `.env.example`)
- [ ] `srv/sap-exam-service.cds`: new `SapExamService` (`@requires: 'authenticated-user'`,
      `@mcp`) with one function `searchSapSites(question)`
- [ ] `srv/sap-exam-service.js`: calls Tavily; the site list is fixed in this code (the
      hard limit); returns page text and links
- [ ] `srv/agent-rules.cds`: both agents use the search for exam questions, always give
      the link, refuse anything outside SAP exam details, never invent
- [ ] Test: C_CPE topics (learning.sap.com link), price (training.sap.com link), "plan my
      holiday" and "make me a study plan" refused, made-up exam code -> "nothing found",
      no login -> 401
- [ ] Open: who writes the code (Ranjan or Claude); T-shirt size (S / M / L / XL), or a
      question for the architect

### Step 15: SAP exam agent (later)

Add `@agent` to `SapExamService`: it becomes its own agent, and the certification agent
calls it (true agent-to-agent). Found 22 Oct: the plugin setting `agents.connect` is
`auto`, so every agent already connects to every other agent and MCP service in the app
(e.g. the employee agent can call the admin agent; tested: ranjan gets 403 there, because
his login is passed along). Decide then whether to list the connections explicitly
(`@agent.connect`).

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
