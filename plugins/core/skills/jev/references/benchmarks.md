# Jev benchmarks

Evidence behind the skill's scope. Read before proposing a new Jev use; rerun a comparable benchmark (50+ real cases,
labels frozen before any Jev call, current behaviour as the baseline) before changing the skill.

## Adopted

| Use | Sample | Result |
|---|---|---|
| `locate` in a large file | 128 functions in 128 files, 5 repos (PHP, Vue/TS, Python, JS) | answer block top-1 86%, top-3 98%, top-5 100%; keyword grep top-3 48%; reads ~105 of ~800 lines; median 0.78 s |
| `locate` (independent set) | 60 tasks, 4 languages | gold inside the first 100 returned lines 56/60 (84-97%); jegrep 25/60; Luna subagent 41/60 at 12.5 s and 34k tokens |
| `filter` as an ordering aid | 51 real grep outputs, ~400 lines, precise task | answer in top-1 31%, top-5 61%, top-10 71%, default kept 69%; median 2.7 s |

## Rejected

| Use | Sample | Result |
|---|---|---|
| Subagent model tier | 39 labelled delegated tasks | Jev 69% vs fixed rule 62%; agent's own pick 84% (21/25); 8 under-tiered |
| Skill routing | 40 real prompts | 53% vs 50% for always "no skill" |
| Conduct doc selection | 12 Laravel tasks | recall 92% at 51% precision (0.5) or 72% at 100% (0.7); routing table is exact |
| Browser QA page vs reference | 200 mutated real snapshots | accuracy 0.93, tied with uid-stripped `diff`; flags timestamp changes as mismatches |
| Automatic output filtering (hook, description as task) | 183 real outputs of 100-500 lines | 61% needed whole; of the rest, all needed lines kept 14-34%; whole-output guard cannot separate |
| Policy text asking agents to pipe output through Jev | 20 fresh Codex Luna runs, 2 wordings | 0/20 used Jev before reading raw output |
| Root-cause log triage with a known literal error | 40 cases from 12 real Laravel logs, 16 signatures | `rg -F -m1` + read 15 lines: 40/40, 16 lines, 8 ms; `locate` 38/40, 240 lines, 2.6 s; `rg -F -C5` piped into `filter` 13/40 |
| jegrep for known-file location | 60 tasks | 25/60 within 100 read lines; median first span 216 lines |
| Transcript compaction pruning | external evidence | keep/drop agreement 56.3%; plugin author advises against |

Raw data from these runs lived in session scratchpads and `/tmp/jev-bench-codex/` (round reports `REPORT.md`,
`ROUND2.md`, `ROUND3.md`, `ROUND4.md`); they are not preserved in the repository.
