# Spec Extension: Jobs / Scheduler Layer

> Include this block when work runs asynchronously via Laravel queues or schedule.

## JS-1. Job / Command Identity

```
Type:         [ ] Queued Job  [ ] Listener (ShouldQueue)  [ ] Scheduled Command
Trigger:      [ ] HTTP request  [ ] Domain event  [ ] Scheduled (cron)  [ ] Manual
Queue:        [queue name]
Connection:   [redis | database | sqs | ...]
Ownership:    Team / repo
```

**Responsibility statement:** One paragraph — what does this unit do, and what does it explicitly NOT do?

## JS-2. Trigger & Schedule

For scheduled commands:

```
Schedule:          dailyAt('02:00') / cron('0 2 * * *')
Timezone:          UTC / app timezone
Expected duration: ~X minutes
Timeout:           X seconds
Overlap policy:    withoutOverlapping / allow overlap
```

## JS-3. Processing Logic

Describe the lifecycle of one unit of work:

1. **Trigger** — how does work arrive?
2. **Fetch** — what data is loaded, and from where?
3. **Validate** — what is checked before processing?
4. **Process** — core business logic steps
5. **Persist** — what gets written and where?
6. **Emit** — what events/notifications/side effects are triggered?
7. **Complete** — when is work considered done?

**Batch vs single-item processing:**
- Processing granularity: one-at-a-time vs chunks of N
- Parallelism: queue workers/concurrency limits
- Ordering guarantees: strict order required? best-effort?

## JS-4. State Management & Idempotency

| State | Where stored | TTL / cleanup |
|---|---|---|
| In-progress locks | Cache/Redis | X min with renewal |
| Processed IDs | DB table / cache key | Rolling window |
| Intermediate results | DB/cache/memory | Per-run / scheduled cleanup |

- Is it safe to process the same payload twice? Yes / No
- Deduplication key and mechanism (if safe to retry)
- Lock/guard mechanism (if NOT safe to retry)

## JS-5. Error Handling

| Error type | Behavior | Retry? | Failed jobs/DLQ? |
|---|---|---|---|
| Transient (network, timeout) | Retry with backoff | Yes, N times | Yes after max retries |
| Validation failure | Mark failed / skip | No | Optional |
| Business rule violation | Log warning | No | Optional |
| Unhandled exception | Fail + alert | Queue retry policy | Yes |

**Retry policy:**
- `tries`: N
- Backoff: fixed/exponential (`backoff` value)
- Timeout: `timeout` seconds

**Failed jobs handling:**
- Failed jobs table enabled? yes / no
- Who monitors failed jobs?
- Resolution process (manual replay, auto-discard policy)

## JS-6. Scalability

- Expected throughput at launch: X jobs per [minute/hour]
- Expected throughput at peak: X
- Scaling mechanism: worker count / Horizon balancing / manual
- Scaling trigger: queue depth > N, runtime latency > X
- State sharing between workers: cache/Redis/DB

## JS-7. Deployment & Operations

- Worker process manager: Supervisor / Horizon / platform-native
- Queue worker command options (`--queue`, `--sleep`, `--tries`, `--timeout`)
- Graceful shutdown behavior during deploy
- Health checks / queue backlog monitoring
