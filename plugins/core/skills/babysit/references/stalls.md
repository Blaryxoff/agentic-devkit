# Stall patterns

Each row was observed in a real supervision run. Match the signal, confirm it in the transcript tail, then act.

| Signal | Confirm | Act |
|---|---|---|
| Idle, last message asks the owner a technical question | `tail.py` last assistant message | Decide it from the spec and the code. Send the decision, the reason, and the next numbered steps. Tell it to record the decision in its plan as one the owner may overrule |
| Idle, parked on an owner-only decision (spend, rollout, scope, dependency) | Same | Leave the decision parked. Send the work that does not depend on it, shaped so either answer fits later (config switch, flag defaulting off) |
| Idle, hands the owner a list of "decisions" | Read each one against the spec | Items the spec already answers are conformance bugs: send them back as work. Keep only true owner items in the report |
| Idle after the peer answered (peer pane shows a finished review or `REVIEW PASSED`; Claude never acted) | Peer pane text, Claude transcript idle | Quote the verdict and tell it to take the plan's next step. Commit or push only when its task already authorises that |
| Both panes idle, a half message sits in a composer (peer-chat send broke mid-body) | Read both composers | If the half message is in Codex's composer: one `Ctrl-C` there (`agtermctl session type $'\x03' --target <id> --pane right`), never a second, never Enter. Then tell Claude to resend through `peer-chat.py --message-file` with a short pointer message. If it is in Claude's composer, `send.sh` refuses: report it instead |
| Waiting on a background CI watch, deploy monitor or subagent that has not reported for longer than one poll | `gh run list --branch <b> --limit 3` or the job's own status | If the job already finished, tell the session its result and to drop the watch and continue. If it is truly hung, tell the session to check or restart it |
| Turn ended on an API or connection error | Last transcript entry is the error, pane idle | Tell it to continue from where it stopped, reading `git status` and the diff first so a half-written edit is not lost |
| Chooser (AskUserQuestion) open | Pane shows numbered options with `❯` on one | Inside delegation and the highlighted option is the right one: re-read the pane immediately before, confirm the same question with the same option highlighted and no permission, trust or approval wording, then send a bare `$'\r'` to the left pane. Otherwise leave it and report. Never answer a permission, trust or approval prompt |
| Finished, nothing buildable left | Final report in the transcript | Do not invent work. Report it as finished, with its open owner questions |
| Usage limit message in the pane | `poll.sh` tail | Nothing until the reset. The waker wakes it; if no waker is armed, send `continue` after the reset |
| A peer session reports a problem it did not cause (red build, broken commit) | `git log -1 <sha>`, then grep supervised transcripts for the short SHA | Forward it with a decision to the session that made the commit. Tell the reporter where it was routed |
| Every session froze at once, agterm socket refuses | Retry `agtermctl window list` a few times; `pmset -g log \| grep -E ' (Sleep\|Wake) ' \| tail -4` | Transient socket refusal: retry. The Mac slept: start `caffeinate -ims -t <seconds>` and say that lid-closed sleep cannot be blocked |
| Transcript idle but pane shows activity | Compare pane to transcript tail | The session may have rotated to a new transcript. Re-run `roster.py`, or match the newest transcript in its project dir by content. Never pick the supervisor's own transcript |

A wait shorter than one poll interval is normal: note it, act next tick if nothing moved.
