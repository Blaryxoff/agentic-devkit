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

```php
// config/telemetry.php

return [
    'enabled' => env('TELEMETRY_ENABLED', false),
    'endpoint' => env('OTEL_EXPORTER_OTLP_ENDPOINT', 'http://localhost:4318'),
    'service_name' => env('OTEL_SERVICE_NAME', 'grow-place'),
    'sample_rate' => (float) env('OTEL_TRACES_SAMPLE_RATE', 1.0), // 0.0 to 1.0
];
```

### Initialization in bootstrap / provider

```php
// app/Providers/AppServiceProvider.php

public function boot(): void
{
    if (! config('telemetry.enabled')) {
        return;
    }

    // Initialize TracerProvider + MeterProvider once per process
    // using OTEL endpoint, service name, and sample rate from config.
    // Keep provider construction in a dedicated bootstrap class.
}
```

### Wiring for HTTP and queue workers

```php
// App bootstrapping rule of thumb:
// - HTTP requests (Nginx -> PHP-FPM): initialize telemetry in app bootstrap
// - Queue workers (php artisan queue:work): initialize telemetry on worker boot
```

## Tracing

### Span naming conventions

| Component | Span name format | Example |
|-----------|-----------------|---------|
| Service method | `ServiceName.methodName` | `UserService.createUser` |
| Repository method | `RepositoryName.methodName` | `UserRepository.findById` |
| HTTP handler | auto via middleware | `GET /api/v1/users/{id}` |
| Queue job | `job.ClassName.handle` | `job.SendInvoiceJob.handle` |
| External client | `client.Service.operation` | `client.Stripe.createPaymentIntent` |

### Creating spans in services

```php
use OpenTelemetry\API\Globals;
use OpenTelemetry\API\Trace\StatusCode;

public function createUser(array $payload): User
{
    $tracer = Globals::tracerProvider()->getTracer('user_service');
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
}
```

### Creating spans in repositories

```php
use OpenTelemetry\API\Globals;

public function findById(int $id): ?User
{
    $tracer = Globals::tracerProvider()->getTracer('user_repository');
    $span = $tracer->spanBuilder('UserRepository.findById')->startSpan();
    $scope = $span->activate();

    try {
        $span->setAttribute('user_id', (string) $id);
        return User::query()->find($id);
    } finally {
        $scope->detach();
        $span->end();
    }
}
```

### Tracer field in structs

Every service and repository that creates spans should resolve a tracer once (constructor or service container), then reuse it:

```php
use OpenTelemetry\API\Globals;
use OpenTelemetry\API\Trace\TracerInterface;

final class UserService
{
    public function __construct(
        private readonly UserRepository $repository,
        private readonly TracerInterface $tracer = Globals::tracerProvider()->getTracer('user_service'),
    ) {}
}
```

### HTTP middleware (Laravel)

```php
// app/Http/Kernel.php

protected $middleware = [
    // ...
    \App\Http\Middleware\TraceContextMiddleware::class,
];
```

### Queue job instrumentation

```php
// app/Jobs/SendInvoiceJob.php

public function handle(): void
{
    // Start span for job execution, attach job name and tenant/user context,
    // record exception + status on failure, then end span.
}
```

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

Expose `/metrics` on the Laravel app only if your deployment model supports it, and restrict access (internal network or auth):

```php
// routes/web.php or routes/internal.php
Route::get('/metrics', MetricsController::class);
```

### RED metrics (automatic via middleware)

HTTP middleware and reverse proxy instrumentation should emit the core RED metrics. Keep manual instrumentation focused on business-critical paths:

| Metric | Type | Labels | Source |
|--------|------|--------|--------|
| `http_server_request_duration_seconds` | Histogram | `method`, `route`, `status_code` | Laravel HTTP middleware / OTEL instrumentation |
| `http_server_request_total` | Counter | `method`, `route`, `status_code` | Laravel HTTP middleware / OTEL instrumentation |
| `queue_job_duration_seconds` | Histogram | `job`, `queue`, `status` | Queue job instrumentation |

### Infrastructure metrics

Instrument key infrastructure components with custom metrics:

```php
// Example: database query duration
$queryDurationHistogram->record(
    $durationSeconds,
    [
        'repo' => 'user_repository',
        'method' => 'findById',
    ]
);
```

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

### Meter field in structs

Services or repositories that emit custom metrics should receive metric instruments via dependency injection and reuse them:

```php
final class UserRepository
{
    public function __construct(
        private readonly ConnectionInterface $db,
        private readonly QueryDurationHistogram $queryDuration,
    ) {}
}
```

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
