# Documentation

Documentation must explain intent, contracts, and usage for frontend code.

## What to document

- module purpose for non-trivial pages/components/composables
- input/output contracts for reusable composables and utilities
- side effects (network, storage, analytics, navigation)
- important constraints and trade-offs

## Style guidelines

- keep docs close to code where practical.
- explain **why** a decision exists, not only **what** code does.
- keep comments short, specific, and maintained with code changes.

## Type-first documentation

- prefer expressive TypeScript types as primary documentation.
- add JSDoc only when types are insufficient to explain behavior.

## Examples

- include compact usage examples for shared composables/utilities.
- use markdown docs for larger patterns and architecture decisions.

## DO / DO NOT

DO:
- document contracts for exported APIs
- update docs when behavior changes

DO NOT:
- leave stale comments after refactors
- write obvious comments that duplicate code line-by-line
