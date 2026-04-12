# Observability

This document covers distributed tracing and metrics collection using OpenTelemetry. For logging conventions, see [logging.md](./logging.md).

## Technology stack

| Signal | SDK | Exporter | Backend |
|--------|-----|----------|---------|
| Traces | `open-telemetry/opentelemetry` (PHP SDK) | OTLP HTTP | OTEL Collector → Jaeger / Tempo |
| Metrics | OpenTelemetry metrics SDK or Prometheus-compatible exporters | OTLP / Prometheus scrape | OTEL Collector → Prometheus |
| Logs ↔ Traces | Laravel `Log::withContext()` + Monolog processors | — | Correlated via `trace_id` |

## OTEL provider initialization

All telemetry providers are initialized during Laravel bootstrap alongside logging and config. A single telemetry bootstrap path should set up both `TracerProvider` and `MeterProvider`.

### Config

Store telemetry settings in `config/telemetry.php` (`enabled`, `endpoint`, `service_name`, `sample_rate`). Initialize `TracerProvider` + `MeterProvider` once in the app provider's `boot()`, gated by `config('telemetry.enabled')`. For queue workers, initialize on worker boot.

## Tracing

### Span naming conventions

| Component | Span name format | Example |
|-----------|-----------------|---------|
| Service method | `ServiceName.methodName` | `UserService.createUser` |
| Repository method | `RepositoryName.methodName` | `UserRepository.findById` |
| HTTP handler | auto via middleware | `GET /api/v1/users/{id}` |
| Queue job | `job.ClassName.handle` | `job.SendInvoiceJob.handle` |
| External client | `client.Service.operation` | `client.Stripe.createPaymentIntent` |

### Creating spans in services and repositories

```php
$span = $tracer->spanBuilder('UserService.createUser')->startSpan();
$scope = $span->activate();
try {
    $span->setAttribute('email_domain', Str::after($payload['email'] ?? '', '@'));
    $user = User::query()->create($payload);
    $span->setAttribute('user_id', (string) $user->id);
    return $user;
} catch (\Throwable $exception) {
    $span->recordException($exception);
    $span->setStatus(StatusCode::STATUS_ERROR, 'failed to create user');
    throw $exception;
} finally {
    $scope->detach();
    $span->end();
}
```

### Tracer/meter field in structs

Every service and repository that creates spans should resolve a `TracerInterface` once via constructor DI, then reuse it. Apply the same pattern for `MeterInterface`.

### HTTP and queue instrumentation

- Register `TraceContextMiddleware` in the HTTP kernel for automatic request spans
- In queue jobs, start a span in `handle()`, attach job name and context, record exceptions on failure

### Context propagation

- **Always** propagate trace context from incoming HTTP request → middleware → controller → service → repository → external client.
- For async jobs and outbound HTTP requests: inject/extract W3C trace headers (`traceparent`, `tracestate`) so traces stay connected across boundaries.

```php
// Outbound HTTP request
Http::withHeaders([
    'traceparent' => $traceparent,
])->post($url, $payload);

// Inbound request / webhook
$traceparent = request()->header('traceparent');
```

### Span attributes rules

**DO add:**
- Entity IDs (user_id, order_id, tenant_id)
- Operation type (query, command)
- Email domain (not full email)
- Status codes, error types

**DO NOT add:**
- PII: full emails, names, phone numbers, addresses
- Secrets: tokens, passwords, API keys
- Large payloads: request/response bodies, file contents
- High-cardinality values that would explode the trace backend (e.g. raw UUID payload fields)

## Metrics

### Prometheus endpoint

Expose `/metrics` on the Laravel app only if your deployment model supports it, and restrict access (internal network or auth).

### RED metrics (automatic via middleware)

HTTP middleware and reverse proxy instrumentation should emit the core RED metrics. Keep manual instrumentation focused on business-critical paths:

| Metric | Type | Labels | Source |
|--------|------|--------|--------|
| `http_server_request_duration_seconds` | Histogram | `method`, `route`, `status_code` | Laravel HTTP middleware / OTEL instrumentation |
| `http_server_request_total` | Counter | `method`, `route`, `status_code` | Laravel HTTP middleware / OTEL instrumentation |
| `queue_job_duration_seconds` | Histogram | `job`, `queue`, `status` | Queue job instrumentation |

### Infrastructure metrics

