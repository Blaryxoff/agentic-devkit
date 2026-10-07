# NestJS Testing

- Follow the target project's test policy, runner, file naming, and commands. Use `@nestjs/testing` when dependency injection, guards, pipes, interceptors, or module wiring affect the behavior.
- Test domain and provider behavior through public methods. Replace owned network and queue boundaries with fakes; control time and retry outcomes.
- Test HTTP validation, authentication, authorization, response shape, and exception mapping through a bootstrapped Nest application when those boundaries change.
- Run persistence, transaction, uniqueness, tenant isolation, and job enqueue guarantees against a dedicated test database. Keep each test isolated and never point it at shared data.
- Assert observable behavior and failure paths. Ensure a test would fail if the production behavior were removed or inverted.
