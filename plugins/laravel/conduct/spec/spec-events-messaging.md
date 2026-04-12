# Spec Extension: Events / Messaging Layer

> Include this block when the feature produces or consumes events, broadcasts, notifications, or queue payload contracts.

## EV-1. Messaging Infrastructure

```
Technology:    [ ] Laravel Events  [ ] Queue jobs  [ ] Notifications
               [ ] Broadcasting (WebSockets)  [ ] Redis pub/sub  [ ] External broker
Pattern:       [ ] Point-to-point job  [ ] Pub-sub event  [ ] Broadcast stream
Ordering:      [ ] Strict order required  [ ] Best-effort
Durability:    [ ] At-most-once  [ ] At-least-once
```

## EV-2. Channels / Queues / Event Names

For each event/queue channel:

```
### Event/Queue: [name]

Full name:            `[env].[context].[entity].[action]` (e.g., `prod.billing.invoice.created`)
Type:                 Event | Queue | Broadcast channel
Producers:            [class/service name(s)]
Consumers:            [listener/job/client name(s)]
Retention:            X hours/days (if applicable)
Expected volume:      X events/min at peak
Failed handling:      failed_jobs table / dead-letter strategy (if external broker)
```

## EV-3. Message / Event Schema

For each event type:

```
### Event: [EventName] (e.g., InvoiceCreated)

Version:  v1
Class:    App\Events\[EventName]

Payload:
{
  "invoice_id": "uuid",
  "user_id": "uuid",
  "amount_cents": 0,
  "currency": "USD",
  "line_items": [
    {
      "description": "string",
      "quantity": 0,
      "unit_price_cents": 0
    }
  ],
  "metadata": {}
}
```

**Invariants (must always be true when this event is emitted):**

- `amount_cents` equals sum of `line_items[*].quantity * unit_price_cents`
- `invoice_id` exists in the invoices table

**Consumers of this event:**

| Consumer | Action | SLA |
|---|---|---|
| Notification listener | Send invoice email | Best-effort |
| Analytics listener | Update revenue metrics | < 30s lag |

## EV-4. Producer Contract

For each producer:

```
### Producer: [Class/ServiceName]

Emits:               [EventName list]
When:                Business condition that triggers each event
Ordering guarantee:  Events for same entity ordering required? yes / no
Transactional:       [ ] Emit inside DB transaction  [ ] afterCommit  [ ] best-effort
```

## EV-5. Consumer Contract

For each consumer:

```
### Consumer: [Listener/JobName] consuming [EventName]

Queued:                       yes / no
Queue:                        [queue-name]
Concurrency:                  N workers
Processing model:             [ ] One-at-a-time  [ ] Batch/chunked
Max processing time/message:  Xs

Processing steps:
1. Validate payload
2. Check idempotency key (if required)
3. Execute business logic
4. Mark complete / ack job

Idempotency:
- Idempotency key: [event id / business key]
- Deduplication store: cache key / processed_events table
- Behavior on duplicate: log and skip
```

## EV-6. Ordering & Sequencing

- Are events expected to arrive in order? Yes / No
- If yes: how is ordering guaranteed?
- What happens if an event arrives out of order? (skip/requeue/apply)
- Are there events that MUST be processed before others? Describe chain.

## EV-7. Schema Evolution

- Versioning strategy: payload version key / event class versioning / channel versioning
- Backward compatibility rule: **always additive** — new optional fields only
- Breaking changes require: new version + migration period

## EV-8. Operational Runbook Stubs

- **Replay failed work:** how to replay failed jobs/events
- **Drain failure backlog:** process for investigating and retrying failures
- **Pause consumers/workers:** how to stop safely without data loss
- **Scale processing:** how to add/remove workers safely
