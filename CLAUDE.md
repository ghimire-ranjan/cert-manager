# cert-manager

SAP CAP + Fiori elements app that tracks employee SAP certifications and their expiry.

## Read these first

1. [docs/context.md](docs/context.md): what the app does, rules, roles, file map, how to run
2. [docs/tasks/todo.md](docs/tasks/todo.md): open bug, next steps, parked items
3. [docs/CHANGELOG.md](docs/CHANGELOG.md): full history, newest first

## Working rules

- **Claude never writes or edits code in this project.** Ranjan writes all code himself.
  Claude may only write `CLAUDE.md`, the files in `docs/`, and i18n `.properties` text
  files (when Ranjan asks). When code is needed, explain
  what to change and where (file, line, short snippet in the chat), then let Ranjan type it.
- The owner is a junior technical consultant. Keep code and explanations simple, in plain
  English. Explain any jargon in one line.
- Use plain CAP and Fiori elements (annotations). No extra libraries unless agreed.
- Business rules belong in `srv/cert-service.js`; UI belongs in
  `app/certifications/annotations.cds`; labels go in `_i18n/i18n.properties`.
- After every change, add a line under **Unreleased** in `docs/CHANGELOG.md`.
- When a task is done or a new one appears, update `docs/tasks/todo.md`.
- When the model, roles, rules or decisions change, update `docs/context.md`.
- Run locally with `npx cds watch`, then log in as `chris` / `chris` (admin) or
  `ranjan` / `ranjan` (employee).
