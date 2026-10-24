# React State and Async Data

- Assign server data to the existing query/cache layer and client UI/session state to local hooks or the existing store. Do not mirror query results into Zustand without a concrete ownership requirement.
- Include every result-changing parameter and authorized account/workspace scope in query keys. Disable protected queries until session restoration completes; cancel/clear scoped caches on logout or account/workspace changes so old responses cannot populate a new session.
- Keep QueryClient lifetime stable per client app and request-isolated on SSR. Review stale time, refetch triggers, retries, and cache retention against the installed TanStack Query major; defaults are product behavior, not neutral tuning.
- Invalidate or update affected keys after successful mutations. For optimistic updates, cancel conflicting fetches, snapshot state, handle rollback and overlapping mutations, then reconcile with the server.
- Use narrow Zustand selectors with stable outputs. Follow the installed major's equality/selector APIs; immutable updates and stable snapshots prevent missed changes and render loops.
- Create request-isolated stores for SSR and align server/client initial state before hydration. Keep credentials out of serialized page props and persist only fields intended for the selected platform storage.
- Own stream lifecycle in one abstraction: authenticate, parse/validate events, bound buffers, handle terminal errors, and dispose listeners/connection on unmount or scope change. Prevent delayed callbacks from writing into a different account's state.

Sources: [TanStack Query defaults](https://tanstack.com/query/v5/docs/framework/react/guides/important-defaults), [query keys](https://tanstack.com/query/v5/docs/framework/react/guides/query-keys), [Zustand v5 migration](https://zustand.docs.pmnd.rs/reference/migrations/migrating-to-v5), [Zustand Next.js guide](https://zustand.docs.pmnd.rs/learn/guides/nextjs).