Standard infrastructure metrics to instrument:

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `db_query_duration_seconds` | Histogram | `repo`, `method` | Database query latency |
| `db_connection_pool_active` | Gauge | `connection` | Active DB connections |
| `db_connection_pool_idle` | Gauge | `connection` | Idle DB connections |
| `redis_operation_duration_seconds` | Histogram | `operation` | Redis command latency |
| `redis_hit_total` | Counter | `operation` | Redis cache hits |
| `redis_miss_total` | Counter | `operation` | Redis cache misses |
| `queue_job_processed_total` | Counter | `queue`, `job` | Processed queue jobs |
| `queue_job_failed_total` | Counter | `queue`, `job` | Failed queue jobs |
| `queue_depth` | Gauge | `queue` | Pending jobs in queue |

### Runtime metrics (PHP / Nginx)

Enable runtime and process metrics collection from:

- PHP-FPM (process count, worker saturation, request duration)
- Nginx (request rate, response codes, upstream latency)
- Host/container runtime (CPU, memory, disk, network)

Collect these metrics via infrastructure exporters and correlate with application traces.

### Metric naming conventions

Follow Prometheus naming best practices:

| Rule | Example |
|------|---------|
| Use `snake_case` | `db_query_duration_seconds` |
| Include unit as suffix | `_seconds`, `_bytes`, `_total` |
| Use `_total` suffix for counters | `requests_total`, `errors_total` |
| Prefix with component | `db_`, `redis_`, `queue_`, `http_` |
| Avoid high-cardinality labels | Never use user IDs, request IDs, or UUIDs as label values |

### Metric types — when to use what

| Type | Use when | Example |
|------|----------|---------|
| Counter | Value only goes up | `requests_total`, `errors_total` |
| Histogram | Measuring distributions (latency, size) | `request_duration_seconds`, `response_size_bytes` |
| Gauge | Value goes up and down | `active_connections`, `queue_depth` |

Services or repositories that emit custom metrics should receive metric instruments via dependency injection and reuse them (same DI pattern as tracers above).

## Logs ↔ Traces correlation

When Laravel logging is configured to include trace context (see [logging.md](./logging.md)), the trace ID and span ID are included in log entries. This enables:

- **From log → trace**: search by `trace_id` field in logs to find the corresponding trace in Jaeger/Tempo
- **From trace → logs**: copy the trace ID from your tracing backend and search in your log aggregation tool

No additional per-method configuration is needed when both tracing and request log context conventions are used.

## Infrastructure overview

```
┌───────────────────────┐    OTLP/HTTP      ┌──────────────────┐
│ Laravel App           │ ─────────────────► │  OTEL Collector  │
│ (Nginx + PHP-FPM)     │                    │                  │
│                       │                    │  ┌────────────┐  │
│ /metrics (optional) ◄─┤                    │  │ processors │  │
└───────────────────────┘                    │  └────────────┘  │
                                             │        │         │
                                             │   ┌────┴────┐    │
                                             │   ▼         ▼    │
                                             │ Jaeger/Tempo Prometheus
                                             └──────────────────┘
```

- **App → Collector**: traces are sent via OTLP HTTP to the Collector
- **App /metrics**: Prometheus scrapes `/metrics` when enabled and exposed safely
- **Collector → Jaeger/Tempo**: Collector forwards traces for storage and querying
- **Collector → Prometheus** (optional): Collector can also forward metrics via remote write

### OTEL Collector endpoint config

The app connects to the Collector via the `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable:

| Environment | Endpoint |
|-------------|----------|
| Local | `http://localhost:4318` |
| Dev | `http://otel-collector.dev:4318` |
| Production | `http://otel-collector.prod:4318` |

## DO / DO NOT

**DO:**
- initialize both `TracerProvider` and `MeterProvider` in app bootstrap
- shut down/flush providers gracefully for worker processes on stop
- create spans in services, repositories, and queue jobs with descriptive names
- propagate trace context through HTTP, queues, and outbound requests
- use `recordException` and set error status on failures
- use middleware-based instrumentation for HTTP entrypoints
- follow Prometheus naming conventions for metrics
- use exemplars to link metrics to traces where supported
- include Nginx and PHP-FPM metrics in dashboards

**DO NOT:**
- start a new root context in the middle of a request/job chain
- add PII, secrets, or large payloads to span attributes
- use high-cardinality values (user IDs, UUIDs) as metric labels — this causes cardinality explosion in Prometheus
- duplicate root spans in controllers when HTTP middleware already creates server spans
- skip span close/end in custom instrumentation — this causes span leaks
- use manual `microtime` timing everywhere instead of shared instrumentation primitives
- duplicate error reporting in logs and spans without additional context
