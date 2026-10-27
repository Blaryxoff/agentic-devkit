#!/usr/bin/env python3
"""Isolated review/QA pairs and evidence-backed, externally adjudicated scoring."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile
import time
import tomllib

HERE = Path(__file__).resolve().parent
FROZEN = {'cases.json': '708881dea8600942bf835102e8ad1649380460a787cd76ce2419d1cd65812b21',
          'rubric.json': '6d9572eda5693fec54ea5c6d0ffe23393fea0d99b41c717fc92c3492296654ac',
          'applicability.json': '6f3bb0da44383b75e4e7939bb5acb4506ace0d2d8397b107133ef81abdf29782'}
AXES = ('static_review', 'case_generation', 'evidence_adjudication', 'runtime_probe')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read(path):
    return json.loads(Path(path).read_text())


def write(path, data):
    Path(path).write_text(json.dumps(data, indent=2) + '\n')


def write_run(directory, result):
    directory = Path(directory)
    metadata = read(directory / 'export.json')
    if any(result.get(key) != value for key, value in metadata.items()):
        raise ValueError('Run identity differs from export')
    result = result | {'export_sha256': digest((directory / 'export.json').read_bytes())}
    write(directory / 'run.json', result)
    return result


def corpus():
    for name, expected in FROZEN.items():
        if digest((HERE / name).read_bytes()) != expected:
            raise ValueError(f'Frozen corpus mismatch: {name}')
    data, rubric = read(HERE / 'cases.json'), read(HERE / 'rubric.json')
    policy = read(HERE / 'applicability.json')
    if policy['parent_corpus'] != {key: FROZEN[key] for key in ('cases.json', 'rubric.json')}:
        raise ValueError('Applicability parent corpus mismatch')
    mapping = policy['required_by_axis']
    if set(mapping) != {case['id'] for case in rubric['cases']}:
        raise ValueError('Applicability case coverage mismatch')
    for case in rubric['cases']:
        axes = mapping[case['id']]
        required = {str(i + 1) for i in range(len(case['required']))}
        if set(axes) != set(case['workflows']) or any(not items or len(items) != len(set(items)) or not set(items) <= required for items in axes.values()):
            raise ValueError(f'Invalid criterion applicability: {case["id"]}')
        if set().union(*(set(items) for items in axes.values())) != required:
            raise ValueError(f'Unmapped rubric criterion: {case["id"]}')
    rubric['required_by_axis'] = mapping
    return data, rubric


def inventory(rubric):
    return sorted(set(rubric['baseline_files']) | set(rubric['candidate_conditional_files']))


def prepare(source, output, arm):
    _, rubric = corpus()
    source, output = Path(source).resolve(), Path(output).resolve()
    if output.exists():
        raise ValueError('Snapshot destination must be fresh')
    if arm == 'baseline':
        expected = rubric['baseline']
    else:
        expected = None
    try:
        revision = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True, stderr=subprocess.DEVNULL).strip()
    except subprocess.CalledProcessError:
        revision = 'archive; validated by source digests'
    entries = {}
    for relative in inventory(rubric):
        path = source / relative
        if not path.exists():
            if relative in rubric['baseline_files']:
                raise ValueError(f'Missing source: {relative}')
            entries[relative] = {'absent': True}
            continue
        data = path.read_bytes()
        if expected and relative in rubric['baseline_files']:
            if digest(data) != rubric['baseline_files'][relative]['sha256']:
                raise ValueError(f'Baseline source mismatch: {relative}')
        if expected and relative in rubric['candidate_conditional_files']:
            raise ValueError(f'Candidate-only source in baseline: {relative}')
        entries[relative] = {'sha256': digest(data), 'bytes': len(data)}
    output.mkdir(parents=True)
    for relative, entry in entries.items():
        if not entry.get('absent'):
            target = output / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes((source / relative).read_bytes())
    manifest = {'arm': arm, 'baseline_revision': expected, 'source_revision': revision,
                'source_root': str(source), 'files': entries, 'corpus': FROZEN,
                'snapshot_sha256': digest(json.dumps(entries, sort_keys=True).encode())}
    write(output / 'snapshot.json', manifest)
    return manifest


def validate_snapshot(root):
    root = Path(root)
    info = read(root / 'snapshot.json')
    if info['corpus'] != FROZEN:
        raise ValueError('Snapshot corpus differs')
    if digest(json.dumps(info['files'], sort_keys=True).encode()) != info['snapshot_sha256']:
        raise ValueError('Snapshot manifest mismatch')
    for relative, entry in info['files'].items():
        path = root / relative
        if entry.get('absent'):
            if path.exists():
                raise ValueError(f'Snapshot absent file appeared: {relative}')
        elif not path.exists() or digest(path.read_bytes()) != entry['sha256']:
            raise ValueError(f'Snapshot content changed: {relative}')
    return info


def selected_files(axis, ids, snapshot):
    ids = set(ids)
    core = 'plugins/core/'
    files = []
    if axis == 'static_review':
        frontend = ids <= {'C003', 'C016', 'C039'}
        files += [f'plugins/{"frontend" if frontend else "laravel"}/skills/reviewer-business-logic/SKILL.md']
        if ids != {'C039'}:
            files += [core + 'conduct/behavioral-completeness.md', core + 'conduct/inputs-grounding-gate.md']
    elif axis == 'case_generation':
        files += [core + 'skills/test-case-creator/SKILL.md', core + 'conduct/behavioral-completeness.md',
                  core + 'conduct/risk-probe-gate.md', core + 'conduct/test-implementation.md']
    else:
        api = ids <= {'C013', 'C014', 'C018', 'C019', 'C022', 'C027', 'C029', 'C030', 'C031', 'C032', 'C033'}
        files += [core + f'skills/{"verify" if api else "browser"}/SKILL.md']
        if not api and ids != {'C040'}:
            files += [core + 'conduct/browser-qa-rules.md']
        if ids != {'C040'}:
            files += [core + 'conduct/runtime-qa-evidence.md']
        if ids & {'C023', 'C024', 'C036', 'C037', 'C038'}:
            files += [core + 'conduct/inputs-grounding-gate.md']
        if ids & {'C025', 'C026', 'C027'}:
            files += [core + 'skills/task/references/qa-brief-template.md']
        if ids & {'C025'}:
            files += [core + 'conduct/behavioral-completeness.md']
        if ids & {'C017', 'C018', 'C019', 'C030', 'C031', 'C032', 'C033'}:
            files += [core + 'conduct/qa-output-verification.md']
        if ids & {'C020', 'C021', 'C022'}:
            files += [core + 'conduct/qa-touch-and-device.md', core + 'conduct/browser-layout-audit.md']
    return [p for p in dict.fromkeys(files) if not snapshot['files'][p].get('absent')]


def export(snapshot_root, axis, ids, variant, destination):
    if axis == 'runtime_probe':
        raise ValueError('Recorded fixtures cannot become runtime probes; use a separately executed fixture lane')
    if not ids or len(ids) > 8 or len(ids) != len(set(ids)):
        raise ValueError('Export one to eight distinct compatible case IDs')
    if set(ids) & {'C039', 'C040'} and len(ids) != 1:
        raise ValueError('Run scope controls independently')
    data, rubric = corpus()
    snapshot = validate_snapshot(snapshot_root)
    by_id = {case['id']: case for case in data['cases']}
    rules = {case['id']: case for case in rubric['cases']}
    profiles = {selected_files(axis, [key], snapshot)[0] for key in ids}
    if len(profiles) != 1:
        raise ValueError('Incompatible batch: use one entry skill/surface profile per request')
    payload = []
    for key in ids:
        if axis not in rules[key]['workflows']:
            raise ValueError(f'{key} does not declare {axis}')
        case = by_id[key]
        payload.append({k: case[k] for k in ('id', 'brief', 'contract')} | {'evidence': case['variants'][variant]})
    paths = selected_files(axis, ids, snapshot)
    instruction_parts = [f'--- {p} ---\n' + (Path(snapshot_root) / p).read_text() for p in paths]
    task = {'static_review': 'Review the supplied source/data against its contract and report only grounded findings.',
            'case_generation': 'Design concrete minimal cases with setup, actions, expected observations and source.',
            'evidence_adjudication': 'Adjudicate acceptance from these records, with precise method, provenance and limits.'}[axis]
    prompt = ('You are evaluating synthetic independent feature briefs. ' + task + '\n'
              'Use only the assigned instruction text and supplied inputs below. Do not inspect host files, installed skills, '
              'other cases, answer keys, or network sources. Do not invoke tools or other agents for these recorded-input lanes. '
              'Some instruction references are unavailable in this bounded package; report a material missing rule rather than '
              'reading outside it. Supplied traces are inherited records, never your own fresh execution. '
              'Return an independent, concise assessment for every case ID, including its evidence and limitations.\n\n'
              + '\n\n'.join(instruction_parts) + '\n\nINPUTS\n' + json.dumps(payload, indent=2))
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=False)
    (destination / 'prompt.txt').write_text(prompt)
    write(destination / 'inputs.json', payload)
    metadata = {'axis': axis, 'ids': ids, 'variant': variant, 'arm': snapshot['arm'],
                'snapshot_sha256': snapshot['snapshot_sha256'], 'prompt_sha256': digest(prompt.encode()),
                'input_sha256': digest(json.dumps(payload, sort_keys=True).encode()),
                'loaded_files': {p: snapshot['files'][p] for p in paths},
                'loaded_instruction_bytes': sum(snapshot['files'][p]['bytes'] for p in paths),
                'instruction_loading': 'Exact source bytes embedded in prompt; no external reference reads authorized',
                'corpus': FROZEN}
    write(destination / 'export.json', metadata)
    return metadata


def effective_effort(requested):
    if requested:
        return requested
    config = Path.home() / '.codex/config.toml'
    value = tomllib.loads(config.read_text()).get('model_reasoning_effort') if config.exists() else None
    if not value:
        raise ValueError('Cannot pin configured effort; supply --effort')
    return value


def exported_metadata(directory):
    directory = Path(directory)
    metadata = read(directory / 'export.json')
    data, rubric = corpus()
    cases = {case['id']: case for case in data['cases']}
    rules = {case['id']: case for case in rubric['cases']}
    ids, axis, variant = metadata['ids'], metadata['axis'], metadata['variant']
    if metadata.get('corpus') != FROZEN or not ids or len(ids) != len(set(ids)) or variant not in ('a', 'b'):
        raise ValueError('Invalid export identity or corpus')
    if any(key not in rules or axis not in rules[key]['workflows'] for key in ids):
        raise ValueError('Export case does not declare its axis')
    if (directory / 'run.json').exists():
        result = read(directory / 'run.json')
        if result.get('export_sha256') != digest((directory / 'export.json').read_bytes()):
            raise ValueError('Run export binding missing or changed; rerun this attempt')
        if any(result.get(key) != value for key, value in metadata.items()):
            raise ValueError('Run identity differs from export')
    if axis != 'runtime_probe':
        payload = [{key: cases[case_id][key] for key in ('id', 'brief', 'contract')} |
                   {'evidence': cases[case_id]['variants'][variant]} for case_id in ids]
        if read(directory / 'inputs.json') != payload or metadata.get('input_sha256') != digest(json.dumps(payload, sort_keys=True).encode()):
            raise ValueError('Export identity differs from frozen inputs')
        prompt = (directory / 'prompt.txt').read_text()
        if digest(prompt.encode()) != metadata.get('prompt_sha256'):
            raise ValueError('Export prompt changed')
        parts = prompt.rsplit('\n\nINPUTS\n', 1)
        if len(parts) != 2 or json.loads(parts[1]) != payload:
            raise ValueError('Prompt inputs differ from export identity')
    return metadata


def launch(directory, model, effort, timeout):
    directory = Path(directory).resolve()
    metadata = exported_metadata(directory)
    prompt = (directory / 'prompt.txt').read_text()
    if digest(prompt.encode()) != metadata['prompt_sha256']:
        raise ValueError('Export prompt changed')
    workspace = tempfile.TemporaryDirectory(prefix='review-qa-')
    work = Path(workspace.name)
    command = ['codex', 'exec', '--ignore-user-config', '--ignore-rules', '--ephemeral',
               '--skip-git-repo-check', '--json', '--sandbox', 'read-only',
               '--enable', 'skip_host_skill_discovery', '--disable', 'plugins', '--disable', 'hooks',
               '-c', 'project_doc_max_bytes=0', '-c', f'model_reasoning_effort="{effort}"',
               '-m', model, '-C', str(work), '--output-last-message', str(directory / 'answer.txt'), '-']
    started = time.time()
    status, code = 'unexecuted', None
    try:
        with (directory / 'events.jsonl').open('w') as stdout, (directory / 'stderr.txt').open('w') as stderr:
            proc = subprocess.run(command, input=prompt, text=True, stdout=stdout, stderr=stderr, timeout=timeout)
            code = proc.returncode
        answer = directory / 'answer.txt'
        status = 'completed' if code == 0 and answer.exists() and answer.read_text().strip() else 'unusable'
    except subprocess.TimeoutExpired:
        status = 'unusable'
    finally:
        workspace.cleanup()
    events = []
    if (directory / 'events.jsonl').exists():
        for line in (directory / 'events.jsonl').read_text().splitlines():
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                status = 'unusable'
    usages = [e.get('usage') for e in events if e.get('usage')]
    tool_events = [e for e in events if e.get('item', {}).get('type') in ('command_execution', 'mcp_tool_call', 'web_search', 'collab_tool_call')]
    if tool_events or not any(e.get('type') == 'turn.completed' for e in events):
        status = 'unusable'
    result = metadata | {'status': status, 'exit_code': code, 'started_at_unix': started,
                         'elapsed_seconds': time.time() - started, 'model': model, 'effort': effort,
                         'harness_version': subprocess.check_output(['codex', '--version'], text=True).strip(),
                         'command': command, 'execution_settings': {'sandbox': 'read-only', 'tools': 'forbidden',
                         'ignore_user_config': True, 'ignore_rules': True, 'ephemeral': True,
                         'skip_host_skill_discovery': True, 'plugins': False, 'hooks': False,
                         'project_doc_max_bytes': 0, 'timeout_seconds': timeout}, 'usage': usages, 'tool_calls': len(tool_events), 'dispatch_count': 0,
                         'isolation_note': 'Host config/rules/skills/plugins/hooks disabled; tool use invalidates recorded-input run.',
                         'answer_sha256': digest((directory / 'answer.txt').read_bytes()) if (directory / 'answer.txt').exists() else None,
                         'events_sha256': digest((directory / 'events.jsonl').read_bytes())}
    return write_run(directory, result)


def units():
    _, rubric = corpus()
    return [(c['id'], v, axis) for c in rubric['cases'] for v in ('a', 'b') for axis in c['workflows']]


def grade_template(run_dir):
    metadata = exported_metadata(run_dir)
    _, rubric = corpus()
    rows = []
    for case in rubric['cases']:
        if case['id'] not in metadata['ids']:
            continue
        clean = metadata['variant'] == case['clean_variant']
        criteria = [('1', case['clean_guard'])] if clean else [
            (str(i + 1), criterion) for i, criterion in enumerate(case['required'])
            if str(i + 1) in rubric['required_by_axis'][case['id']][metadata['axis']]]
        items = [{'item': key, 'criterion': criterion, 'status': 'unexecuted',
                  'applicable': True, 'reason': '', 'evidence': []} for key, criterion in criteria]
        if metadata['axis'] == 'case_generation':
            items.append({'item': 'axis-case-generation', 'criterion': rubric['score_axes']['case_generation'],
                          'status': 'unexecuted', 'applicable': True, 'reason': '', 'evidence': []})
        rows.append({'id': case['id'], 'axis': metadata['axis'], 'variant': metadata['variant'],
                     'items': items,
                     'confirmed_false_defects': [], 'false_runtime_promotion': False})
    return {'evaluator': '', 'independent_of_tested_agent': False, 'run_directory': str(Path(run_dir).resolve()),
            'answer_sha256': None, 'rows': rows}


def score_run(run_dir, grade):
    run_dir = Path(run_dir)
    planned = grade_template(run_dir)
    result = read(run_dir / 'run.json') if (run_dir / 'run.json').exists() else {'status': 'unexecuted'}
    usable = result['status'] == 'completed' and (run_dir / 'answer.txt').exists()
    if usable:
        actual = digest((run_dir / 'answer.txt').read_bytes())
        usable = (actual == result['answer_sha256'] == grade.get('answer_sha256')
                  and grade.get('independent_of_tested_agent') is True and bool(grade.get('evaluator')))
        for artifact, key in [('events.jsonl', 'events_sha256'), ('prompt.txt', 'prompt_sha256')]:
            usable = usable and (run_dir / artifact).exists() and digest((run_dir / artifact).read_bytes()) == result[key]
    if usable and result.get('axis') == 'runtime_probe':
        usable = result.get('runtime_kind') == 'agent_runtime_detection'
        source = run_dir / 'runtime-source.json'
        usable = usable and source.exists() and digest(source.read_bytes()) == result.get('runtime_source_sha256')
        for artifact in result.get('runtime_artifacts', []):
            path = run_dir / artifact['path']
            usable = usable and path.exists() and digest(path.read_bytes()) == artifact['sha256']
    scored = []
    for expected in planned['rows']:
        candidates = [r for r in grade.get('rows', []) if (r['id'], r['axis'], r['variant']) == (expected['id'], expected['axis'], expected['variant'])]
        row = candidates[0] if len(candidates) == 1 else {}
        checks = []
        for requirement in expected['items']:
            items = [i for i in row.get('items', []) if i['item'] == requirement['item']]
            item = items[0] if len(items) == 1 else {}
            status = item.get('status', 'unexecuted') if usable else 'unexecuted'
            if status not in ('passed', 'failed', 'blocked', 'unexecuted'):
                status = 'unexecuted'
            if item.get('applicable') is not True:
                status = 'unexecuted'
            if status in ('passed', 'failed') and not (item.get('reason') and item.get('evidence')):
                status = 'unexecuted'
            checks.append({'item': requirement['item'], 'status': status})
        status = 'passed' if checks and all(c['status'] == 'passed' for c in checks) else 'incomplete'
        if row.get('confirmed_false_defects') or row.get('false_runtime_promotion') or any(c['status'] == 'failed' for c in checks):
            status = 'failed' if usable else 'unexecuted'
        scored.append({k: expected[k] for k in ('id', 'axis', 'variant')} | {'status': status, 'items': checks,
                       'confirmed_false_defects': row.get('confirmed_false_defects', []),
                       'false_runtime_promotion': row.get('false_runtime_promotion', False)})
    return {'arm': result.get('arm'), 'trial': result.get('trial'), 'usable': usable, 'rows': scored,
            'elapsed_seconds': result.get('elapsed_seconds'), 'loaded_instruction_bytes': result.get('loaded_instruction_bytes'),
            'run_directory': str(run_dir.resolve()), 'run_metadata': result}


def validate_audit(path, scores):
    path = Path(path)
    if not path.exists():
        return {'passed': False, 'reason': 'Independent scope/cost audit missing'}
    audit = read(path)
    if not audit.get('evaluator') or audit.get('independent_of_tested_agent') is not True or audit.get('corpus') != FROZEN:
        return {'passed': False, 'reason': 'Audit identity or corpus missing/mismatched'}
    expected_runs = sorted(digest((Path(s['run_directory']) / 'run.json').read_bytes()) for s in scores)
    if audit.get('reviewed_run_sha256') != expected_runs:
        return {'passed': False, 'reason': 'Audit is not bound to these exact scored attempts'}
    for name in ('C039', 'C040', 'cost_budget'):
        entry = audit.get('checks', {}).get(name, {})
        if entry.get('status') != 'passed' or not entry.get('reason') or not entry.get('evidence'):
            return {'passed': False, 'reason': f'Unverified audit gate: {name}'}
        for artifact in entry['evidence']:
            source = Path(artifact.get('path', ''))
            if not source.is_file() or digest(source.read_bytes()) != artifact.get('sha256'):
                return {'passed': False, 'reason': f'Invalid audit evidence: {name}'}
    return {'passed': True, 'evaluator': audit['evaluator'], 'sha256': digest(path.read_bytes())}


def compare(root, audit_path=None):
    root = Path(root)
    scores = [score_run(path.parent, read(path)) for path in sorted(root.rglob('grade.json'))]
    observed, observed_items, observed_usable, run_metadata = {}, {}, {}, {}
    row_guard_failures, candidate_nonpassing_trials = [], []
    for score in scores:
        for row in score['rows']:
            key = (row['id'], row['variant'], row['axis'], score['arm'], score['trial'])
            if key in observed:
                raise ValueError(f'Duplicate graded attempt: {key}; retain ungraded history or select attempts explicitly')
            observed[key] = row['status']
            observed_usable[key] = score['usable']
            if score['arm'] == 'candidate':
                if row['status'] != 'passed':
                    candidate_nonpassing_trials.append({'unit': key[:3], 'trial': score['trial'], 'status': row['status']})
                if row['confirmed_false_defects'] or row['false_runtime_promotion']:
                    row_guard_failures.append({'unit': key[:3], 'trial': score['trial'],
                                               'confirmed_false_defects': row['confirmed_false_defects'],
                                               'false_runtime_promotion': row['false_runtime_promotion']})
            observed_items[key] = {item['item']: item['status'] for item in row['items']}
            run_metadata[key] = score['run_metadata']
    missing, regressions, improvements, inconsistent = [], [], [], []
    missing_baseline, pair_mismatches, comparison_issues, item_regressions = [], [], [], []
    eligible = [s['run_metadata'] for s in scores if s['usable']]
    for arm in ('baseline', 'candidate'):
        snapshots = {r.get('snapshot_sha256') for r in eligible if r.get('arm') == arm}
        if None in snapshots or '' in snapshots or len(snapshots) > 1:
            comparison_issues.append({'field': 'snapshot_sha256', 'arm': arm, 'reason': 'Each arm requires one pinned snapshot'})
    for field in ('model', 'effort', 'harness_version'):
        values = {r.get(field) for r in eligible}
        if None in values or '' in values or len(values) > 1:
            comparison_issues.append({'field': field, 'reason': 'One pinned value is required across all scored runs'})
    for score in scores:
        if score['usable']:
            run = score['run_metadata']
            if run.get('corpus') != FROZEN:
                comparison_issues.append({'field': 'corpus', 'run': score['run_directory']})
            if not isinstance(run.get('execution_settings'), dict) or not run['execution_settings']:
                comparison_issues.append({'field': 'execution_settings', 'run': score['run_directory'], 'reason': 'Missing tool/control settings'})
    for unit in units():
        before = observed.get(unit + ('baseline', 1), 'unexecuted')
        after = observed.get(unit + ('candidate', 1), 'unexecuted')
        if before not in ('passed', 'failed'):
            missing_baseline.append({'unit': unit, 'baseline_status': before})
        unit_runs = [run_metadata[unit + (arm, trial)] for arm in ('baseline', 'candidate') for trial in (1, 2, 3)
                     if unit + (arm, trial) in run_metadata]
        for field in ('model', 'effort', 'harness_version', 'input_sha256', 'execution_settings', 'corpus'):
            values = {json.dumps(r.get(field), sort_keys=True) for r in unit_runs}
            if len(values) > 1 or (unit_runs and any(not r.get(field) for r in unit_runs)):
                comparison_issues.append({'unit': unit, 'field': field, 'reason': 'Paired arms and confirmation trials must use identical settings/inputs'})
        for trial in (1, 2, 3):
            left = run_metadata.get(unit + ('baseline', trial))
            right = run_metadata.get(unit + ('candidate', trial))
            if left and right:
                fields = ('model', 'effort', 'harness_version', 'input_sha256', 'execution_settings', 'corpus')
                if any(left.get(field) != right.get(field) for field in fields):
                    pair_mismatches.append({'unit': unit, 'trial': trial})
            if observed.get(unit + ('baseline', trial)) == 'passed' and observed.get(unit + ('candidate', trial)) not in (None, 'passed'):
                if unit not in regressions:
                    regressions.append(unit)
        if after != 'passed':
            missing.append({'unit': unit, 'candidate_status': after})
        if before == 'passed' and after != 'passed' and unit not in regressions:
            regressions.append(unit)
        item_ids = set(observed_items.get(unit + ('baseline', 1), {})) | set(observed_items.get(unit + ('candidate', 1), {}))
        for item_id in sorted(item_ids):
            pairs = [(observed_items.get(unit + ('baseline', trial), {}).get(item_id),
                      observed_items.get(unit + ('candidate', trial), {}).get(item_id)) for trial in (1, 2, 3)]
            for trial, (old, new) in enumerate(pairs, 1):
                if old == 'passed' and new not in (None, 'passed'):
                    item_regressions.append({'unit': unit, 'item': item_id, 'trial': trial})
            first = pairs[0]
            if first in (('failed', 'passed'), ('passed', 'failed')):
                confirmed_rows = all(observed.get(unit + ('candidate', trial)) == 'passed'
                                     and observed.get(unit + ('baseline', trial)) in ('passed', 'failed')
                                     and observed_usable.get(unit + ('baseline', trial))
                                     and observed_usable.get(unit + ('candidate', trial)) for trial in (1, 2, 3))
                if first == ('failed', 'passed') and all(pair == first for pair in pairs) and confirmed_rows:
                    improvements.append({'unit': unit, 'item': item_id})
                elif not all(pair == first for pair in pairs) or not confirmed_rows:
                    inconsistent.append({'unit': unit, 'item': item_id})
    times = [s['elapsed_seconds'] for s in scores if s['elapsed_seconds'] is not None]
    coverage_complete = not (missing or missing_baseline or pair_mismatches or comparison_issues or regressions or item_regressions or inconsistent or row_guard_failures or candidate_nonpassing_trials)
    execution_complete = all(observed.get(unit + (arm, 1)) in ('passed', 'failed') for unit in units() for arm in ('baseline', 'candidate'))
    audit = validate_audit(audit_path or root / 'scope-cost-audit.json', scores)
    complete = coverage_complete and bool(improvements) and audit['passed']
    return {'complete': complete, 'validation_complete': complete, 'execution_complete': execution_complete,
            'coverage_complete': coverage_complete, 'scope_cost_audit': audit,
            'effectiveness': 'demonstrated' if complete else 'unproven',
            'mandatory_units': len(units()), 'missing_or_nonpassing': missing, 'missing_baseline': missing_baseline,
            'pair_mismatches': pair_mismatches, 'comparison_issues': comparison_issues, 'regressions': regressions, 'item_regressions': item_regressions,
            'row_guard_failures': row_guard_failures, 'candidate_nonpassing_trials': candidate_nonpassing_trials,
            'repeatable_improvements': improvements, 'unconfirmed_differences': inconsistent,
            'scored_runs': len(scores), 'wall_seconds_median': statistics.median(times) if times else None,
            'per_run_costs': [{k: s[k] for k in ('arm', 'trial', 'elapsed_seconds', 'loaded_instruction_bytes', 'run_directory')} for s in scores]}


def import_runtime(record_path, snapshot_root, output):
    record = read(record_path)
    snapshot = validate_snapshot(snapshot_root)
    _, rubric = corpus()
    rule = next((c for c in rubric['cases'] if c['id'] == record['id']), None)
    if not rule or 'runtime_probe' not in rule['workflows'] or record['variant'] not in ('a', 'b'):
        raise ValueError('Unknown runtime case/variant')
    for field in ('command_or_tool', 'observations', 'source_run', 'component_pins', 'fixture_pins', 'runtime_method', 'evidence'):
        if not record.get(field):
            raise ValueError(f'Missing runtime provenance: {field}')
    if record['kind'] not in ('deterministic_fixture', 'agent_runtime_detection'):
        raise ValueError('Runtime evidence kind must be explicit')
    artifacts = []
    for index, item in enumerate(record['evidence']):
        source = Path(item['path']).resolve()
        data = source.read_bytes()
        if digest(data) != item['sha256']:
            raise ValueError('Runtime artifact hash mismatch')
        artifacts.append((f'evidence-{index:03d}' + source.suffix, data, item))
    agent = record.get('agent_run', {})
    actual_agent = record['kind'] == 'agent_runtime_detection'
    if actual_agent:
        required = ('command', 'model', 'effort', 'harness_version', 'prompt', 'answer', 'transcript',
                    'input_sha256', 'loaded_files', 'tool_calls', 'elapsed_seconds', 'trial', 'status', 'execution_settings')
        if any(key not in agent for key in required) or agent['tool_calls'] < 1:
            raise ValueError('Actual agent runtime detection requires its complete run and tool transcript')
        if agent['trial'] not in (1, 2, 3):
            raise ValueError('Invalid paired trial')
        for path, expected in agent['loaded_files'].items():
            if path not in snapshot['files'] or snapshot['files'][path] != expected:
                raise ValueError('Runtime loaded instruction differs from assigned snapshot')
        agent_bytes = {}
        for key in ('prompt', 'answer', 'transcript'):
            artifact = agent[key]
            data = Path(artifact['path']).read_bytes()
            if not data or digest(data) != artifact['sha256']:
                raise ValueError(f'Runtime {key} absent or changed')
            agent_bytes[key] = data
    output = Path(output)
    output.mkdir(parents=True, exist_ok=False)
    local_evidence = []
    for name, data, original in artifacts:
        (output / name).write_bytes(data)
        local_evidence.append({'path': name, 'sha256': digest(data), 'source_path': original['path']})
    record['evidence'] = local_evidence
    write(output / 'runtime-source.json', record)
    metadata = {'axis': 'runtime_probe', 'ids': [record['id']], 'variant': record['variant'],
                'arm': snapshot['arm'], 'snapshot_sha256': snapshot['snapshot_sha256'], 'corpus': FROZEN,
                'runtime_kind': record['kind'], 'runtime_source_sha256': digest((output / 'runtime-source.json').read_bytes()),
                'runtime_artifacts': local_evidence}
    if actual_agent:
        for key, destination in (('prompt', 'prompt.txt'), ('answer', 'answer.txt'), ('transcript', 'events.jsonl')):
            (output / destination).write_bytes(agent_bytes[key])
        metadata.update(status='completed' if agent['status'] == 'completed' else 'unusable',
                        answer_sha256=digest(agent_bytes['answer']), events_sha256=digest(agent_bytes['transcript']),
                        prompt_sha256=digest(agent_bytes['prompt']),
                        loaded_instruction_bytes=sum(entry['bytes'] for entry in agent['loaded_files'].values()))
        metadata.update({key: agent[key] for key in ('command', 'model', 'effort', 'harness_version', 'input_sha256',
                         'loaded_files', 'tool_calls', 'elapsed_seconds', 'trial', 'execution_settings')})
    else:
        metadata.update(status='unexecuted', loaded_instruction_bytes=0, trial=record.get('trial', 1))
    write(output / 'export.json', metadata)
    write_run(output, metadata)
    return {'directory': str(output), 'kind': record['kind'], 'status': metadata['status'],
            'agent_credit': 'Requires independent evidence-backed grade' if actual_agent else 'None; deterministic fixture only'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('prepare'); p.add_argument('--source', required=True); p.add_argument('--output', required=True); p.add_argument('--arm', choices=('baseline', 'candidate'), required=True)
    p = sub.add_parser('export'); p.add_argument('--snapshot', required=True); p.add_argument('--axis', choices=AXES, required=True); p.add_argument('--ids', nargs='+', required=True); p.add_argument('--variant', choices=('a', 'b'), required=True); p.add_argument('--output', required=True)
    p = sub.add_parser('pair'); p.add_argument('--baseline', required=True); p.add_argument('--candidate', required=True); p.add_argument('--axis', choices=AXES, required=True); p.add_argument('--ids', nargs='+', required=True); p.add_argument('--variant', choices=('a', 'b'), required=True); p.add_argument('--output', required=True); p.add_argument('--trial', type=int, choices=(1, 2, 3), default=1); p.add_argument('--model'); p.add_argument('--effort'); p.add_argument('--timeout', type=int, default=180); p.add_argument('--execute', action='store_true')
    p = sub.add_parser('import-runtime'); p.add_argument('--record', required=True); p.add_argument('--snapshot', required=True); p.add_argument('--output', required=True)
    p = sub.add_parser('grade-template'); p.add_argument('--run', required=True)
    p = sub.add_parser('score'); p.add_argument('--run', required=True); p.add_argument('--grade', required=True)
    p = sub.add_parser('compare'); p.add_argument('--root', required=True); p.add_argument('--audit')
    args = parser.parse_args()
    if args.command == 'prepare':
        result = prepare(args.source, args.output, args.arm)
    elif args.command == 'export':
        result = export(args.snapshot, args.axis, args.ids, args.variant, args.output)
    elif args.command == 'pair':
        if args.axis == 'runtime_probe':
            raise ValueError('Execute runtime fixtures separately; this runner only launches recorded-input lanes')
        if args.execute and not args.model:
            raise ValueError('--execute requires explicit --model; resolve the current model with bin/devkit-model luna')
        effort = effective_effort(args.effort) if args.execute else args.effort
        order = ('baseline', 'candidate') if (args.trial + int(args.ids[0][1:])) % 2 == 0 else ('candidate', 'baseline')
        result = []
        for arm in order:
            target = Path(args.output) / arm
            info = export(getattr(args, arm), args.axis, args.ids, args.variant, target)
            if args.execute:
                info = launch(target, args.model, effort, args.timeout)
                info['trial'] = args.trial
                write(target / 'run.json', info)
            result.append({'arm': arm, 'trial': args.trial, 'directory': str(target), 'status': info.get('status', 'exported_only'), 'loaded_instruction_bytes': info['loaded_instruction_bytes']})
    elif args.command == 'import-runtime':
        result = import_runtime(args.record, args.snapshot, args.output)
    elif args.command == 'grade-template':
        result = grade_template(args.run)
    elif args.command == 'score':
        result = score_run(args.run, read(args.grade))
    else:
        result = compare(args.root, args.audit)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(2)
