# Maturity levels

Estimate each requested level separately. Never call a happy path production-ready.

| Level | Required outcome | Say it to the reader as |
|---|---|---|
| Demo | Controlled happy path is demonstrable; mocks/manual setup and known gaps are allowed. | Shows the flow to stakeholders; not for real users. Checked by a manual walkthrough. |
| Alpha | Core end-to-end flow works on real data; limited edge-case and operational coverage is allowed. | A small internal group can use it on real data. Automated checks cover the main flow. |
| Beta | Intended flows, roles, states, migrations, automated tests, and integration contracts are complete. | Releasable to users. Automated checks cover the flows, access rights, data migrations, and the joins between the parts. |
| Production-ready | Beta plus the safeguards the changed paths actually require, drawn from authorization abuse cases, retries/idempotency, backfill, observability, browser/device QA, rollback/rollout safety, and fixes from final review. | Runs at full load unattended. Adds checks under heavy load and failure, monitoring, and a rollback that has been rehearsed. |

Production-ready means the requested behavior is safe to release, not that every safeguard in the row was rebuilt.
Reuse existing authorization, idempotency, observability, and rollout mechanisms and schedule zero days for them. Add
schema changes, migrations, backfill, external integrations, cross-client work, or device QA only when the literal
scope or the code requires them.

Skip levels the user does not need, but always distinguish the requested result from the next-lower level. Report a
level above Demo only when you can name the work it adds over the level below. Never print a level and disclaim it in
the same breath: a rung you would immediately call redundant for this surface is dropped, not footnoted — the reader
quotes the number, not the caveat. When the remaining work is a bounded change to existing code — no new entity, no
new integration, no schema migration — the ladder collapses: report one implementation lane plus focused verification,
and do not decompose it into four rungs.
