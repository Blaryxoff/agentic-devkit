# Spec Extension: Infra / Nginx Layer

> Include this block when feature delivery requires Nginx or deployment-level changes.

## IN-1. Nginx Context

```
Virtual host:      [domain]
App upstream:      [php-fpm/upstream name]
Scope:             [ ] Routing  [ ] Caching  [ ] Compression
                   [ ] Security headers  [ ] Rate limits  [ ] Static assets
```

## IN-2. Routing & Rewrite Rules

- Any new route prefixes, rewrites, or location blocks
- Handling for SPA/Inertia fallback vs direct file serving
- API and web route separation expectations

## IN-3. Performance Policy

- Static assets cache policy (`Cache-Control`, immutable assets)
- Compression policy (`gzip`/`brotli`) and eligible MIME types
- Proxy/read timeouts for long-running endpoints

## IN-4. Security Policy

- TLS/redirect policy
- Security headers (HSTS, X-Frame-Options, CSP where applicable)
- Request body limits / upload limits
- IP/rate limiting rules for sensitive routes

## IN-5. Rollout / Rollback

- Deployment sequencing with Laravel app changes
- How to validate config before reload
- Rollback steps if traffic or error rates regress
