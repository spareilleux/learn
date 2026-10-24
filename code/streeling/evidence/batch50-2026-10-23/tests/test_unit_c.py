"""Independent authored-case calculations; no engine, material or learner claims."""
import copy
import json
import math
from pathlib import Path
import unittest

EVIDENCE = Path(__file__).resolve().parents[1]
PACKET = json.loads((EVIDENCE / 'unit-c.json').read_text(encoding='utf-8'))
MODELS = {c['code']: c['authored_model'] for c in PACKET['courses']}
SCOPE = 'Authored finite mathematics/logical witnesses only; no renderer, material, policy executor or learner validation.'


def cross(a, b):
    return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]


def subtract(a, b):
    return [x-y for x, y in zip(a, b)]


def diagonal(d, v):
    return [a*b for a, b in zip(d, v)]


def norm(v):
    return math.sqrt(sum(x*x for x in v))


def basis_sample(t, b, n, sample):
    return [sample[0]*t[i]+sample[1]*b[i]+sample[2]*n[i] for i in range(3)]


def nearest_rank(values, probability):
    if not values or not 0 < probability <= 1:
        raise ValueError('Nearest-rank requires data and 0 < p <= 1')
    return sorted(values)[math.ceil(probability*len(values))-1]


def normalize_row(row):
    total = sum(row)
    return [x/total for x in row] if total else None


def queue_trace(initial, arrivals, capacity, weeks):
    trace, departures = [initial], []
    for _ in range(weeks):
        available = trace[-1] + arrivals
        completed = min(available, capacity)
        departures.append(completed)
        trace.append(available-completed)
    return trace, departures


