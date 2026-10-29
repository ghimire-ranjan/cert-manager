# Checks still to do

Things that are built and tested on the laptop, but not yet checked in the cloud (or
need someone else). Work through them when the conditions are met. Tick a check when it
passes, and write down what you saw. When one fails, use "If it fails" first.

Last updated: 2026-10-29

**Before any cloud check:**

- Free HANA running? It stops every night. If the apps say "Internal Server Error" and
  the server log says "Pool resource could not be acquired", start it: a file
  `hana-start.json` with `{"data":{"serviceStopped":false}}` (outside the project), then
  `cf update-service cert-manager-hana -c hana-start.json`, wait about 4 minutes.
- `cf login -a https://api.cf.ap10.hana.ondemand.com --sso` (the login lasts a few hours).
- Login error in the browser after a deploy: use a private window (old cookies).
- Server log: `cf logs cert-manager-srv --recent`.

---

## 1. Deploy step 16 (first login)

**Waits for:** nothing, can be done any time.
**Branch:** `deployment` (step 16 merged on 29 Oct, commit `44b0f70`).

- [x] `mbt build`, `cf deploy mta_archives/cert-manager_1.0.0.mtar`, then `npm install`
      (the build can empty the laptop's `node_modules`)
- [x] Deploy ends with "Process finished." (29 Oct: first try failed because HANA was
      in its night stop; after starting HANA, `retry` finished it, database task
      SUCCEEDED, deployer stopped again)

**Watch out:** this is the first deploy that changes the database: e-mail becomes
unique, Login becomes optional. The database deployer must succeed.

**If it fails:**

- "HANA Database instance is stopped" in the deploy log, and `cert-manager-db-deployer`
  shows **Crashed** in the cockpit: HANA was asleep. Start HANA, then
  `cf deploy -i <operation id> -a retry`. If the deployer still shows "started"
  afterwards, `cf stop cert-manager-db-deployer` (it only needs to run once per deploy).
- `cf dmol -i <operation id>` downloads the deploy logs (the ID is printed at the end).
- Error about a unique constraint on `email`: two employees in the **cloud** data share
  an e-mail (the laptop data was checked and is clean). Find them in the Employees app
  and change one, then deploy again.
- `cf logs cert-manager-db-deployer --recent` shows what the database deployer did.

## 2. A colleague's first login (step 16)

**Waits for:** check 1, and a colleague who has **never** opened the app.
**Prepare:** someone assigns the colleague **CertManager Employee** on their **CIS user**
(identity provider `aalbksesi.accounts.cloud.sap`, not "Default identity provider").

- [ ] The colleague opens the Certifications app (cockpit > HTML5 Applications)
- [ ] In the Employees app (as admin) the colleague appears with their **real name**
      and **e-mail**, Login = a long ID like `0a41fa04-…`, no manager, active
- [ ] Set their manager in the Employees app
- [ ] The colleague creates a plan; it is saved with their name

**If it fails:**

- Name shows as the long ID and e-mail is empty: the company login does not send
  `given_name` / `family_name` / `email` in the token. CAP copies these into
  `req.user.attr` (see `node_modules/@sap/cds/lib/srv/middlewares/auth/jwt-auth.js`,
  around line 76). Ask the IAS / BTP admin whether those attributes are passed on.
- Colleague gets 403: the role collection is on the wrong user (check the identity
  provider column under Security > Users).
- Colleague appears twice: should be impossible (unique Login, `try/catch`); check
  `cf logs` for errors from `srv/lib/first-login.js`.

## 3. A prepared record gets linked (step 16)

**Waits for:** check 1, and a colleague who has never opened the app.

- [ ] As admin, before the colleague's first visit: Employees app > Create, enter their
      name, **their company e-mail** and a manager, leave **Login empty**, Save
- [ ] The colleague opens the app once
- [ ] Their prepared record now has their Login (long ID), the manager is still set,
      and there is **no second record** for them

**If it fails:**

- A second record appears instead: the e-mail typed in does not exactly match the one
  in their login (upper/lower case, a different alias). Compare with the e-mail the
  cockpit shows under Security > Users.
- Nothing happens: is the prepared record's Login really empty?

## 4. Readable message for an unlinked login (27 Oct fix)

**Waits for:** a user whose login has **no** employee record. Since step 16 creates
records automatically, this now only happens when someone's e-mail already belongs to
another login.

- [ ] Such a user clicks Create > Save in the Certifications app and sees
      "Your login '…' is not linked to an employee. Ask an admin to set it as Login in
      the Employees app." on the Employee field

**If it fails:** see `before CREATE` in `srv/cert-service.js`.

## 5. Approvals app tabs in the cloud (27 Oct HANA fix)

**Waits for:** nothing (as admin).

- [x] Approvals app: the tabs All / Pending / Verified / Rejected show their counts
      without "Internal Server Error" (29 Oct, after starting HANA)

**If it fails:** `cf logs cert-manager-srv --recent` and look for `SqlError`. The 27 Oct
fix is in `srv/lib/expiry-fields.js` (no `validUntil` on count queries).

## 6. Launchpad site with tiles

**Waits for:** someone giving Ranjan the role collection `Launchpad_Admin` in Sandpit.

- [ ] SAP Build Work Zone: create a site, add the four apps as tiles; admin tiles only
      for admins
- [ ] Each tile opens the right app (each app has its own inbound since 27 Oct:
      `certifications-display`, `approvals-display`, `employees-display`,
      `catalogue-display`)

- [x] (29 Oct) `Launchpad_Admin` granted; the four apps added to Work Zone's My Content

**If it fails:**

- Two tiles open the same app → check `crossNavigation` in each app's
  `webapp/manifest.json`.
- Our apps missing in Content Explorer (found 29 Oct): the `cert-manager-destination`
  resource in `mta.yaml` needs `config: HTML5Runtime_enabled: true`, because our
  destinations are created on that instance. Without it the cockpit can open the apps,
  but Work Zone's HTML5 Apps provider ignores them. After a deploy, always click
  Refresh on the HTML5 Apps provider in Channel Manager.
- The refresh report shows "Duplicate sap.app/id" for `customUI`: that is another
  project's app, not ours.
