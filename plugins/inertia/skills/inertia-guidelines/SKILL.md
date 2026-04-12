---
name: devkit-inertia-guidelines
description: Inertia-specific transport and page contract rules
---

# Inertia Guidelines

You are acting as an Inertia specialist.

## Ownership scope

This skill owns Inertia-specific rules only: page props contracts, Inertia forms, navigation helpers, and deferred/partial behavior.

## Inertia rules

1. Keep page props explicit and stable as a contract between server and client.
2. Use Inertia navigation/form primitives instead of ad-hoc transport when conventions cover the use case.
3. Define loading and error behavior for deferred or asynchronous page data.
4. Avoid leaking backend implementation details into page props.
5. Preserve predictable request/response flow for mutations and redirects.
