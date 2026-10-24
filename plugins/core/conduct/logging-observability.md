# Logging and Observability

Load this document for diagnostics, request/job context, tracing, metrics, or operational review. Use the project's installed logger and approved telemetry stack; this policy does not authorize installing a collector, exporter, or SDK.

## Structured logging

| Level | Meaning |
|---|---|
| Debug | Bounded diagnostic detail; disabled or sampled in production |
| Info | Meaningful normal lifecycle/business event |
| Warn | Recoverable failure, retry, degraded dependency, or operational anomaly |
| Error | Operation failed; the process remains usable |
| Fatal/emergency | Bootstrap or runtime-critical failure requiring shutdown |

- Enrich inherited request/job context at service, repository, client, and handler boundaries with component and operation names plus allowlisted identifiers. Avoid per-method success noise and raw argument dumps.
- Propagate request/correlation ID and, when tracing exists, trace/span IDs across HTTP, queues, callbacks, and outbound calls. Scope context to the operation; concurrent tenants must not inherit another request's logger fields.
- Log failures once at their reporting owner with stable code, safe cause/stack, retry attempt, and outcome. Lower layers add useful context without emitting the same failure again.
- Redact credentials, cookies, tokens, signed URL query strings, personal data, prompts/documents, and full request/response bodies. Bound event size; record lengths or safe hashes instead of blobs.
- Use the logger rather than production debug prints. Keep client logs and diagnostic exports as sensitive as server logs; do not send secrets or full crash state to a renderer or telemetry provider.

## Traces and metrics

- Initialize approved Node instrumentation before importing instrumented clients when its SDK requires that order; reuse the existing application provider rather than creating a provider per module.
- Name spans with bounded operation names. Propagate standard trace context through owned HTTP and job carriers; validate untrusted baggage and do not put credentials or personal content in it.
- End spans and record failure/cancellation consistently in success, exception, timeout, and disconnect paths. Flush/shutdown exporters with a deadline during process exit.
- Measure request rate/errors/duration, queue depth/age/failures/duration, database pool/query pressure, provider timeouts, and resource saturation when those are the changed operational risks.
- Keep metric labels bounded: route templates, operation type, outcome, and approved dimensions. User IDs, document IDs, request IDs, full URLs, and error messages belong outside metric labels.
- Check event-loop lag/CPU/memory for Node, JS/UI frame time and memory for native, and main/renderer responsiveness for Electron. Profile the relevant production-like build before claiming an optimization.
- Keep scrape/debug endpoints private or authorized. Define sampling, retention, sensitive-field policy, alert owner, and a usable correlation path from log to trace when introducing telemetry.
- Link an operational failure to a recovery procedure: diagnose, pause/drain, retry/replay safely, roll back, and confirm recovery. Verify signals with a focused failure probe in an isolated environment when authorized.

Source: [OpenTelemetry JavaScript instrumentation](https://opentelemetry.io/docs/languages/js/instrumentation/).
