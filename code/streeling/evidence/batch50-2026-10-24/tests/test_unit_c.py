"""Independent finite-model checks. No engine, physical or learner trial."""
import json
import math
from pathlib import Path
import unittest

PACKET_PATH = Path(__file__).resolve().parents[1] / 'unit-c.json'
PACKET = json.loads(PACKET_PATH.read_text(encoding='utf-8'))
COURSES = {c['code']: c for c in PACKET['courses']}
SCOPE = 'Authored finite classroom inputs only; no physical, image, engine, material, scene or learner observation.'


def calculate(code, v):
    """Compute from actual input fields; never read packet expected outputs."""
    if code == 'PHY016':
        r, a = v['radius_mm'], math.radians(v['angle_deg'])
        x, y = r * math.cos(a), r * math.sin(a)
        return dict(endpoint_mm=[x, y], swept_displacement_mm=math.hypot(x-r, y),
                    radial_margin_mm=r-v['obstacle_radius_mm'])
    if code == 'PHY017':
        growth = v['length_mm'] * v['alpha_per_K'] * v['delta_K']
        return dict(growth_mm=growth, remaining_gap_mm=v['gap_mm']-growth)
    if code == 'PHY018':
        center = sum(m*x for m, x in zip(v['masses_kg'], v['x_m']))/sum(v['masses_kg'])
        lo, hi = v['support_m']
        return dict(x_cm_m=center, margin_m=min(center-lo, hi-center), inside_support=lo <= center <= hi)
    if code == 'VC014':
        f = v['viewport_height_px']/2/math.tan(math.radians(v['vertical_fov_deg'])/2)
        width = f*v['width_m']/v['distance_m']
        return dict(focal_px=f, width_px=width, meets_declared_threshold=width >= v['required_px'])
    if code == 'VC015':
        r, n = v['radius_mm'], v['segments']
        error = r*(1-math.cos(math.pi/n))
        return dict(sagitta_mm=error, perimeter_mm=2*n*r*math.sin(math.pi/n), acceptable=error <= v['tolerance_mm'])
    if code == 'VC016':
        gutter = v['gutter_px']/2**v['mip_level']
        return dict(effective_gutter_px=gutter, meets_declared_margin=gutter >= v['required_gutter_px'])
    if code == 'DV014':
        a = v['clearance_mm']
        return dict(minimum_mm=min(a), overlap_count=sum(x < 0 for x in a), contact_count=a.count(0), mean_absolute_mm=sum(map(abs, a))/len(a))
    if code == 'DV015':
        a = v['observed_stitch']
        assert len(a) == v['grid_width']*v['grid_height']
        seen = sum(x is not None for x in a)
        absent = sum(x is False for x in a)
        return dict(observed=seen, present=sum(x is True for x in a), absent=absent, missing=len(a)-seen, observed_absence_fraction=absent/seen)
    if code == 'DV016':
        delta = [a-b for a, b in zip(v['after_px'], v['before_px'])]
        return dict(delta_px=delta, mean_delta_px=sum(delta)/len(delta), worst_before_px=max(v['before_px']), worst_after_px=max(v['after_px']), worsened_views=[name for name, d in zip(v['view_ids'], delta) if d > 0])
    if code == 'SEM012':
        x, y = v['point_mm']; tx, ty = v['translation_mm']
        a = math.radians(v['rotation_deg'])
        def rotate(x, y):
            return [round(x*math.cos(a)-y*math.sin(a), 12), round(x*math.sin(a)+y*math.cos(a), 12)]
        rt = rotate(x+tx, y+ty)
        rx, ry = rotate(x, y); tr = [rx+tx, ry+ty]
        return dict(rotate_after_translate_mm=rt, translate_after_rotate_mm=tr, commute=rt == tr)
    if code == 'SEM013':
        residues = [v['shift_cells'] % p for p in v['periods_cells']]
        return dict(phase_remainders=residues, compatible=all(x == 0 for x in residues), joint_period_cells=math.lcm(*v['periods_cells']))
    if code == 'SEM014':
        ab = v['base'] | v['patch_a'] | v['patch_b']
        ba = v['base'] | v['patch_b'] | v['patch_a']
        return dict(AB=ab, BA=ba, commute=ab == ba)
    if code == 'PHI010':
        a, b = v['candidate_a'], v['candidate_b']
        oa, ob = ([point[i] for i in v['projection_axes']] for point in (a, b))
        return dict(observation_a=oa, observation_b=ob, indistinguishable=oa == ob, requirement_a=a[2] == v['required_depth'], requirement_b=b[2] == v['required_depth'])
    if code == 'PHI011':
        flat, lit = v['new_flat']-v['old_flat'], v['new_lit']-v['old_lit']
        return dict(mesh_flat=flat, mesh_lit=lit, average_mesh=(flat+lit)/2, interaction=lit-flat, diagonal=v['new_lit']-v['old_flat'])
    if code == 'FUT010':
        w, f, wm, fm = (v[k] for k in ('warp_count', 'weft_count', 'warp_multiplier', 'weft_multiplier'))
        return dict(base_crossings=w*f, future_crossings=w*wm*f*fm, crossing_ratio=wm*fm, base_strands=w+f, future_strands=w*wm+f*fm, strand_ratio=(w*wm+f*fm)/(w+f))
    if code == 'FUT011':
        state, switches, states = v['initial_mesh'], 0, []
        for width in v['widths_px']:
            previous = state
            if not state and width >= v['enter_mesh_px']:
                state = True
            elif state and width < v['exit_mesh_px']:
                state = False
            states.append(state); switches += state != previous
        # Each two-state threshold transition is monotone in width, so both
        # closed endpoints enumerate its possible results exactly.
        def next_state(previous, width):
            if previous:
                return not width < v['exit_mesh_px']
            return width >= v['enter_mesh_px']
        robust = v['initial_mesh']
        reachable = {robust}
        robust_states, possible_states = [], []
        robust_switches = 0
        for lo, hi in v['width_intervals_px']:
            outcomes = {next_state(robust, w) for w in (lo, hi)}
            previous = robust
            if len(outcomes) == 1:
                robust = outcomes.pop()
            robust_states.append(robust)
            robust_switches += robust != previous
            reachable = {next_state(s, w) for s in reachable for w in (lo, hi)}
            possible_states.append(sorted(reachable))
        return dict(mesh_states=states, switches=switches,
                    robust_mesh_states=robust_states, robust_switches=robust_switches,
                    possible_mesh_states=possible_states,
                    ambiguous_samples=[i+1 for i, s in enumerate(possible_states) if len(s) > 1])
    raise ValueError(code)


