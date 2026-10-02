# State Management (Pinia)

This project uses Pinia (`@pinia/nuxt`) for cross-page state.

## When to use a store vs a composable

| Scenario | Use |
|---|---|
| State scoped to one page or feature | Composable (`useXxx`) |
| State shared across unrelated pages | Pinia store |
| State that must survive route changes | Pinia store |
| UI state (loading spinner, modal open) | Composable or component-local `ref` |
| Server-fetched data for one page | `useAsyncData` / `useFetch` in composable |

## Store definition rules

- Use composition API style (`setup` stores) — not options API style.
- Export stores as `useXxxStore` from `stores/xxx.ts`.
- Define explicit TypeScript types for state shape.
- Keep actions focused: one action = one operation.
- Delegate network requests to a composable or service and call that boundary from the store action.

```ts
// stores/catalog.ts
export const useCatalogStore = defineStore('catalog', () => {
  const items = ref<CatalogItem[]>([])
  const isLoading = ref(false)

  async function fetchItems(filters: CatalogFilters): Promise<void> {
    isLoading.value = true
    try {
      items.value = await catalogService.getItems(filters)
    } finally {
      isLoading.value = false
    }
  }

  return { items, isLoading, fetchItems }
})
```

## Replace these patterns

| Pattern | Required implementation |
|---|---|
| Options API store (`state()`, `actions: {}`) | Composition store (`setup` function) |
| Direct `$fetch` calls inside store actions | Composable/service layer |
| Storing raw API response shapes in state | Map to typed domain models first |
| Global UI state for single-component concerns | Component-local `ref` |
| Mutating store state outside actions | Actions only |

## Apply these practices

- keep stores typed end-to-end
- keep store files in `stores/` with `useXxxStore` naming
- reset store state on logout or session expiry where applicable

## Replace these patterns

- Keep page-scoped data in composables instead of creating a store.
- Route each resource's API request through one store or composable boundary.
- Keep tokens and PII out of Pinia state.
