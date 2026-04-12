# Observability

Observability covers logs, metrics, and optional traces for frontend behavior.

## Goals

- detect regressions early
- diagnose production issues quickly
- track user-impacting performance

## Core signals

- **Logs**: structured operational context (see `logging.md`)
- **Metrics**: counters/histograms for key user flows
- **Traces**: optional distributed tracing where infrastructure supports it

## Recommended frontend metrics

| Metric | Type | Notes |
|---|---|---|
| `ui_request_total` | counter | by endpoint + status |
| `ui_request_duration_ms` | histogram | API latency |
| `ui_render_duration_ms` | histogram | expensive render paths |
| `ui_error_total` | counter | by feature + error type |

## Correlation

- propagate and log `requestId`/`traceId` when available.
- include route and feature tags for each error event.
- keep labels low-cardinality to avoid noisy dashboards.

## Data safety

- never send secrets/PII in logs, traces, or metric labels.
- avoid full payload capture in telemetry.

## Alerts (example)

- error rate spikes above baseline
- p95 request latency exceeds threshold
- repeated failures on critical funnel actions

## DO / DO NOT

DO:
- instrument critical journeys first
- keep telemetry naming consistent across modules

DO NOT:
- add high-cardinality labels (user ids, raw UUIDs)
- duplicate same telemetry event in multiple layers
