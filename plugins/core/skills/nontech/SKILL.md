---
name: devkit-nontech
description: >-
  format incidents, status, decisions, results, or explanations for managers and other non-technical readers. Use on "для менеджера", "для нетехнических сотрудников", "объясни простыми словами", "без технических деталей", or "stakeholder update". Preserve impact, status, cause, action, and next steps; omit codebase internals.
  Always writes the final answer in Russian. A bare invocation rewrites the immediately preceding assistant response.
---

# Nontech

Turn verified technical facts into a concise, audience-ready explanation for a non-technical reader. Preserve what the reader needs to understand, trust, and act on the result while translating implementation details and combining supporting facts.

## Hard boundary: no codebase internals

The final answer must not contain:

- local or repository file paths;
- file names or directory names;
- class names, function names, method names, variable names, or internal constants;
- database table names, column names, schema names, query text, migration names, or indexes;
- route names, endpoint paths, internal API fields, event names, queue names, or job names;
- package, module, container, service, host, branch, or commit identifiers when they are implementation-only;
- commands, code snippets, SQL, configuration fragments, stack traces, exception names, or raw error messages;
- line numbers, raw log excerpts, test names, or links into the codebase.

Do not merely shorten or pseudonymize a technical identifier. Replace it with the concept the reader needs: "customer data", "payment processing", "background processing", "the external integration", "access settings", or another plain business-level term.

You may inspect technical evidence to establish the facts. Keep raw artifacts private and translate the facts they establish before answering.

This boundary applies to implementation vocabulary, not to factual detail. Translate technical fields into their business meaning. Keep an operational identifier only when it helps the reader locate the affected item or act on the message.

## Content contract

Preserve the relevant subset of:

1. **What happened** — the visible problem or result in plain language.
2. **Impact** — who or what was affected, and how severely.
3. **Current status** — broken, partially restored, restored, monitoring, or still under investigation.
4. **Cause** — the causal mechanism at a level a non-technical reader can understand.
5. **What was done** — the corrective action expressed as an outcome, not an implementation diff.
6. **Next step** — monitoring, follow-up work, prevention, decision needed, or no further action.
7. **Timing** — only when a real deadline, duration, or ETA is known.
8. **Confidence** — one or two understandable observations or ruled-out exceptions when they materially support the conclusion.

Do not invent impact, scope, cause, dates, percentages, or ETA. Say "the exact scope is still being checked" when it is genuinely unknown. Do not turn uncertainty into reassurance.

Make the rewrite modestly shorter than a detailed technical source. Group related facts, remove repetition, and omit secondary proof that does not change the content contract. Do not compress the result to generic statements that leave the cause unsupported or hide a material exception.

## Translation rules

- Write the entire final answer in Russian, regardless of the user's language, requested output language, or the current conversation language. Translate every label and explanatory phrase into Russian; keep only proper names, product names, and other terms that must remain exact in their original form.
- Translate mechanisms, not nouns. "Two operations changed the same information at once" is useful; the names of the processes are not.
- Explain consequences before causes. The audience usually needs impact and status before the internal reason.
- Use familiar words. Prefer "data was incomplete" over storage terminology and "the external service responded too slowly" over protocol details.
- Keep necessary business terms, product names, customer-visible feature names, money, dates, and measured impact exact.
- Summarize technical evidence as observable behaviour; never include its raw representation.
- Avoid blame. Describe the failed process or missing safeguard unless personal responsibility is a verified and relevant fact.
- Avoid euphemisms. A serious outage remains a serious outage after simplification.

## Workflow

### 1. Select the source

Use source text or task parameters supplied with the invocation. When neither is supplied, including a bare `/nontech` or `$devkit-nontech`, rewrite the immediately preceding assistant response. Do not ask the user to paste it again. If no preceding assistant response exists, ask for the source instead of inventing one.

### 2. Establish the audience and purpose

Default to a manager or non-technical employee when the user does not specify a narrower audience. Infer whether the deliverable is an incident explanation, status update, completed-work summary, decision brief, or direct answer. Ask only when the audience or purpose materially changes the message.

### 3. Extract verified facts

Extract confirmed facts, assumptions, and unknowns. Select facts using the content contract.

### 4. Rewrite at business level

Replace codebase structure with user-visible behaviour, operational consequences, or business concepts. Group related facts and remove repetition.

### 5. Run the disclosure scrub

Before answering, check every sentence for file paths, file names, table names, column names, class names, function names, stack traces, raw errors, commands, code identifiers, and repository references. Rewrite or remove every hit.

Then compare the result with the content contract and restore any material fact lost during simplification.

### 6. Deliver the message

Output only the audience-ready text. Do not preface it with "simplified version", explain the transformation, include a technical appendix, or mention what details were removed.

## Response shapes

### Incident or failure

For a multi-fact update, prefer three to six short paragraphs or bullets. Use labels when they improve navigation, but do not force every fact into a separate status field:

```text
Что произошло: [видимая проблема]
Влияние: [кого или какой процесс затронуло и насколько сильно]
Текущий статус: [текущее состояние]
Причина: [причина простыми словами]
Что сделано: [результат исправления]
Следующий шаг: [дальнейшие действия или наблюдение]
```

Omit a label only when it adds no information. Preserve explicit unknowns that matter.

### Completed work

```text
[What is now possible or fixed.]
[Who benefits and what changed for them.]
[Any remaining limitation or required next action.]
```

### Decision or recommendation

Lead with the recommendation. Follow with the business reason, material trade-off, impact, and the decision or action required from the reader.

### Simple question

Answer in one or two plain paragraphs. Do not force a status template onto a small answer.

## Quality check

The final text passes when it satisfies the content contract without requiring knowledge of the repository, source code, database structure, deployment layout, or developer tooling.
