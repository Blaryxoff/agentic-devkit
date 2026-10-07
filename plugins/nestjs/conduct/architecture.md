# NestJS Architecture

- Group related controllers, providers, and adapters in a feature module. Export a provider only when another module consumes its public contract.
- Keep controllers limited to parsing transport input, invoking an application operation, and mapping the result to a response. Put rules and state transitions in providers or domain code.
- Introduce a domain layer, repository interface, or command abstraction only when a real invariant, multiple implementations, or repeated use justifies it. Match neighboring modules before adding new layers.
- Inject external clients and persistence through Nest providers so operations can be tested without real network calls. Keep provider scopes at the default singleton unless request state requires otherwise.
- Put API request and response schemas at the project's contract boundary. Do not let a web client or worker invent a second version of the same contract.
- Separate transport failures from domain failures. Preserve a consistent public error shape and avoid leaking internal exceptions.
- For asynchronous workflows, name the initiating operation, persisted state, job payload, retry policy, and recovery path. Treat handlers as repeatable and make duplicate delivery safe.