class UnitCClaims(unittest.TestCase):
    def close(self, observed, expected):
        if isinstance(expected, dict):
            self.assertEqual(set(observed), set(expected))
            for key in expected:
                with self.subTest(quantity=key):
                    self.close(observed[key], expected[key])
        elif isinstance(expected, list):
            self.assertEqual(len(observed), len(expected))
            for index, (actual, target) in enumerate(zip(observed, expected)):
                with self.subTest(index=index):
                    self.close(actual, target)
        elif isinstance(expected, bool) or expected is None or isinstance(expected, str):
            self.assertEqual(observed, expected)
        else:
            self.assertIsInstance(observed, (float, int))
            self.assertTrue(math.isfinite(observed))
            self.assertAlmostEqual(observed, expected, delta=max(1e-12, abs(expected)*1e-10))

    def observe(self, code, case, observed, expected, declared=None):
        print('OBSERVATION ' + json.dumps(dict(code=code, case=case, observed=observed,
              expected=expected, scope=SCOPE), sort_keys=True), flush=True)
        self.close(observed, expected)
        if declared is not None:
            self.close(declared, expected)

    def test_PHY013_torque_and_common_translation(self):
        m = MODELS['PHY013']; v = m['values']; f = v['force_N']
        torque = lambda point, origin: cross(subtract(point, origin), f)
        observed = {'torque_Nm': torque(v['point_m'], v['origin_m']),
                    'second_torque_Nm': torque(v['point_m'], v['second_origin_m'])}
        self.observe('PHY013', 'model', observed,
                     {'torque_Nm': [0,0,-6], 'second_torque_Nm': [0,0,-4]}, m['expected_calculations'])
        c = m['negative_control']
        self.observe('PHY013', 'negative', torque(c['point_m'], c['origin_m']), [0,0,-6], c['expected_torque_Nm'])
        self.close(torque(v['point_m'], v['point_m']), [0,0,0])
        self.assertEqual(norm(f), 20)

    def test_PHY014_mass_scaling_and_fixed_stock_thickness(self):
        m=MODELS['PHY014']; v=m['values']; s=v['scale']
        volume=v['width_m']*v['height_m']*v['thickness_m']; mass=v['density_kg_m3']*volume
        full_volume=(s*v['width_m'])*(s*v['height_m'])*(s*v['thickness_m'])
        planar_volume=(s*v['width_m'])*(s*v['height_m'])*v['thickness_m']
        o=dict(volume_m3=volume, mass_kg=mass, fully_scaled_volume_m3=full_volume,
               fully_scaled_mass_kg=v['density_kg_m3']*full_volume,
               planar_scaled_mass_kg=v['density_kg_m3']*planar_volume,
               fixed_mass_density_kg_m3=mass/full_volume)
        self.observe('PHY014','model',o,dict(volume_m3=.00002,mass_kg=.016,
                     fully_scaled_volume_m3=.00016,fully_scaled_mass_kg=.128,
                     planar_scaled_mass_kg=.064,fixed_mass_density_kg_m3=100),m['expected_calculations'])
        c=m['negative_control']
        control_t=v['thickness_m']*(s if c['scale_thickness'] else 1)
        ratio=(s*v['width_m'])*(s*v['height_m'])*control_t/volume
        self.observe('PHY014','negative',ratio,4,c['expected_mass_ratio'])
        self.assertNotEqual(ratio, s**3)

    def test_PHY015_clearance_bounds_and_common_offset(self):
        m=MODELS['PHY015']; v=m['values']; z=v['reference_surfaces_mm']
        intervals=[[a-t/2,a+t/2] for a,t in zip(z,v['thicknesses_mm'])]
        nominal=intervals[1][0]-intervals[0][1]
        thick=z[1]-z[0]-sum(v['thickened_mm'])/2
        o=dict(intervals_mm=intervals,nominal_clearance_mm=nominal,
               worst_clearance_mm=nominal-sum(v['inward_error_bounds_mm']),
               thickened_nominal_mm=thick,thickened_worst_mm=thick-sum(v['inward_error_bounds_mm']))
        self.observe('PHY015','model',o,dict(intervals_mm=[[-1,1],[2,4]],nominal_clearance_mm=1,
                     worst_clearance_mm=.3,thickened_nominal_mm=0,thickened_worst_mm=-.7),m['expected_calculations'])
        c=m['negative_control']; sides=c['one_sided_intervals_mm']
        self.observe('PHY015','negative',sides[1][0]-sides[0][1],1,c['expected_clearance_mm'])
        self.assertLess(o['thickened_worst_mm'],0)

    def test_VC011_tangent_sign_and_nondiscriminating_sample(self):
        m=MODELS['VC011']; v=m['values']; n=v['normal']; t=v['tangent']; d=v['mirror_diagonal']
        b=[v['tangent_w']*x for x in cross(n,t)]
        n2=[n[i]/d[i] for i in range(3)]; n2=[x/norm(n2) for x in n2]
        t2=diagonal(d,t); old=[v['tangent_w']*x for x in cross(n2,t2)]
        desired=diagonal(d,b); w2=v['tangent_w']*math.prod(d)
        fixed=[w2*x for x in cross(n2,t2)]
        right=basis_sample(t2,desired,n2,v['sample']); wrong=basis_sample(t2,old,n2,v['sample'])
        o=dict(bitangent=b,reflected_normal=n2,reflected_tangent=t2,old_w_bitangent=old,
               corrected_w=w2,corrected_bitangent=fixed,correct_world_sample=right,
               wrong_world_sample=wrong,sample_dot=sum(a*b for a,b in zip(right,wrong)))
        self.observe('VC011','model',o,dict(bitangent=[0,1,0],reflected_normal=[0,0,1],
                     reflected_tangent=[-1,0,0],old_w_bitangent=[0,-1,0],corrected_w=-1,
                     corrected_bitangent=[0,1,0],correct_world_sample=[0,.6,.8],
                     wrong_world_sample=[0,-.6,.8],sample_dot=.28),m['expected_calculations'])
        c=m['negative_control']; a=basis_sample(t2,fixed,n2,c['sample']); b=basis_sample(t2,old,n2,c['sample'])
        self.observe('VC011','negative',dict(correct_world=a,wrong_world=b,discriminates=a!=b),
                     dict(correct_world=[0,0,1],wrong_world=[0,0,1],discriminates=False),
                     {k:c[k] for k in ('correct_world','wrong_world','discriminates')})

    def test_VC012_grouped_submissions_and_incompatible_groups(self):
        m=MODELS['VC012']; v=m['values']; separate=v['authored_mesh_instances']*v['passes']; grouped=v['compatible_groups']*v['passes']
        self.observe('VC012','model',dict(separate_submissions=separate,grouped_submissions=grouped,reduction=separate-grouped),
                     dict(separate_submissions=120,grouped_submissions=6,reduction=114),m['expected_calculations'])
        c=m['negative_control']
        self.observe('VC012','negative',c['groups']*v['passes'],120,c['expected_submissions'])
        self.assertEqual(v['historical_block_instances'],[5,5]); self.assertEqual(v['historical_boxes'],[53,85])

    def test_VC013_winding_and_collapsed_triangle(self):
        m=MODELS['VC013']; v=m['values']; a,b,c=v['triangle']; edge=cross(subtract(b,a),subtract(c,a))
        transformed=[diagonal(v['mirror_diagonal'],x) for x in (a,b,c)]; a2,b2,c2=transformed
        baked=cross(subtract(b2,a2),subtract(c2,a2)); swapped=cross(subtract(c2,a2),subtract(b2,a2))
        o=dict(original_cross=edge,original_area=norm(edge)/2,mirror_determinant=math.prod(v['mirror_diagonal']),
               baked_cross=baked,swapped_cross=swapped,composed_determinant=math.prod(diagonal(v['mirror_diagonal'],v['second_diagonal'])))
        self.observe('VC013','model',o,dict(original_cross=[0,0,6],original_area=3,mirror_determinant=-2,
                     baked_cross=[0,0,-12],swapped_cross=[0,0,12],composed_determinant=2),m['expected_calculations'])
        control=m['negative_control']; a3,b3,c3=[diagonal(control['zero_diagonal'],x) for x in (a,b,c)]
        collapsed=cross(subtract(b3,a3),subtract(c3,a3))
        self.observe('VC013','negative',dict(cross=collapsed,area=norm(collapsed)/2),dict(cross=[0,0,0],area=0),
                     dict(cross=control['expected_cross'],area=control['expected_area']))
        self.close(cross(subtract(c3,a3),subtract(b3,a3)),[0,0,0])

    def test_DV011_normalization_and_empty_rows(self):
        m=MODELS['DV011']; rows=m['values']['raw_rows']; columns=[sum(col) for col in zip(*rows)]
        o=dict(normalized_rows=[normalize_row(r) for r in rows],totals=[sum(r) for r in rows],column_totals=columns,overall_total=sum(columns))
        self.observe('DV011','model',o,dict(normalized_rows=[[.5,.5],[.5,.5],None],totals=[2,40,0],column_totals=[21,21],overall_total=42),m['expected_calculations'])
        c=m['negative_control']; self.observe('DV011','negative',normalize_row(c['raw_row']),[.2,.8],c['expected_normalized'])
        self.assertNotEqual(rows[0],rows[1]); self.assertEqual(normalize_row(rows[0]),normalize_row(rows[1]))

    def test_DV012_nearest_rank_and_constant_cohorts(self):
        m=MODELS['DV012']; v=m['values']; probs=v['probabilities']; a=v['A_ms']; b=v['B_ms']
        qa=[nearest_rank(a,p) for p in probs]; qb=[nearest_rank(b,p) for p in probs]
        o=dict(A_quantiles_ms=qa,B_quantiles_ms=qb,pooled_quantiles_ms=[nearest_rank(a+b,p) for p in probs],
               average_medians_ms=(qa[0]+qb[0])/2,average_upper_quantiles_ms=(qa[1]+qb[1])/2)
        self.observe('DV012','model',o,dict(A_quantiles_ms=[2,100],B_quantiles_ms=[5,7],pooled_quantiles_ms=[4,100],
                     average_medians_ms=3.5,average_upper_quantiles_ms=53.5),m['expected_calculations'])
        c=m['negative_control']; self.observe('DV012','negative',nearest_rank(c['A_ms']+c['B_ms'],.5),2,c['expected_pooled_median_ms'])
        self.assertNotEqual(o['average_medians_ms'],o['pooled_quantiles_ms'][0])

    def test_DV013_equal_budgets_and_missing_endpoint(self):
        m=MODELS['DV013']; v=m['values']; pairs=[(a,b) for a,b in zip(v['A_scores'],v['B_scores']) if a is not None and b is not None]
        ma=sum(a for a,b in pairs)/len(pairs); mb=sum(b for a,b in pairs)/len(pairs)
        o=dict(shared_differences_B_minus_A=[b-a for a,b in pairs],shared_mean_A=ma,shared_mean_B=mb,
               shared_mean_difference=mb-ma,last_A=[a for a in v['A_scores'] if a is not None][-1],last_B=[b for b in v['B_scores'] if b is not None][-1])
        self.observe('DV013','model',o,dict(shared_differences_B_minus_A=[.05,.02],shared_mean_A=.65,shared_mean_B=.685,
                     shared_mean_difference=.035,last_A=.75,last_B=.72),m['expected_calculations'])
        c=m['negative_control']; diff=[b-a for a,b in zip(v['A_scores'],c['B_scores']) if a is not None and b is not None]
        self.observe('DV013','negative',diff,[0,0],c['expected_shared_differences']); self.assertIsNone(v['B_scores'][-1])

    def test_SEM009_unit_conversion_and_zero_offset(self):
        m=MODELS['SEM009']; v=m['values']; offset=v['offset_mm']*v['m_per_mm']; length=v['base_m']+offset
        o=dict(offset_m=offset,composed_m=length,composed_mm=v['base_m']/v['m_per_mm']+v['offset_mm'],
               wrong_raw_sum=v['base_m']+v['offset_mm'],scaled_offset_m=v['scale']*offset)
        self.observe('SEM009','model',o,dict(offset_m=.03,composed_m=.23,composed_mm=230,wrong_raw_sum=30.2,scaled_offset_m=.06),m['expected_calculations'])
        c=m['negative_control']; correct=v['base_m']+c['offset_mm']*v['m_per_mm']; wrong=v['base_m']+c['offset_mm']
        self.observe('SEM009','negative',dict(correct=correct,wrong=wrong,discriminates=correct!=wrong),
                     dict(correct=.2,wrong=.2,discriminates=False),dict(correct=c['expected_correct_numeric'],wrong=c['expected_wrong_numeric'],discriminates=c['discriminates']))
        self.assertNotEqual(o['composed_m'],o['wrong_raw_sum'])

    def test_SEM010_identity_locale_pairs_and_conflicting_revision(self):
        m=MODELS['SEM010']; rows=m['values']['rows']; renamed=copy.deepcopy(rows); renamed[0]['title']='Panel Clearance'
        o=dict(rows=len(rows),distinct_ids=len({r['id'] for r in rows}),distinct_pairs=len({(r['id'],r['locale']) for r in rows}),after_title_rename_distinct_ids=len({r['id'] for r in renamed}))
        self.observe('SEM010','model',o,dict(rows=4,distinct_ids=2,distinct_pairs=4,after_title_rename_distinct_ids=2),m['expected_calculations'])
        c=m['negative_control']; combined=rows+[c['duplicate']]; duplicates={}
        for row in combined: duplicates.setdefault((row['id'],row['locale']),set()).add(row['revision'])
        self.observe('SEM010','negative',dict(rows=len(combined),distinct_pairs=len(duplicates),conflict=any(len(x)>1 for x in duplicates.values())),
                     dict(rows=5,distinct_pairs=4,conflict=True))
        self.close(dict(rows=c['expected_rows'],distinct_pairs=c['expected_distinct_pairs']),dict(rows=5,distinct_pairs=4))

    def test_SEM011_version_binding_and_algebraic_zero(self):
        m=MODELS['SEM011']; v=m['values']
        meaning=lambda version,n: v[version+'_constant']+v[version+'_slope']*n
        old=meaning('v1',v['n']); new=meaning('v2',v['n']); bindings={v['old_token']:old}; bindings[v['alias']]=bindings[v['alias_binding']]
        self.observe('SEM011','model',dict(v1=old,v2=new,difference=new-old,alias_result=bindings[v['alias']]),
                     dict(v1=11,v2=19,difference=8,alias_result=11),m['expected_calculations'])
        c=m['negative_control']; a=meaning('v1',c['n']); b=meaning('v2',c['n'])
        self.observe('SEM011','negative',dict(v1=a,v2=b,discriminates=a!=b),dict(v1=3,v2=3,discriminates=False),
                     {k:c[k] for k in ('v1','v2','discriminates')})
        self.assertNotEqual(old,new)

    def test_PHI008_specification_false_positive_and_missing_field(self):
        m=MODELS['PHI008']; v=m['values']; oracle=v['well_formed']; spec=[a and b for a,b in zip(oracle,v['relevant_evidence'])]
        o=dict(spec=spec,weak_oracle=list(oracle),true_positive=sum(o and s for o,s in zip(oracle,spec)),
               false_positive=sum(o and not s for o,s in zip(oracle,spec)),true_negative=sum(not o and not s for o,s in zip(oracle,spec)),false_negative=sum(not o and s for o,s in zip(oracle,spec)))
        self.observe('PHI008','model',o,dict(spec=[True,False,False,False],weak_oracle=[True,True,False,False],
                     true_positive=1,false_positive=1,true_negative=2,false_negative=0),m['expected_calculations'])
        historical=json.loads((EVIDENCE.parent/'representation-release-2026-10-22/phi002-schema-replay.json').read_text(encoding='utf-8'))
        record=copy.deepcopy(historical['fixture']['rule_result'])
        if m['negative_control']['missing_required_field']: record.pop('confidence')
        required={'rule_id','subject','decision','reason_codes','evidence_refs','next_actions','confidence'}
        self.observe('PHI008','negative',dict(well_formed_required_keys=required.issubset(record),missing=sorted(required-set(record))),
                     dict(well_formed_required_keys=False,missing=['confidence']))
        self.assertFalse(m['negative_control']['expected_well_formed']); self.assertEqual(historical['fixture']['rule_result']['evidence_refs'],[])

    def test_PHI009_authority_and_capability_countermodels(self):
        m=MODELS['PHI009']; v=m['values']; permit=[a and s and t for a,s,t in zip(v['principal_authorized'],v['scope_matches'],v['still_valid'])]
        may=[p and c for p,c in zip(permit,v['capability'])]
        self.observe('PHI009','model',dict(permit=permit,may_execute=may),dict(permit=[False,False,False,True],may_execute=[False,False,False,True]),m['expected_calculations'])
        c=m['negative_control']; self.observe('PHI009','negative',dict(permit=c['permit'],may_execute=c['permit'] and c['capability']),dict(permit=True,may_execute=False))
        self.assertEqual(c['may_execute'],False)
        self.assertTrue(v['capability'][0]); self.assertFalse(may[0])

    def test_FUT008_backlog_growth_and_draining_control(self):
        m=MODELS['FUT008']; v=m['values']; trace,departures=queue_trace(v['initial_items'],v['arrivals_items_per_week'],v['capacity_items_per_week'],v['weeks'])
        zero,unused=queue_trace(v['initial_items'],0,v['capacity_items_per_week'],math.ceil(v['initial_items']/v['capacity_items_per_week']))
        o=dict(queue_trace=trace,departures_trace=departures,total_departures=sum(departures),zero_arrival_drain_weeks=len(zero)-1)
        self.observe('FUT008','model',o,dict(queue_trace=[12,14,16,18],departures_trace=[6,6,6],total_departures=18,zero_arrival_drain_weeks=2),m['expected_calculations'])
        c=m['negative_control']; control,depart=queue_trace(v['initial_items'],c['arrivals_items_per_week'],v['capacity_items_per_week'],c['weeks'])
        self.observe('FUT008','negative',control,[12,9,6,3,0],c['expected_trace'])
        self.assertEqual(zero[-1],0); self.assertEqual(control[-1],0)
        self.assertEqual(v['initial_items']+v['arrivals_items_per_week']*v['weeks']-sum(departures),trace[-1])

    def test_FUT009_regret_and_faulty_staged_gate(self):
        m=MODELS['FUT009']; v=m['values']; direct=v['direct_loss']; staged=v['staged_loss']; best=[min(a,b) for a,b in zip(direct,staged)]
        rd=[a-b for a,b in zip(direct,best)]; rs=[a-b for a,b in zip(staged,best)]
        o=dict(state_best=best,direct_regret=rd,staged_regret=rs,direct_worst=max(direct),staged_worst=max(staged),direct_max_regret=max(rd),staged_max_regret=max(rs))
        self.observe('FUT009','model',o,dict(state_best=[6,8],direct_regret=[0,18],staged_regret=[4,0],direct_worst=26,staged_worst=10,direct_max_regret=18,staged_max_regret=4),m['expected_calculations'])
        c=m['negative_control']; worst=max(c['faulty_gate_staged_loss'])
        self.observe('FUT009','negative',worst,30,c['expected_worst']); self.assertGreater(worst,max(direct))


if __name__ == '__main__':
    unittest.main()
