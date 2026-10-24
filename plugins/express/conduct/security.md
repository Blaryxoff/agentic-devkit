# Express Security

- Resolve the authenticated actor and current workspace on the server. Treat client workspace IDs, roles, object IDs, and job payload scope as claims requiring authorization.
- Apply object and nested-resource access checks to reads and writes, exports, file downloads, search results, streams, vector filters, and collaboration connections. A valid login does not grant access to another tenant's resource.
- Keep cookie and bearer transports distinct. Preserve HttpOnly/Secure/SameSite cookie policy and CSRF protection for ambient-cookie mutations; use narrow CORS origin/credential rules. Serialize refresh requests and bound retries in clients.
- Configure `trust proxy` for the actual trusted topology before depending on client IPs, secure cookies, or rate limits. Apply request size limits, upload limits, authentication throttles, and safe error responses.
- Validate outbound schemes and destinations for URL fetch/import, redirects, callbacks, and embedded services. Block access to private/metadata networks where users choose a URL; recheck redirects and resolution through the project's SSRF control.
- Authorize object-storage keys before issuing signed URLs; enforce upload size/type policy and safe filenames. Treat extracted documents, generated HTML, tool arguments, and model output as untrusted input.
- Keep provider keys server-side. Redact cookies, bearer tokens, secrets, prompts containing private content, and personal data from logs; retain safe request/job IDs for diagnosis.
- Use the project's maintained password hashing and constant-time verification helpers; never store plaintext or manually compare hashes. Preserve token expiry/rotation/revocation policy, TLS, security headers, and session invalidation when auth changes.

Sources: [Express security](https://expressjs.com/en/advanced/best-practice-security.html), [proxy configuration](https://expressjs.com/en/guide/behind-proxies.html), [OWASP API object authorization](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/).
