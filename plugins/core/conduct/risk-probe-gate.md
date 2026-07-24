# Risk Probe Gate

Use these probes as an internal final pass at the end of a review, plan analysis, or post-implementation verification.
Their purpose is to discover overlooked risks, not to produce a compliance appendix.

## Probes

### A. First-break

Ask what concrete real-world scenario is most likely to break first for a specific user, client, job, or integration.
Treat it as a finding only when code, product requirements, or observed behaviour supports both the failure and its
relative likelihood. Do not invent or rank speculative candidates merely to answer the probe.

### B. Chaos

For state-changing, asynchronous, retryable, or concurrent paths, consider only relevant interaction sequences such as
double-submit, refresh mid-mutation, racing tabs, reconnect, webhook replay, retry storms, and clock skew. There is no
minimum case count. Report only a sequence that exposes an unhandled failure.

### C. User-assumption

When user-facing behaviour changed, inspect it as a first-time user. Look for missing labels, instructions, empty-state
guidance, error recovery, or next-step actions. Report only an unsupported assumption that creates a concrete usability
failure.

## Reporting

- Fold each newly discovered, evidence-backed risk into the normal findings format.
- Use the review's existing severity rubric; a probe does not raise severity by itself.
- Cite the relevant file and line, requirement, or observed behaviour.
- Do not append a separate Risk Probes block.
- Do not report covered, resolved, or not-applicable cases.
- If the probes reveal nothing new, emit nothing.
