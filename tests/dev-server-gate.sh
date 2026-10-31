#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 DEVKIT_GATE_ROOT="$ROOT" python3 - <<'PY'
import importlib.util
import io
import json
import os
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

root = Path(os.environ['DEVKIT_GATE_ROOT'])
spec = importlib.util.spec_from_file_location('dev_server_gate', root / 'plugins/core/hooks/dev-server-gate.py')
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class DevServerGateTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.config = Path(self.tmp.name) / 'projects.json'
        self.config.write_text(json.dumps({'version': 1, 'canonical_dev_servers': True, 'projects': []}))

    def decision(self, command, tool='Bash', platform='darwin', required_config=False):
        return gate.check_payload({'tool_name': tool, 'tool_input': {'command': command}}, self.config, platform, required_config=required_config)

    def installed_arguments(self, config_path=None, clone_path=root, previous_commands=()):
        env = dict(os.environ)
        env.pop('DEVKIT_PROJECTS_CONFIG', None)
        if config_path is not None:
            env['DEVKIT_PROJECTS_CONFIG'] = str(config_path)
        command = subprocess.check_output(['bash', '-c', 'source "$1/adapters/_lib/hooks.sh"; dev_server_gate_command "$2" "$3"', '_', str(root), str(clone_path), json.dumps(previous_commands)], env=env, text=True)
        return shlex.split(command)

    def test_direct_app_servers_are_blocked(self):
        for command in [
            'npm run dev', 'npm start', 'pnpm dev --port 3005', 'yarn dev',
            'npm run serve', 'bun preview',
            'bun run dev', 'bun --bun node_modules/next/dist/bin/next dev -p 3022',
            'node node_modules/nuxt/bin/nuxt.mjs dev --port 3138',
            'node ./node_modules/.bin/../vite/bin/vite.js --port 44040',
            'next start', 'nuxt dev', 'nuxi dev', 'vite', 'vite preview',
            'php artisan serve --port=8001', 'php -S 127.0.0.1:8001',
            'php artisan octane:start', 'php artisan reverb:start',
            'vite . --host', 'npx vite ./frontend --port 44040',
        ]:
            with self.subTest(command=command):
                self.assertIsNotNone(self.decision(command))

    def test_shell_wrappers_do_not_bypass(self):
        for command in [
            'PORT=3005 nohup pnpm dev > /tmp/dev.log 2>&1 &',
            'env NODE_ENV=development npm run dev',
            'bash -lc "cd /tmp/demo && npm run dev"',
            'fnm exec -- corepack pnpm dev',
            'npx --yes next@15 dev', 'npm exec -- vite --port 3001',
            'pnpm --dir /tmp/demo run dev',
            'npm --workspace app run dev', 'pnpm preview',
            'devkit-projects status; pnpm dev',
            'if true; then pnpm dev; fi',
            '(pnpm dev)', '(cd /repo && pnpm dev)',
            'pnpm \\\ndev',
        ]:
            with self.subTest(command=command):
                self.assertIsNotNone(self.decision(command))

    def test_manager_checks_builds_and_fixtures_are_allowed(self):
        for command in [
            'devkit-projects start pdd', '~/.claude/agentic-devkit/bin/devkit-projects start pdd',
            'cd /repo && devkit-projects status',
            'pnpm test', 'bun run build', 'npm run lint', 'npx next info',
            'vite build', 'vite optimize', 'nuxt prepare', 'php artisan test', 'git status',
            'next dev --help', 'echo "npm run dev"',
            "printf '%s\\n' ';' pnpm dev", "printf '%s\\n' \\; pnpm dev",
            'bun run dev:debug', 'pnpm dev:types', 'npm run dev:lint', 'yarn start:worker',
            "python3 -m http.server 18080 --bind 127.0.0.1",
            "cat <<'EOF'\npnpm dev\nEOF\n",
        ]:
            with self.subTest(command=command):
                self.assertIsNone(self.decision(command))

    def test_server_after_heredoc_is_not_hidden(self):
        self.assertIsNotNone(self.decision("cat <<'EOF'\nfixture\nEOF\npnpm dev\n"))

    def test_payload_variants(self):
        for payload in [
            {'tool_name': 'Bash', 'tool_input': {'command': 'npm run dev'}},
            {'tool_name': 'exec_command', 'tool_input': {'cmd': 'npm run dev'}},
            {'tool_name': 'functions.exec_command', 'tool_input': {'cmd': 'npm run dev'}},
            {'toolName': 'Shell', 'toolInput': {'command': 'npm run dev'}},
            {'command': 'npm run dev'},
        ]:
            with self.subTest(payload=payload):
                self.assertIsNotNone(gate.check_payload(payload, self.config, 'darwin'))
        self.assertIsNone(gate.check_payload({'tool_name': 'Write', 'tool_input': {'command': 'npm run dev'}}, self.config, 'darwin'))

    def test_opt_in_is_mac_only(self):
        self.assertIsNone(self.decision('npm run dev', platform='linux'))
        self.config.write_text(json.dumps({'canonical_dev_servers': False}))
        self.assertIsNone(self.decision('npm run dev'))
        self.config.write_text('{}')
        self.assertIsNone(self.decision('npm run dev'))

    def test_only_remembered_opt_in_fails_closed_on_broken_registry(self):
        for value in ['invalid json', '{"canonical_dev_servers": "true"}']:
            self.config.write_text(value)
            self.assertIsNotNone(self.decision('npm run dev', required_config=True))
            self.assertIsNone(self.decision('npm run dev'))
            self.assertIsNone(self.decision('git status', required_config=True))
        self.config.unlink()
        self.assertIsNotNone(self.decision('npm run dev', required_config=True))
        self.assertIsNone(self.decision('npm run dev'))

    def test_missing_default_registry_does_not_enable_policy(self):
        with patch.object(gate, 'DEFAULT_CONFIG', Path(self.tmp.name) / 'missing.json'), patch.dict(os.environ, {}, clear=True):
            self.assertIsNone(gate.check_payload({'command': 'npm run dev'}, platform='darwin'))

    def test_cli_denies_with_actionable_stderr_and_exit_two(self):
        stderr = io.StringIO()
        with patch('sys.argv', ['gate', '--config', str(self.config)]), patch('sys.platform', 'darwin'), patch('sys.stdin', io.StringIO('{"tool_name":"Bash","tool_input":{"command":"pnpm dev"}}')), patch('sys.stderr', stderr):
            self.assertEqual(gate.main(), 2)
        self.assertIn('devkit-projects', stderr.getvalue())
        self.assertNotIn('pnpm dev', stderr.getvalue())

    def test_cli_requires_broken_config_only_after_remembered_opt_in(self):
        self.config.unlink()
        for extra, expected in [([], 0), (['--require-config'], 2)]:
            with patch('sys.argv', ['gate', '--config', str(self.config), *extra]), patch('sys.platform', 'darwin'), patch('sys.stdin', io.StringIO('{"tool_name":"Bash","tool_input":{"command":"pnpm dev"}}')), patch('sys.stderr', io.StringIO()):
                self.assertEqual(gate.main(), expected)

    def test_installer_command_pins_shared_real_config(self):
        alias = Path(self.tmp.name) / 'registry alias.json'
        alias.symlink_to(self.config)
        self.assertEqual(self.installed_arguments(alias), ['sh', str(root / 'plugins/core/hooks/dev-server-gate.sh'), '--config', str(self.config.resolve()), '--require-config'])

    def test_installer_preserves_clone_alias_like_other_hooks(self):
        clone_alias = Path(self.tmp.name) / 'clone alias'
        clone_alias.symlink_to(root, target_is_directory=True)
        self.assertEqual(self.installed_arguments(self.config, clone_alias)[1], str(clone_alias / 'plugins/core/hooks/dev-server-gate.sh'))

    def test_installer_remembers_only_valid_explicit_opt_in(self):
        for initial in [{'canonical_dev_servers': True}, {'canonical_dev_servers': False}, {}, 'invalid']:
            self.config.write_text(json.dumps(initial) if isinstance(initial, dict) else initial)
            arguments = self.installed_arguments(self.config)
            required = isinstance(initial, dict) and initial.get('canonical_dev_servers') is True
            self.assertEqual('--require-config' in arguments, required)
            self.assertEqual(arguments[arguments.index('--config') + 1], str(self.config.resolve()))
            for value in [None, 'invalid']:
                if value is None:
                    self.config.unlink()
                else:
                    self.config.write_text(value)
                self.assertEqual(self.decision('pnpm dev', required_config=required) is not None, required)

    def test_opt_out_reinstall_clears_remembered_requirement(self):
        self.assertIn('--require-config', self.installed_arguments(self.config))
        self.config.write_text('{"canonical_dev_servers":false}')
        self.assertIsNone(self.decision('pnpm dev', required_config=True))
        arguments = self.installed_arguments(self.config)
        self.assertNotIn('--require-config', arguments)
        self.config.unlink()
        self.assertIsNone(self.decision('pnpm dev', required_config='--require-config' in arguments))

    def test_installer_default_present_and_absent_states(self):
        clone = Path(self.tmp.name) / 'kit'
        clone.mkdir()
        default = clone / 'projects.json'
        for value in [None, {}, {'canonical_dev_servers': False}, {'canonical_dev_servers': True}]:
            if value is not None:
                default.write_text(json.dumps(value))
            arguments = self.installed_arguments(clone_path=clone)
            self.assertEqual(arguments[arguments.index('--config') + 1], str(default.resolve()))
            self.assertEqual('--require-config' in arguments, value is not None and value.get('canonical_dev_servers') is True)

    def test_reinstall_retains_prior_opt_in_only_for_same_broken_registry(self):
        previous = shlex.join(self.installed_arguments(self.config))
        for value in [None, 'invalid', '{"canonical_dev_servers":"true"}']:
            if value is None:
                self.config.unlink()
            else:
                self.config.write_text(value)
            with self.subTest(value=value):
                self.assertIn('--require-config', self.installed_arguments(self.config, previous_commands=[previous]))
        for value in ['{"canonical_dev_servers":false}', '{}']:
            self.config.write_text(value)
            self.assertNotIn('--require-config', self.installed_arguments(self.config, previous_commands=[previous]))
        other = Path(self.tmp.name) / 'other.json'
        self.assertNotIn('--require-config', self.installed_arguments(other, previous_commands=[previous]))
        self.config.unlink()
        fake = shlex.join(['echo', previous])
        self.assertNotIn('--require-config', self.installed_arguments(self.config, previous_commands=[fake]))

unittest.main(verbosity=2)
PY