class UnitC(unittest.TestCase):
    def equal_tree(self, observed, expected):
        if isinstance(expected, dict):
            self.assertEqual(set(observed), set(expected))
            for key in expected:
                self.equal_tree(observed[key], expected[key])
        elif isinstance(expected, list):
            self.assertEqual(len(observed), len(expected))
            for a, b in zip(observed, expected):
                self.equal_tree(a, b)
        elif isinstance(expected, bool):
            self.assertIs(observed, expected)
        elif isinstance(expected, (int, float)):
            self.assertTrue(math.isclose(observed, expected, rel_tol=1e-10, abs_tol=1e-10), (observed, expected))
        else:
            self.assertEqual(observed, expected)

    def check_course(self, code, model, negative, course=None):
        c = course if course is not None else COURSES[code]
        m = c['authored_model']
        for case, packet_case, fixed in (('model', m, model), ('negative', m['negative_control'], negative)):
            observed = calculate(code, packet_case['values'])
            print('OBSERVATION '+json.dumps(dict(code=code, case=case, observed=observed, expected=fixed, scope=SCOPE), sort_keys=True), flush=True)
            self.equal_tree(observed, fixed)
            self.equal_tree(packet_case['expected'], fixed)

    def test_phy016(self):
        self.check_course('PHY016', dict(endpoint_mm=[50, 50*math.sqrt(3)], swept_displacement_mm=100, radial_margin_mm=10), dict(endpoint_mm=[100, 0], swept_displacement_mm=0, radial_margin_mm=10))

    def test_phy017(self):
        self.check_course('PHY017', dict(growth_mm=.2, remaining_gap_mm=.1), dict(growth_mm=.4, remaining_gap_mm=-.1))

    def test_phy018(self):
        self.check_course('PHY018', dict(x_cm_m=.1, margin_m=.02, inside_support=True), dict(x_cm_m=.2, margin_m=-.08, inside_support=False))

    def test_vc014(self):
        self.check_course('VC014', dict(focal_px=500, width_px=1, meets_declared_threshold=False), dict(focal_px=500, width_px=2, meets_declared_threshold=True))

    def test_vc015(self):
        self.check_course('VC015', dict(sagitta_mm=3.407417371093169, perimeter_mm=621.1657082460498, acceptable=False), dict(sagitta_mm=.8555138626189618, perimeter_mm=626.5257226562476, acceptable=True))

    def test_vc016(self):
        self.check_course('VC016', dict(effective_gutter_px=2, meets_declared_margin=True), dict(effective_gutter_px=1, meets_declared_margin=False))

    def test_dv014(self):
        self.check_course('DV014', dict(minimum_mm=-.4, overlap_count=1, contact_count=1, mean_absolute_mm=.35), dict(minimum_mm=0, overlap_count=0, contact_count=1, mean_absolute_mm=.35))

    def test_dv015(self):
        self.check_course('DV015', dict(observed=5, present=3, absent=2, missing=1, observed_absence_fraction=2/5), dict(observed=6, present=3, absent=3, missing=0, observed_absence_fraction=1/2))

    def test_dv016(self):
        self.check_course('DV016', dict(delta_px=[2,-5,2], mean_delta_px=-1/3, worst_before_px=8, worst_after_px=4, worsened_views=['front','back']), dict(delta_px=[1,-4,2], mean_delta_px=-1/3, worst_before_px=8, worst_after_px=4, worsened_views=['front','back']))

    def test_sem012(self):
        self.check_course('SEM012', dict(rotate_after_translate_mm=[0,2], translate_after_rotate_mm=[1,1], commute=False), dict(rotate_after_translate_mm=[0,1], translate_after_rotate_mm=[0,1], commute=True))

    def test_sem013(self):
        self.check_course('SEM013', dict(phase_remainders=[0,0], compatible=True, joint_period_cells=6), dict(phase_remainders=[1,0], compatible=False, joint_period_cells=6))

    def test_sem014(self):
        self.check_course('SEM014', dict(AB=dict(roughness=.6,metallic=1), BA=dict(roughness=.3,metallic=1), commute=False), dict(AB=dict(roughness=.3,metallic=1), BA=dict(roughness=.3,metallic=1), commute=True))

    def test_phi010(self):
        self.check_course('PHI010', dict(observation_a=[0,0], observation_b=[0,0], indistinguishable=True, requirement_a=True, requirement_b=False), dict(observation_a=[0,0], observation_b=[1,0], indistinguishable=False, requirement_a=True, requirement_b=False))

    def test_phi011(self):
        self.check_course('PHI011', dict(mesh_flat=-2, mesh_lit=-2, average_mesh=-2, interaction=0, diagonal=2), dict(mesh_flat=-2, mesh_lit=2, average_mesh=0, interaction=4, diagonal=6))

    def test_fut010(self):
        self.check_course('FUT010', dict(base_crossings=24, future_crossings=96, crossing_ratio=4, base_strands=10, future_strands=20, strand_ratio=2), dict(base_crossings=24, future_crossings=48, crossing_ratio=2, base_strands=10, future_strands=16, strand_ratio=1.6))

    def test_fut011(self):
        self.check_course('FUT011',
            dict(mesh_states=[True,True,True,True,False,False,True], switches=3,
                 robust_mesh_states=[False,False,False,False,False,False,True], robust_switches=1,
                 possible_mesh_states=[[False,True],[False,True],[False,True],[False,True],[False,True],[False,True],[True]],
                 ambiguous_samples=[1,2,3,4,5,6]),
            dict(mesh_states=[True,False,True,False,False,False,True], switches=5,
                 robust_mesh_states=[True,True,True,False,False,False,True], robust_switches=3,
                 possible_mesh_states=[[True],[False,True],[True],[False],[False],[False],[True]],
                 ambiguous_samples=[2]))


if __name__ == '__main__':
    unittest.main()
