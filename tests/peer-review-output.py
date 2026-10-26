#!/usr/bin/env python3
"""Exercise the documented launch through installed Claude/Codex skill links."""

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


def check(skill_dir, devkit_home):
    skill = (skill_dir / "SKILL.md").read_text()
    assert "Read `references/codex-review.md` and follow it exactly." in skill
    assert "not the project root." in skill
    contract = (skill_dir / "references/codex-review.md").read_text()
    assert "plugins/core/conduct/cross-agent-review.md" in contract
    conduct = (devkit_home / "plugins/core/conduct/cross-agent-review.md").read_text()
    assert "never on stderr or a merged transcript" in conduct
    assert "Keep stderr for failure diagnosis." in conduct
    for gate in (
        "distinct, fresh scratchpad paths for this pass",
        "Read `review_answer` only after completion",
        "missing/empty answer file",
        "a non-zero exit",
        "A timeout or interruption invalidates",
        "stop the pipeline; do not advance to QA or wrapup",
        "Scan the complete final answer for `CRITICAL`, `MAJOR`, and `MINOR`",
        "`NO ISSUES FOUND` counts as clean only when no severity tag appears",
    ):
        assert gate in contract, gate
    commands = re.findall(r"```bash\n(.*?)\n```", contract, re.S)
    assert len(commands) == 1, "exercise the actual documented launch, not a copied command"
    command = commands[0]
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        launcher = root / "codex"
        launcher.write_text(
            f"#!{sys.executable}\n"
            "import os, pathlib, sys\n"
            "args = sys.argv[1:]\n"
            "assert args[:5] == ['exec', '--sandbox', 'read-only', '--skip-git-repo-check', '-o']\n"
            "assert len(args) == 7\n"
            "assert args[-1] == pathlib.Path(os.environ['prompt_file']).read_text().rstrip('\\n')\n"
            "assert sys.stdin.read() == ''\n"
            "assert os.environ['DEVKIT_FEEDBACK_WORKER'] == '1'\n"
            "print('CRITICAL MAJOR MINOR: echoed prompt, not findings', file=sys.stderr)\n"
            "print('CRITICAL: reasoning transcript, not the final answer')\n"
            "mode = os.environ['MODE']\n"
            "answers = {'clean': 'NO ISSUES FOUND', 'mixed': 'NO ISSUES FOUND\\nMAJOR: a.py:1 - defect\\n  continuation', 'minor': 'MINOR: a.py:1 - defect', 'empty': '', 'failed': 'NO ISSUES FOUND'}\n"
            "if mode != 'missing':\n"
            "    pathlib.Path(args[5]).write_text(answers[mode])\n"
            "sys.exit(9 if mode == 'failed' else 0)\n"
        )
        launcher.chmod(0o755)
        prompt = root / "prompt.txt"
        prompt.write_text('Review `literal` and $UNEXPANDED; "quotes" stay intact.\n')
        for mode in ("clean", "mixed", "minor", "empty", "missing", "failed"):
            run = root / mode
            run.mkdir()
            answer, stdout, stderr = (run / name for name in ("answer", "stdout", "stderr"))
            env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}", MODE=mode,
                       prompt_file=str(prompt), review_answer=str(answer),
                       review_stdout=str(stdout), review_stderr=str(stderr))
            proc = subprocess.run(["bash", "-c", command], cwd=run, env=env,
                                  capture_output=True, text=True, timeout=10)
            assert proc.returncode == (9 if mode == "failed" else 0), (
                mode, proc.returncode, proc.stderr, stderr.read_text() if stderr.exists() else "no diagnostics"
            )
            assert not proc.stdout and not proc.stderr, "launch leaked merged output"
            assert "echoed prompt" in stderr.read_text()
            assert "reasoning transcript" in stdout.read_text()
            if mode == "missing":
                assert not answer.exists(), "missing final answer must not fall back to transcript"
            else:
                text = answer.read_text()
                assert "echoed prompt" not in text and "reasoning transcript" not in text
                if mode == "clean":
                    assert text == "NO ISSUES FOUND"
                elif mode == "mixed":
                    assert "MAJOR:" in text and "NO ISSUES FOUND" in text and "continuation" in text
                    assert len(text.splitlines()) == 3, "wrapped findings must retain their line boundaries"
                elif mode == "minor":
                    assert text.startswith("MINOR:")
                elif mode == "empty":
                    assert not text, "stderr chatter must not fill an empty final answer"
    print(f"peer review output: {skill_dir} — 6 launch cases + contract gates passed")


if __name__ == "__main__":
    check(Path(sys.argv[1]), Path(sys.argv[2]))
