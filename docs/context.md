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
| Status | A code list, table `Statuses` (`code` + readable `name`). Codes: `Planned`, `LearningJourney`, `Pending`, `Verified`, `Rejected`. The column on `EmployeeCertifications` is `status_code`. |
| `earnedOn` | Date the exam was passed. If empty, the certification is not earned yet. |
| `plannedFor` | Target exam date, used before the certification is earned. |
| `validUntil` | Expiry date. Always calculated as `earnedOn` + 12 months. Users cannot type it. |
| Days left | `daysUntilExpiry`, calculated on every read. Not stored. |
| Criticality | The colour of "Days left": green over 90 days, neutral 46-90, orange 16-45, red 15 or less. |
| Approve | Admin action: `Pending` -> `Verified`. |
| Reject | Admin action: `Pending` -> `Rejected`. No reason is recorded (yet). |
| Revoke | Admin action: `Verified` or `Rejected` -> `Pending`. Undoes a decision and re-opens the record so the employee can edit it. |
| SAP exam details | Facts SAP publishes about an exam, not stored in our catalogue: official exam page link, exam topics and weighting, format (questions, duration, pass mark, language), price and booking, validity and "stay current" rule, recommended learning journey (name and link). Never study plans, schedules or personal advice. Looked up live, only on SAP's official sites `learning.sap.com` and `training.sap.com`, always with the source link. Nobody types them in. (Agreed 22 Oct.) |
| SAP exam agent | Planned: a separate agent that answers questions about SAP exam details, called by our certification agent (true agent-to-agent). Starts as a plain search tool (`SapExamService`). |

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
| EmployeeCertifications | Read and create **own** records. Update own only while `Planned`, `LearningJourney` or `Pending`. Delete own only while `Planned`, `LearningJourney` or `Pending` (withdrawing a submission before an admin decides) | Also reads direct reports' records, **except `Rejected`** | Everything |

**AdminService** (`srv/admin-service.cds` + `.js`, at `/odata/v4/admin`, admin role only):

| Table | Admin can |
| --- | --- |
| Employees | Read, create and edit (draft) in the **Employees** app. No delete (405): set `active = false` instead. Login (`userID`) must be unique; nobody can be their own manager |
| EmployeeCertifications | Read all, plus the Approve, Reject and Revoke actions. No direct edits here. |
| Certifications | Read (for drop-down lists) |

Managers do not use AdminService. A read-only "My Team" app for managers is parked.

**AI assistant (MCP, step 12).** CertService is also served over MCP at `/mcp/cert`, using
SAP's official plugin `@cap-js/mcp` (beta, 1.5.x) and one line in `srv/protocols.cds`:
`annotate CertService with @agent @mcp @odata;` (keep `@odata`, or the Fiori apps stop working).
An AI assistant (Claude Code, or the MCP Inspector) gets two tools: `describe` (what data
exists) and `query` (a read-only CQL `SELECT`; anything else is rejected). It runs the
normal CAP service, so `@restrict` and the handlers apply: as ranjan it sees only ranjan's
records, and Days Left is filled in.

