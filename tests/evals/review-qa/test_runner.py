import importlib.util
import json
import shutil
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('review_qa_run', Path(__file__).with_name('run.py'))
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.snapshot = self.root / 'snapshot'
        self.snapshot.mkdir()
        _, rubric = runner.corpus()
        files = {}
        for path in runner.inventory(rubric):
            target = self.snapshot / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text('Assigned instruction ' + path)
            files[path] = {'sha256': runner.digest(target.read_bytes()), 'bytes': target.stat().st_size}
        runner.write(self.snapshot / 'snapshot.json', {'arm': 'baseline', 'files': files, 'corpus': runner.FROZEN,
                     'snapshot_sha256': runner.digest(json.dumps(files, sort_keys=True).encode())})

    def tearDown(self):
        self.temp.cleanup()

    def export(self, key='C001', variant='a', axis='static_review'):
        directory = self.root / f'{key}-{variant}-{axis}'
        runner.export(self.snapshot, axis, [key], variant, directory)
        return directory

    def completed(self, directory):
        metadata = runner.read(directory / 'export.json')
        (directory / 'answer.txt').write_text('Grounded assessment of the contract and source.')
        (directory / 'events.jsonl').write_text('{"type":"turn.completed"}\n')
        result = metadata | {'status': 'completed', 'trial': 1,
                             'answer_sha256': runner.digest((directory / 'answer.txt').read_bytes()),
                             'events_sha256': runner.digest((directory / 'events.jsonl').read_bytes())}
        result = runner.write_run(directory, result)
        grade = runner.grade_template(directory)
        grade.update(evaluator='independent-reviewer', independent_of_tested_agent=True, answer_sha256=result['answer_sha256'])
        for row in grade['rows']:
            for item in row['items']:
                item.update(status='passed', reason='Contract/source reviewed independently.', evidence=['answer.txt:1'])
        return grade

    def test_export_does_not_disclose_polarity_rubric_or_other_variant(self):
        directory = self.export()
        prompt = (directory / 'prompt.txt').read_text()
        self.assertNotIn('fault_variant', prompt)
        self.assertNotIn('clean_guard', prompt)
        self.assertNotIn('rubric.json', prompt)
        payload = runner.read(directory / 'inputs.json')[0]
        self.assertEqual(set(payload), {'id', 'brief', 'contract', 'evidence'})
        self.assertIn('exercise: placement.exercise', prompt)
        self.assertNotIn('placement: placement.id', prompt)

    def test_mixed_review_entry_skills_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Incompatible batch'):
            runner.export(self.snapshot, 'static_review', ['C001', 'C003'], 'a', self.root / 'mixed')
        runner.export(self.snapshot, 'static_review', ['C001', 'C002'], 'a', self.root / 'compatible')

    def test_browser_and_verify_profiles_cannot_share_batch(self):
        with self.assertRaisesRegex(ValueError, 'Incompatible batch'):
            runner.export(self.snapshot, 'evidence_adjudication', ['C012', 'C013'], 'a', self.root / 'mixed')

    def test_mutated_snapshot_rejected(self):
        (self.snapshot / 'plugins/core/conduct/behavioral-completeness.md').write_text('changed')
        with self.assertRaisesRegex(ValueError, 'Snapshot content changed'):
            self.export()

    def test_baseline_source_mismatch_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Baseline source mismatch'):
            runner.prepare(self.snapshot, self.root / 'new', 'baseline')

    def test_no_run_cannot_be_graded_as_pass(self):
        directory = self.export()
        grade = runner.grade_template(directory)
        grade.update(evaluator='someone', independent_of_tested_agent=True)
        for item in grade['rows'][0]['items']:
            item.update(status='passed', reason='asserted', evidence=['pretend'])
        result = runner.score_run(directory, grade)
        self.assertFalse(result['usable'])
        self.assertTrue(all(i['status'] == 'unexecuted' for i in result['rows'][0]['items']))

    def test_clean_variant_uses_guard_not_required_defect(self):
        directory = self.export(variant='b')
        grade = self.completed(directory)
        self.assertEqual(len(grade['rows'][0]['items']), 1)
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'passed')
        grade['rows'][0]['confirmed_false_defects'] = ['Demands independent copies of intentionally shared content.']
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'failed')

    def test_failed_item_and_false_runtime_promotion_fail(self):
        directory = self.export()
        grade = self.completed(directory)
        grade['rows'][0]['items'][0]['status'] = 'failed'
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'failed')
        grade['rows'][0]['items'][0]['status'] = 'passed'
        grade['rows'][0]['false_runtime_promotion'] = True
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'failed')

    def test_missing_evidence_and_tampered_answer_cannot_pass(self):
        directory = self.export()
        grade = self.completed(directory)
        grade['rows'][0]['items'][0]['evidence'] = []
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'incomplete')
        (directory / 'answer.txt').write_text('different')
        self.assertFalse(runner.score_run(directory, grade)['usable'])

    def test_completed_export_identity_cannot_be_relabelled(self):
        directory = self.export(axis='case_generation')
        grade = self.completed(directory)
        original = (directory / 'export.json').read_bytes()
        for change in ({'ids': ['C002']}, {'variant': 'b'}, {'ids': ['C012'], 'axis': 'runtime_probe'}):
            with self.subTest(change=change):
                runner.write(directory / 'export.json', json.loads(original) | change)
                with self.assertRaisesRegex(ValueError, 'export binding'):
                    runner.grade_template(directory)
                with self.assertRaisesRegex(ValueError, 'export binding'):
                    runner.score_run(directory, grade)
                (directory / 'export.json').write_bytes(original)

    def test_export_swap_between_completed_attempts_is_rejected(self):
        first, second = self.export('C001'), self.export('C002')
        grade = self.completed(first)
        self.completed(second)
        shutil.copyfile(second / 'export.json', first / 'export.json')
        with self.assertRaisesRegex(ValueError, 'export binding'):
            runner.score_run(first, grade)

    def test_missing_binding_and_changed_run_axis_are_rejected(self):
        directory = self.export()
        grade = self.completed(directory)
        result = runner.read(directory / 'run.json')
        legacy = dict(result)
        legacy.pop('export_sha256')
        runner.write(directory / 'run.json', legacy)
        with self.assertRaisesRegex(ValueError, 'export binding'):
            runner.score_run(directory, grade)
        runner.write(directory / 'run.json', result | {'axis': 'runtime_probe'})
        with self.assertRaisesRegex(ValueError, 'Run identity differs'):
            runner.score_run(directory, grade)

    def test_export_identity_is_checked_before_launch(self):
        directory = self.export()
        metadata = runner.read(directory / 'export.json')
        runner.write(directory / 'export.json', metadata | {'ids': ['C002']})
        with patch.object(runner.subprocess, 'run') as invoke:
            with self.assertRaisesRegex(ValueError, 'frozen inputs'):
                runner.launch(directory, 'fixture-model', 'high', 1)
            invoke.assert_not_called()

    def test_prompt_payload_must_match_exported_case(self):
        directory = self.export()
        prompt = (directory / 'prompt.txt').read_text().rsplit('\n\nINPUTS\n', 1)[0] + '\n\nINPUTS\n[]'
        (directory / 'prompt.txt').write_text(prompt)
        metadata = runner.read(directory / 'export.json')
        runner.write(directory / 'export.json', metadata | {'prompt_sha256': runner.digest(prompt.encode())})
        with self.assertRaisesRegex(ValueError, 'Prompt inputs differ'):
            runner.grade_template(directory)

    def test_recorded_trace_cannot_launch_runtime_lane(self):
        with self.assertRaisesRegex(ValueError, 'Recorded fixtures cannot become runtime probes'):
            self.export('C012', axis='runtime_probe')

    def test_empty_comparison_cannot_complete(self):
        result = runner.compare(self.root)
        self.assertFalse(result['complete'])
        self.assertEqual(result['effectiveness'], 'unproven')
        self.assertEqual(len(result['missing_baseline']), result['mandatory_units'])

    def test_scope_controls_do_not_load_conditional_references(self):
        directory = self.export('C040', axis='evidence_adjudication')
        metadata = runner.read(directory / 'export.json')
        self.assertEqual(list(metadata['loaded_files']), ['plugins/core/skills/browser/SKILL.md'])

    def paired_grade(self, arm, trial, status, model='fixture-model', ids=None, snapshot_sha=None):
        directory = self.root / f'{arm}-{trial}'
        runner.export(self.snapshot, 'static_review', ids or ['C001'], 'a', directory)
        export = runner.read(directory / 'export.json')
        export['arm'] = arm
        if snapshot_sha:
            export['snapshot_sha256'] = snapshot_sha
        runner.write(directory / 'export.json', export)
        grade = self.completed(directory)
        result = runner.read(directory / 'run.json')
        result.update(arm=arm, trial=trial, model=model, effort='high', harness_version='fixture',
                      execution_settings={'sandbox': 'read-only', 'tools': 'forbidden', 'timeout_seconds': 180})
        runner.write(directory / 'run.json', result)
        grade['rows'][0]['items'][0]['status'] = status
        runner.write(directory / 'grade.json', grade)
        return directory

    def audit(self):
        evidence = self.root / 'scope-cost-check.txt'
        evidence.write_text('Independent control dispatch/load and context-budget measurements.')
        entry = {'status': 'passed', 'reason': 'Measured controls and budgets verified.',
                 'evidence': [{'path': str(evidence), 'sha256': runner.digest(evidence.read_bytes())}]}
        hashes = sorted(runner.digest((p.parent / 'run.json').read_bytes()) for p in self.root.rglob('grade.json'))
        runner.write(self.root / 'scope-cost-audit.json', {'evaluator': 'scope-reviewer',
                     'independent_of_tested_agent': True, 'corpus': runner.FROZEN,
                     'reviewed_run_sha256': hashes, 'checks': {key: entry for key in ('C039', 'C040', 'cost_budget')}})

    def test_improvement_needs_both_confirmation_pairs(self):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            self.paired_grade('baseline', 1, 'failed')
            self.paired_grade('candidate', 1, 'passed')
            initial = runner.compare(self.root)
            self.assertFalse(initial['complete'])
            self.assertEqual(initial['effectiveness'], 'unproven')
            for trial in (2, 3):
                self.paired_grade('baseline', trial, 'failed')
                self.paired_grade('candidate', trial, 'passed')
            unaudited = runner.compare(self.root)
            self.assertTrue(unaudited['coverage_complete'])
            self.assertFalse(unaudited['validation_complete'])
            self.audit()
            confirmed = runner.compare(self.root)
            self.assertTrue(confirmed['complete'])
            self.assertEqual(confirmed['effectiveness'], 'demonstrated')

    def test_pair_model_mismatch_blocks_completion(self):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            self.paired_grade('baseline', 1, 'passed')
            self.paired_grade('candidate', 1, 'passed', model='different')
            result = runner.compare(self.root)
            self.assertFalse(result['complete'])
            self.assertTrue(result['pair_mismatches'])

    def test_regression_blocks_completion(self):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            self.paired_grade('baseline', 1, 'passed')
            self.paired_grade('candidate', 1, 'failed')
            result = runner.compare(self.root)
            self.assertFalse(result['complete'])
            self.assertTrue(result['regressions'])

    def test_ungraded_attempt_cannot_replace_graded_metadata(self):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            self.paired_grade('baseline', 1, 'passed')
            candidate = self.paired_grade('candidate', 1, 'passed', model='different')
            later = self.root / 'zzz-ungraded'
            later.mkdir()
            metadata = runner.read(candidate / 'run.json')
            metadata.update(model='fixture-model', status='unusable')
            runner.write(later / 'run.json', metadata)
            result = runner.compare(self.root)
            self.assertFalse(result['coverage_complete'])
            self.assertTrue(result['pair_mismatches'])

    def test_duplicate_graded_attempt_rejected(self):
        self.paired_grade('baseline', 1, 'passed')
        shutil.copytree(self.root / 'baseline-1', self.root / 'zzz-repeat')
        with self.assertRaisesRegex(ValueError, 'Duplicate graded attempt'):
            runner.compare(self.root)

    def test_snapshot_must_stay_fixed_across_confirmation_trials(self):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            for trial in (1, 2, 3):
                self.paired_grade('baseline', trial, 'failed')
                self.paired_grade('candidate', trial, 'passed', snapshot_sha=str(trial) * 64)
            self.audit()
            result = runner.compare(self.root)
            self.assertFalse(result['complete'])
            self.assertTrue(any(i['field'] == 'snapshot_sha256' for i in result['comparison_issues']))

    def test_same_criterion_must_improve_in_every_pair(self):
        with patch.object(runner, 'units', return_value=[('C023', 'a', 'static_review')]):
            for trial in (1, 2, 3):
                directory = self.paired_grade('baseline', trial, 'failed', ids=['C023'])
                self.paired_grade('candidate', trial, 'passed', ids=['C023'])
                if trial == 2:
                    grade = runner.read(directory / 'grade.json')
                    grade['rows'][0]['items'][0]['status'] = 'passed'
                    grade['rows'][0]['items'][1]['status'] = 'failed'
                    runner.write(directory / 'grade.json', grade)
            self.audit()
            result = runner.compare(self.root)
            self.assertFalse(result['complete'])
            self.assertEqual(result['repeatable_improvements'], [])
            self.assertTrue(result['unconfirmed_differences'])

    def test_case_generation_clean_guard_alone_is_insufficient(self):
        directory = self.export(variant='b', axis='case_generation')
        grade = self.completed(directory)
        self.assertIn('axis-case-generation', [i['item'] for i in grade['rows'][0]['items']])
        grade['rows'][0]['items'] = [i for i in grade['rows'][0]['items'] if i['item'] != 'axis-case-generation']
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'incomplete')

    def test_fault_case_generation_requires_cases_and_its_mechanism(self):
        directory = self.export(axis='case_generation')
        grade = self.completed(directory)
        self.assertEqual([i['item'] for i in grade['rows'][0]['items']], ['2', 'axis-case-generation'])
        for key in ('2', 'axis-case-generation'):
            with self.subTest(item=key):
                revised = json.loads(json.dumps(grade))
                item = next(i for i in revised['rows'][0]['items'] if i['item'] == key)
                item.update(status='not_applicable', applicable=False, reason='Evaluator attempts to waive required work')
                result = runner.score_run(directory, revised)
                self.assertEqual(result['rows'][0]['status'], 'incomplete')
                self.assertEqual(next(i for i in result['rows'][0]['items'] if i['item'] == key)['status'], 'unexecuted')

    def test_static_finding_cannot_be_replaced_with_a_case_design_item(self):
        directory = self.export()
        grade = self.completed(directory)
        self.assertEqual([i['item'] for i in grade['rows'][0]['items']], ['1'])
        grade['rows'][0]['items'][0].update(status='not_applicable', applicable=False, reason='Only proposing tests')
        grade['rows'][0]['items'].append({'item': '2', 'status': 'passed', 'applicable': True,
                                        'reason': 'Proposed tests', 'evidence': ['answer.txt:1']})
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'incomplete')

    def test_passed_item_cannot_disable_its_applicability(self):
        directory = self.export()
        grade = self.completed(directory)
        grade['rows'][0]['items'][0]['applicable'] = False
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'incomplete')

    def test_static_native_review_requires_identifying_the_missing_event_path(self):
        directory = self.export('C033')
        grade = self.completed(directory)
        self.assertEqual([i['item'] for i in grade['rows'][0]['items']], ['1', '2'])
        grade['rows'][0]['items'] = [item for item in grade['rows'][0]['items'] if item['item'] == '1']
        self.assertEqual(runner.score_run(directory, grade)['rows'][0]['status'], 'incomplete')

    def test_parity_is_coverage_not_completed_validation(self):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            self.paired_grade('baseline', 1, 'passed')
            self.paired_grade('candidate', 1, 'passed')
            self.audit()
            result = runner.compare(self.root)
            self.assertTrue(result['execution_complete'])
            self.assertTrue(result['coverage_complete'])
            self.assertFalse(result['validation_complete'])
            self.assertEqual(result['effectiveness'], 'unproven')

    def test_confirmation_inputs_and_tool_settings_must_stay_fixed(self):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            for trial in (1, 2, 3):
                for arm, status in (('baseline', 'failed'), ('candidate', 'passed')):
                    directory = self.paired_grade(arm, trial, status, ids=['C001', 'C002'] if trial == 2 else ['C001'])
                    if trial == 2:
                        metadata = runner.read(directory / 'run.json')
                        metadata['execution_settings']['tools'] = 'allowed'
                        runner.write(directory / 'run.json', metadata)
            self.audit()
            result = runner.compare(self.root)
            self.assertFalse(result['complete'])
            fields = {i['field'] for i in result['comparison_issues']}
            self.assertTrue({'input_sha256', 'execution_settings'} <= fields)

    def test_scope_cost_audit_is_bound_to_exact_runs(self):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            for trial in (1, 2, 3):
                self.paired_grade('baseline', trial, 'failed')
                self.paired_grade('candidate', trial, 'passed')
            self.audit()
            metadata = runner.read(self.root / 'candidate-3/run.json')
            metadata['elapsed_seconds'] = 99
            runner.write(self.root / 'candidate-3/run.json', metadata)
            result = runner.compare(self.root)
            self.assertFalse(result['complete'])
            self.assertFalse(result['scope_cost_audit']['passed'])

    def assert_confirmation_guard_rejects(self, flag, value):
        with patch.object(runner, 'units', return_value=[('C001', 'a', 'static_review')]):
            for trial in (1, 2, 3):
                self.paired_grade('baseline', trial, 'failed')
                directory = self.paired_grade('candidate', trial, 'passed')
                if trial == 2:
                    grade = runner.read(directory / 'grade.json')
                    grade['rows'][0][flag] = value
                    runner.write(directory / 'grade.json', grade)
            self.audit()
            result = runner.compare(self.root)
            self.assertFalse(result['validation_complete'])
            self.assertFalse(result['coverage_complete'])
            self.assertEqual(result['repeatable_improvements'], [])
            self.assertTrue(result['row_guard_failures'])
            self.assertEqual(result['candidate_nonpassing_trials'][0]['trial'], 2)

    def test_confirmation_false_runtime_promotion_blocks_gain(self):
        self.assert_confirmation_guard_rejects('false_runtime_promotion', True)

    def test_confirmation_false_defect_blocks_gain(self):
        self.assert_confirmation_guard_rejects('confirmed_false_defects', ['Invented a second defect.'])

    def test_execution_requires_explicit_resolved_model(self):
        argv = ['run.py', 'pair', '--baseline', 'base', '--candidate', 'next', '--axis', 'static_review',
                '--ids', 'C039', '--variant', 'a', '--output', 'unused', '--execute']
        with patch.object(runner.sys, 'argv', argv):
            with self.assertRaisesRegex(ValueError, 'requires explicit --model'):
                runner.main()

    def test_dry_pair_needs_no_model_or_config(self):
        argv = ['run.py', 'pair', '--baseline', str(self.snapshot), '--candidate', str(self.snapshot),
                '--axis', 'static_review', '--ids', 'C039', '--variant', 'a', '--output', str(self.root / 'dry')]
        with patch.object(runner.sys, 'argv', argv), patch.object(runner, 'effective_effort', side_effect=AssertionError('unexpected config read')), patch('builtins.print'):
            runner.main()
        self.assertFalse((self.root / 'dry/baseline/run.json').exists())

    def runtime_record(self):
        evidence = self.root / 'probe.txt'
        evidence.write_text('Actual local request: revision=r1, checkout passed; then revision=r2.')
        record = {'id': 'C012', 'variant': 'a', 'kind': 'deterministic_fixture',
                  'command_or_tool': ['python3', 'local_probe.py'], 'observations': ['r1 then r2'],
                  'source_run': 'local-run-1', 'component_pins': {'frontend': ['r1', 'r2']},
                  'fixture_pins': {'cart': 'synthetic1'}, 'runtime_method': 'local synthetic HTTP',
                  'evidence': [{'path': str(evidence), 'sha256': runner.digest(evidence.read_bytes())}]}
        path = self.root / 'runtime.json'
        runner.write(path, record)
        return path, record

    def test_deterministic_runtime_never_earns_agent_credit(self):
        path, _ = self.runtime_record()
        destination = self.root / 'runtime'
        result = runner.import_runtime(path, self.snapshot, destination)
        self.assertEqual(result['status'], 'unexecuted')
        grade = runner.grade_template(destination)
        self.assertFalse(runner.score_run(destination, grade)['usable'])
        result = runner.read(destination / 'run.json')
        self.assertEqual(result['export_sha256'], runner.digest((destination / 'export.json').read_bytes()))

    def test_runtime_agent_requires_actual_transcript(self):
        path, record = self.runtime_record()
        record['kind'] = 'agent_runtime_detection'
        record['agent_run'] = {'status': 'passed'}
        runner.write(path, record)
        with self.assertRaisesRegex(ValueError, 'complete run and tool transcript'):
            runner.import_runtime(path, self.snapshot, self.root / 'runtime')

    def test_runtime_artifact_tampering_rejected(self):
        path, record = self.runtime_record()
        Path(record['evidence'][0]['path']).write_text('changed')
        with self.assertRaisesRegex(ValueError, 'artifact hash mismatch'):
            runner.import_runtime(path, self.snapshot, self.root / 'runtime')

    def test_tool_call_invalidates_recorded_input_run(self):
        directory = self.export()
        def fake_run(command, **kwargs):
            (directory / 'answer.txt').write_text('answer')
            kwargs['stdout'].write('{"type":"item.completed","item":{"type":"command_execution"}}\n{"type":"turn.completed"}\n')
            return type('Result', (), {'returncode': 0})()
        with patch.object(runner.subprocess, 'run', fake_run), patch.object(runner.subprocess, 'check_output', return_value='codex fixture'):
            result = runner.launch(directory, 'fixture-model', 'high', 1)
        self.assertEqual(result['status'], 'unusable')
        self.assertEqual(result['tool_calls'], 1)
        self.assertEqual(result['export_sha256'], runner.digest((directory / 'export.json').read_bytes()))
        self.assertIn('--ignore-user-config', result['command'])
        work = Path(result['command'][result['command'].index('-C') + 1])
        self.assertNotIn('baseline', str(work))
        self.assertNotIn('candidate', str(work))
        self.assertFalse(work.exists())


if __name__ == '__main__':
    unittest.main()
