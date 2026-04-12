# Spec Extension: Inertia UI Layer

> Include this block when the feature changes Inertia pages, Vue components, or Tailwind styles.

## UI-1. Page / Component Inventory

```
Pages:
- resources/js/Pages/[Module]/[Page].vue

Components:
- resources/js/Components/[Component].vue

Layouts:
- resources/js/Layouts/[Layout].vue
```

- Which pages/components are new vs modified?
- Which shared components should be reused (do NOT duplicate UI patterns)?

## UI-2. Navigation & Routing Behavior

- Entry points: where users can access the page/action
- Inertia navigation behavior (`<Link>`, `router.visit`, redirects)
- URL/state rules: query params, filters, pagination, tabs
- Back/forward behavior and deep-link expectations

## UI-3. Data Contract (Server → Inertia Props)

For each Inertia page:

```
### Page: [Module/Page]

Route: GET /resources
Controller: ResourceController@index

Props:
- resources: paginated collection
- filters: object
- can: permission booleans

Deferred props: yes / no
```

- Define required prop shapes
- Define empty/loading/error states (including skeletons where applicable)

## UI-4. UX States & Validation

- Loading states (initial load, form submit, button disabled states)
- Empty states (no data found, no permissions, filtered-empty)
- Error states (validation errors, general failure, retry CTA)
- Form behavior (`<Form>` component or `useForm` helper, reset rules)

## UI-5. Styling & Accessibility (Tailwind)

- Tailwind conventions and reusable utility patterns
- Dark mode parity (if existing area supports dark mode)
- Accessibility requirements: labels, focus, keyboard nav, contrast, ARIA where needed