- **Autowire:** while `cds watch` runs, the plugin writes an entry `cds:CertService` into
  `~/.claude.json` (Claude Code's config) and removes it on stop. The user it logs in as
  is `cds.mcp.autowire` in `package.json` (now `ranjan` / `ranjan`; the default `alice` is
  disabled here). To switch user: change it, restart `cds watch`, open a **new** Claude
  Code session.
- **MCP Inspector** (the tool from SAP's video series) to try the tools by hand:
  `npx @modelcontextprotocol/inspector@1.0.2` (version 1, as the guide recommends; without
  the version you get version 2, which also works). Connect with Streamable HTTP, URL
  `http://localhost:4004/mcp/cert`, header `Authorization: Basic <base64 of user:password>`
  (ranjan = `cmFuamFuOnJhbmphbg==`).
- **Source:** Ranjan's study guide of SAP's video series "CAP in the Age of AI" (Expert
  Session #6 and Episodes 1-5): `@cap-js/mcp`, then `@cap-js/agents` for A2A.

**AI agent (A2A, step 13).** `@agent` on CertService (plugin `@cap-js/agents`, beta 0.9.x)
makes it an agent that other agents and chat UIs can talk to in plain language, at
`/a2a/cert` (agent card at `/a2a/cert/.well-known/agent-card.json`, built-in chat at
`/a2a/cert/preview`). The model runs **inside the CAP app** and uses the MCP tools
(`describe`, `query`), so the same login and rules apply. Which model is
`cds.requires.llm`, set **only in the local `.env` file** (not in `package.json`; decided
16 Oct). `.env` is ignored by git; `.env.example` is the committed template. It has one
"model block" per model; keep exactly **one** active (the others commented out with `#`),
then restart plain `cds watch`. Check the active one with `cds env requires.llm`.

- Groq (free tier): `kind=openai`, `model=openai/gpt-oss-120b`,
  `credentials.baseURL=https://api.groq.com/openai/v1`, key `OPENAI_API_KEY`.
- SAP AI Core (company, instance `gen-ai-a2a`, plan `extended`): `kind=aicore`, a model
  from AI Launchpad, key `AICORE_SERVICE_KEY` (the service key as one line of JSON).
- Fake model, no AI: `kind=llm-mock`.
- If no block is active, the plugin falls back to `auto`, which hits its mock bug, so
  always keep one active. Keys live in `.env` only; never in `package.json` or chat.

**How the agents behave (`srv/agent-rules.cds`, 20 Oct).** The doc comment on each
service is that agent's instructions. Every AI action that changes data has
`@agent.hitl` (human in the loop): the agent stops and shows the action it wants to run;
the user answers `approve` to run it, anything else cancels it. This applies to the
built-in agents only; Claude Code (MCP) asks for permission in its own way.

**Employees and logins are separate.** An employee record (`userID`) only links data to a
login name. Adding an employee in the app does **not** create a login: logins are the
mocked users in `package.json` now, and the company login (XSUAA) after deployment.
A new employee can log in only once a login with the same name exists.

**Adding a new employee in the cloud (agreed 23 Oct) takes two steps, in any order:**
(1) in the BTP cockpit, give them the role collection "CertManager Employee" (or
"CertManager Admin"); (2) in the Employees app, create their record with `userID` = their
exact login name. Only step 1: they can log in but can't create records. Only step 2:
they can't get in. When someone leaves: remove the role collection and set Active off;
their history stays.

**Watch out when adding links to the database model:** a new association on a database
entity appears in **every** service built on it. Check each service's `@restrict` rules,
and use `excluding { … }` in a projection where a service must not offer the link
(e.g. `certifications` on `Employees` in CertService, found 15 Oct).

**Creating and editing in the Certifications app** uses draft (`@odata.draft.enabled` on
`EmployeeCertifications` in CertService). Create and Edit open a working copy; the rules
in `cert-service.js` (`before CREATE` / `before UPDATE`) run when the user clicks Save. A
new draft gets the logged-in employee filled in at once (`before NEW` on
`EmployeeCertifications.drafts`), and the Employee field is read-only on the page. The
certificate is picked from a value help on `Certifications`. A manager still sees an Edit
button on team records; clicking it gives 403 (accepted for now).

## Where things are

| File | What it does |
| --- | --- |
| `db/schema.cds` | Data model: 3 tables and the `Statuses` code list |
| `db/data/*.csv` | Seed data: 10 SAP certifications, 5 employees, 10 records |
| `srv/cert-service.cds` | The OData service `CertService` and who can do what |
| `srv/cert-service.js` | Business rules (before CREATE/UPDATE) and the days-left calculation (READ) |
| `srv/admin-service.cds` | `AdminService` for the admin apps: entities and the approve / reject / revoke actions |
| `srv/admin-service.js` | The action logic: one `changeStatus` helper that checks the current status |
| `srv/lib/expiry.js` | Date helpers: `today`, `addOneYear`, `daysUntil`, `criticality` |
| `srv/lib/expiry-fields.js` | `addExpiryFields(srv, entity)`: the READ handlers that fill Days Left and its colour; called by both services |
| `app/certifications/annotations.cds` | Fiori UI: table columns, filter bar, object page |
| `app/certifications/webapp/` | Generated Fiori app (`manifest.json` etc.). Usually no need to edit. |
| `app/approvals/annotations.cds` | Fiori UI for the admin **Approvals** app (on AdminService) |
| `app/approvals/webapp/` | Generated Approvals app. Open at `/approvals/webapp/index.html` |
| `app/employees/annotations.cds` | Fiori UI for the admin **Employees** app (on AdminService): list, details, manager value help (active only), certifications table with Approve / Reject / Revoke |
| `app/employees/webapp/` | Generated Employees app. Open at `/employees/webapp/index.html` |
| `app/labels.cds` | Field labels (`@Common.Label`) on the database entities, shared by every service and app |
| `app/services.cds` | Pulls the labels and the UI annotations of both apps into the build |
| `_i18n/i18n.properties` | All UI texts. Label keys used by `app/labels.cds` live here |
| `package.json` | Dependencies, scripts, mocked users |
| `test/admin.http` | Manual API tests (REST Client extension). Run requests 1-9 in order after starting the server |
| `srv/protocols.cds` | Which protocols each service is served over (`@odata`, `@mcp`, `@agent`), all in one file. Keep `@odata` on every service |
| `srv/agent-rules.cds` | How the built-in agents behave: their instructions (doc comment per service) and which actions need the user's approval (`@agent.hitl`) |
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
| Action buttons use `@Core.OperationAvailable` with `$self.status.code`, and the server checks again | The UI only offers moves that are allowed; the server still blocks direct API calls. Inside annotation expressions write `status.code`; `status_code` does not compile there |
| Draft on `EmployeeCertifications` in CertService only (15 Oct) | Fiori elements V4 shows Create / Edit only with draft. AdminService stays without draft: the admin changes records only through the actions |
| The employee on a new record is filled in on `NEW` (draft start), not on Save (15 Oct) | `@mandatory` is checked before the CREATE handler runs, so filling it in on Save is too late (`ASSERT_MANDATORY`) |
| Employee field read-only in the Certifications app for everyone, admins included (15 Oct) | This is the employee's own app. Assigning or correcting the person belongs in the Employees app. A per-user editable field (dynamic `FieldControl`) was prototyped and dropped as not needed |
| Status is a code list (`Statuses : sap.common.CodeList`), not an enum (14 Oct) | Gives a dropdown in the filter bars, readable names ("Learning Journey"), translatable names later, and `@assert.target` rejects unknown codes. The codes stayed the same text, so no data changed |
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
  Merged into `main` and pushed (14 Oct, `main` at `86c14ac`).
- `story/status-codelist` (from `main`): step 10, status as a code list. Merged into
  `main` and pushed (15 Oct, `d79a20a`).
- `story/draft` (from `main`): step 11, draft in the Certifications app. Current work.
- New work goes on a `story/<short-name>` branch.
- Commit messages follow the step numbers: `1`, `2`, `3a`, `3b` ... `6c`.
- Pushing needs the `ghimire-ranjan` GitHub account. The `ranjan-ghimire` work account gets
  a 403 error.
