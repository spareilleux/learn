"""Independent characterizations of C16 finite teaching cases, not engine trials."""
import itertools
import json
import math
from fractions import Fraction
from pathlib import Path
import unittest

PACKET_PATH = Path(__file__).resolve().parents[1] / 'unit-c.json'
COURSES = {c['code']: c for c in json.loads(PACKET_PATH.read_text(encoding='utf-8'))['courses']}
SCOPE = 'Authored finite model/control only; no physical, scene, human, learner or production acceptance.'


def q(x):
    return Fraction(str(x))


def require(ok, diagnostic):
    if not ok:
        raise ValueError(diagnostic)


def calculate(code, v):
    """Use inputs only. No packet expected field participates in a calculation."""
    if code == 'PHY022':
        m, rho, volume, g = [q(v[k]) for k in ('mass_kg', 'fluid_density_kg_m3', 'sealed_volume_m3', 'g_m_s2')]
        require(all(x > 0 for x in (m, rho, volume, g)), 'positive mass, fluid density, sealed volume and gravity required')
        weight, buoyancy, displacement = m*g, rho*g*volume, m/rho
        return dict(weight_N=float(weight), maximum_buoyancy_N=float(buoyancy), required_displacement_m3=float(displacement), required_fraction=float(displacement/volume), feasible=displacement <= volume, full_submersion_net_N=float(buoyancy-weight))
    if code == 'PHY023':
        hold, mu, angle, load = [float(v[k]) for k in ('hold_N', 'mu', 'wrap_rad', 'load_N')]
        require(0 < hold <= load and mu >= 0 and angle >= 0, 'positive lower holding tension, higher load, nonnegative friction and radians required')
        ratio = math.exp(mu*angle)
        capacity = hold*ratio
        return dict(ratio=ratio, capacity_N=capacity, reserve_N=capacity-load, feasible=load <= capacity)
    if code == 'PHY024':
        ds, ks = v['thickness_m'], v['conductivity_W_mK']
        require(len(ds) == len(ks) and len(ds) > 0, 'one conductivity per nonempty layer; unequal lengths cannot be truncated')
        ds, ks = list(map(q, ds)), list(map(q, ks))
        area, delta = q(v['area_m2']), q(v['delta_K'])
        require(area > 0 and all(d > 0 for d in ds) and all(k > 0 for k in ks), 'positive slab thicknesses, conductivities and common area required')
        rs = [ds[i]/(ks[i]*area) for i in range(len(ds))]
        total = sum(rs)
        power = delta/total
        return dict(resistances_K_W=list(map(float, rs)), total_K_W=float(total), power_W=float(power), drops_K=[float(power*r) for r in rs])
    if code == 'VC020':
        arrays = [v[k] for k in ('minimum', 'maximum', 'origin', 'direction')]
        require(all(len(a) == 3 for a in arrays), 'four three-coordinate box/ray vectors required')
        lower, upper, origin, direction = [list(map(q, a)) for a in arrays]
        limit = q(v['t_max'])
        require(all(lower[i] <= upper[i] for i in range(3)) and any(direction) and limit >= 0, 'ordered closed box, nonzero ray direction and forward limit required')
        enter, leave = Fraction(0), limit
        miss = dict(hit=False, t_enter=None, t_exit=None)
        for i in range(3):
            if direction[i] == 0:
                if not lower[i] <= origin[i] <= upper[i]:
                    return miss
            else:
                a, b = sorted(((lower[i]-origin[i])/direction[i], (upper[i]-origin[i])/direction[i]))
                enter, leave = max(enter, a), min(leave, b)
                if enter > leave:
                    return miss
        return dict(hit=True, t_enter=float(enter), t_exit=float(leave))
    if code == 'VC021':
        require(len(v['vector']) == 3 and type(v['fold_lower']) is bool, 'three-vector and Boolean fold selection required')
        original = list(map(q, v['vector']))
        require(any(original), 'normal direction must be nonzero')
        x, y, z = [a/sum(map(abs, original)) for a in original]
        sign = lambda a: 1 if a >= 0 else -1  # Declared sign(0)=1.
        if z < 0 and v['fold_lower']:
            x, y = (1-abs(y))*sign(x), (1-abs(x))*sign(y)
        encoded = [float(x), float(y)]
        z = 1-abs(x)-abs(y)
        if z < 0:
            x, y = (1-abs(y))*sign(x), (1-abs(x))*sign(y)
        length = math.sqrt(x*x+y*y+z*z)
        normal = [float(a)/length for a in (x, y, z)]
        original_length = math.sqrt(sum(a*a for a in original))
        agreement = sum(normal[i]*float(original[i])/original_length for i in range(3))
        return dict(encoded=encoded, decoded_normal=normal, agreement=agreement)
    if code == 'VC022':
        require(len(v['point']) == len(v['light_travel']) == 3, 'point and light-travel direction must each have three coordinates')
        point, direction = list(map(q, v['point'])), list(map(q, v['light_travel']))
        require(any(direction), 'light-travel vector must be nonzero')
        if direction[2] == 0:
            require(point[2] != q(v['plane_z']), 'this finite parallel control is off the receiver plane')
            return dict(status='parallel', t=None, intersection=None)
        t = (q(v['plane_z'])-point[2])/direction[2]
        if t < 0:
            return dict(status='behind', t=None, intersection=None)
        return dict(status='hit', t=float(t), intersection=[float(point[i]+t*direction[i]) for i in range(3)])
    if code == 'DV020':
        edges, counts = list(map(q, v['edges_mm'])), list(map(q, v['counts']))
        require(len(edges) == len(counts)+1 and len(counts) > 0, 'bin edges need exactly one more value than nonempty counts')
        widths = [edges[i+1]-edges[i] for i in range(len(counts))]
        total = sum(counts)
        require(all(w > 0 for w in widths) and all(c >= 0 for c in counts) and total > 0, 'increasing edges, nonnegative counts and positive denominator required')
        densities = [counts[i]/(total*widths[i]) for i in range(len(counts))]
        return dict(widths_mm=list(map(float, widths)), sample_count=float(total), density_per_mm=list(map(float, densities)), areas=[float(densities[i]*widths[i]) for i in range(len(counts))])
    if code == 'DV021':
        require(v['transform'] == 'sqrt', 'only the declared square-root display map is supported')
        centre, lo, hi = [q(v[k]) for k in ('centre', 'lower', 'upper')]
        require(0 <= lo <= centre <= hi, 'ordered nonnegative feasible endpoints enclosing the centre required')
        c, a, b = map(math.sqrt, (centre, lo, hi))
        return dict(display_centre=c, display_lower=a, display_upper=b, lower_extent=c-a, upper_extent=b-c)
    if code == 'DV022':
        corners = v['corners_TL_TR_BR_BL']
        require(len(corners) == 4 and type(v['connect_high']) is bool, 'four cyclic TL/TR/BR/BL corners and Boolean connectivity required')
        corners, threshold = list(map(q, corners)), q(v['threshold'])
        high = [c > threshold for c in corners]
        require(all(c != threshold for c in corners) and all(high[i] != high[(i+1)%4] for i in range(4)), 'this finite case requires strictly alternating corner classes, with no threshold ties')
        fractions = [(threshold-corners[i])/(corners[(i+1)%4]-corners[i]) for i in range(4)]
        isolated_tl_br = high[0] != v['connect_high']
        pairs = [['top','left'],['right','bottom']] if isolated_tl_br else [['top','right'],['bottom','left']]
        # Independent corner-region graph for the component counts.
        parents = list(range(4))
        connected = [i for i in range(4) if high[i] == v['connect_high']]
        parents[connected[1]] = connected[0]
        n_high = len({parents[i] for i in range(4) if high[i]})
        n_low = len({parents[i] for i in range(4) if not high[i]})
        return dict(ambiguous=True, edge_fractions=list(map(float, fractions)), pairs=pairs, high_components=n_high, low_components=n_low)
    if code == 'SEM018':
        threading, lifts = v['threading'], v['lift_plan']
        require(len(threading) > 0 and len(lifts) > 0 and all(type(x) is int and x >= 0 for x in threading), 'nonempty integer shaft threading and picks required')
        shafts = set(threading)
        require(all(row is None or (isinstance(row,list) and len(row) == len(set(row)) and all(type(x) is int and x in shafts for x in row)) for row in lifts), 'lift rows must be missing or distinct declared integer shaft labels')
        rows = [None if row is None else [shaft in row for shaft in threading] for row in lifts]
        return dict(status='incomplete' if any(row is None for row in rows) else 'complete', drawdown=rows)
    if code == 'SEM019':
        overs, unders = v['over_tangents'], v['under_tangents']
        require(len(overs) == len(unders) and len(overs) > 0 and all(len(p) == 2 for p in overs+unders), 'equal nonempty ordered crossing lists with two-component tangents required')
        require(v['operation'] in ('reverse','mirror'), 'declared operation must be reverse or mirror')
        def signs(a, b):
            determinants = [q(a[i][0])*q(b[i][1])-q(a[i][1])*q(b[i][0]) for i in range(len(a))]
            require(all(d != 0 for d in determinants), 'crossing determinants must be nonzero')
            return [1 if d > 0 else -1 for d in determinants]
        original = signs(overs, unders)
        factors = [-1,-1] if v['operation'] == 'reverse' else [-1,1]
        moved = [[[factors[i]*p[i] for i in range(2)] for p in group] for group in (overs, unders)]
        transformed = signs(*moved)
        return dict(original_signs=original, original_writhe=sum(original), transformed_signs=transformed, transformed_writhe=sum(transformed))
    if code == 'SEM020':
        runs, indices, phase = v['runs'], v['indices'], v['phase']
        require(len(runs) > 0 and all(isinstance(r,list) and len(r) == 2 and isinstance(r[0],str) for r in runs), 'nonempty symbol/length run pairs required')
        require(type(phase) is int and all(type(i) is int for i in indices), 'integer phase and cell addresses required')
        if any(type(r[1]) is not int or r[1] <= 0 for r in runs):
            return dict(status='invalid_run', period=None, samples=None)
        # Explicit expansion independently checks cumulative-end lookup for this small case.
        expanded = [symbol for symbol,length in runs for _ in range(length)]
        return dict(status='valid', period=len(expanded), samples=[expanded[(i+phase)%len(expanded)] for i in indices])
    if code == 'PHI014':
        rows, selection = v['rows_A_B_mass'], v['selection']
        require(selection in ('A_or_B','all'), 'selection must be the declared disjunction or all rows')
        require(len(rows) > 0 and all(len(row) == 3 and type(row[0]) is int and type(row[1]) is int and row[0] in (0,1) and row[1] in (0,1) and q(row[2]) >= 0 for row in rows), 'weighted binary A/B row triples required')
        def rate(source, a):
            denominator = sum(q(row[2]) for row in source if row[0] == a)
            require(denominator > 0, 'each conditional stratum needs positive mass')
            return sum(q(row[2])*row[1] for row in source if row[0] == a)/denominator
        retained = rows if selection == 'all' else [r for r in rows if r[0] or r[1]]
        r0, r1 = rate(retained,0), rate(retained,1)
        return dict(retained_mass=float(sum(q(r[2]) for r in retained)), B_given_A0=float(r0), B_given_A1=float(r1), difference=float(r1-r0), unselected_difference=float(rate(rows,1)-rate(rows,0)))
    if code == 'PHI015':
        prediction, auxiliary = v['observed_prediction'], v['auxiliary_verified']
        require(type(prediction) is bool and (auxiliary is None or type(auxiliary) is bool), 'Boolean prediction and optional Boolean auxiliary observation required')
        worlds = [[h,a] for h,a in itertools.product((False,True),repeat=2) if (h and a) == prediction and (auxiliary is None or a == auxiliary)]
        require(bool(worlds), 'entailment needs a nonempty compatible world set')
        return dict(worlds=worlds, count=len(worlds), H_false_entailed=all(not h for h,a in worlds))
    if code == 'FUT014':
        cohorts, ages, horizon = list(map(q,v['introduced_by_period'])), v['retirement_age_mass'], v['output_periods']
        require(cohorts and all(c >= 0 for c in cohorts) and type(horizon) is int and horizon > 0, 'nonnegative original cohort masses and positive integer output horizon required')
        require(ages and all(k.isdigit() and int(k)>0 and q(m)>=0 for k,m in ages.items()) and sum(map(q, ages.values())) == 1, 'positive integer ages and normalized nonnegative retirement allocation required')
        schedule = [Fraction(0) for _ in range(horizon)]
        for cohort,mass in enumerate(cohorts):
            for age,share in ages.items():
                t = cohort+int(age)
                require(t < horizon or mass*q(share) == 0, 'declared complete schedule must include all positive allocated retirements')
                if t < horizon:
                    schedule[t] += mass*q(share)
        peak = max(schedule)
        return dict(first_retirements=list(map(float,schedule)), total=float(sum(schedule)), peak_period=schedule.index(peak), peak_mass=float(peak))
    if code == 'FUT015':
        features = v['features']
        require(features and len(features) == len(set(features)) and all(isinstance(f,str) for f in features), 'distinct ordered feature names required')
        requirements, conflicts = v['requirements'], v['forbidden_together']
        require(all(len(pair) == 2 and all(name in features for name in pair) for pair in requirements+conflicts), 'compatibility pairs must name exactly two declared features')
        compatible, incompatible = [], []
        for bits in itertools.product((0,1), repeat=len(features)):
            state = {features[i]: bits[i] for i in range(len(features))}
            ok = all(not state[a] or state[b] for a,b in requirements) and all(not (state[a] and state[b]) for a,b in conflicts)
            (compatible if ok else incompatible).append(''.join(map(str,bits)))
        return dict(compatible=compatible, count=len(compatible), incompatible=incompatible)
    raise ValueError('unassigned course '+code)


class UnitC(unittest.TestCase):
    def equal_tree(self, observed, expected):
        if isinstance(expected,dict):
            self.assertIsInstance(observed,dict)
            self.assertEqual(set(observed),set(expected))
            for key in expected:
                self.equal_tree(observed[key],expected[key])
        elif isinstance(expected,list):
            self.assertIsInstance(observed,list)
            self.assertEqual(len(observed),len(expected))
            for i in range(len(expected)):
                self.equal_tree(observed[i],expected[i])
        elif isinstance(expected,bool) or expected is None:
            self.assertIs(observed,expected)
        elif isinstance(expected,(int,float)):
            self.assertNotIsInstance(observed,bool)
            self.assertTrue(math.isclose(observed,expected,rel_tol=1e-11,abs_tol=1e-11),(observed,expected))
        else:
            self.assertEqual(observed,expected)

    def check_course(self, code, model, negative, course=None):
        packet = (COURSES[code] if course is None else course)['authored_model']
        for case,p,fixed in (('model',packet,model),('negative',packet['negative_control'],negative)):
            try:
                observed = calculate(code,p['values'])
            except (ValueError,KeyError,TypeError,ZeroDivisionError,OverflowError) as error:
                observed = dict(diagnostic=str(error))
            print('\nOBSERVATION '+json.dumps(dict(code=code,case=case,observed=observed,expected=fixed,scope=SCOPE),sort_keys=True),flush=True)
            self.equal_tree(observed,fixed)
            self.equal_tree(p['expected'],fixed)

    def test_phy022(self):
        self.check_course('PHY022',dict(weight_N=6,maximum_buoyancy_N=10,required_displacement_m3=.0006,required_fraction=.6,feasible=True,full_submersion_net_N=4),dict(weight_N=12,maximum_buoyancy_N=10,required_displacement_m3=.0012,required_fraction=1.2,feasible=False,full_submersion_net_N=-2))
    def test_phy023(self):
        self.check_course('PHY023',dict(ratio=2.718281828459045,capacity_N=5.43656365691809,reserve_N=1.43656365691809,feasible=True),dict(ratio=1,capacity_N=2,reserve_N=-2,feasible=False))
    def test_phy024(self):
        self.check_course('PHY024',dict(resistances_K_W=[1/5,1/25],total_K_W=6/25,power_W=125,drops_K=[25,5]),dict(resistances_K_W=[1/5,1/5],total_K_W=2/5,power_W=75,drops_K=[15,15]))
    def test_vc020(self):
        self.check_course('VC020',dict(hit=True,t_enter=2,t_exit=4),dict(hit=False,t_enter=None,t_exit=None))
    def test_vc021(self):
        self.check_course('VC021',dict(encoded=[.5,.75],decoded_normal=[1/math.sqrt(6),2/math.sqrt(6),-1/math.sqrt(6)],agreement=1),dict(encoded=[.25,.5],decoded_normal=[1/math.sqrt(6),2/math.sqrt(6),1/math.sqrt(6)],agreement=2/3))
    def test_vc022(self):
        self.check_course('VC022',dict(status='hit',t=2,intersection=[4,3,0]),dict(status='parallel',t=None,intersection=None))
    def test_dv020(self):
        self.check_course('DV020',dict(widths_mm=[1,2],sample_count=8,density_per_mm=[1/2,1/4],areas=[1/2,1/2]),dict(widths_mm=[1,2],sample_count=12,density_per_mm=[1/3,1/3],areas=[1/3,2/3]))
    def test_dv021(self):
        self.check_course('DV021',dict(display_centre=2,display_lower=1,display_upper=3,lower_extent=1,upper_extent=1),dict(display_centre=2,display_lower=0,display_upper=math.sqrt(8),lower_extent=2,upper_extent=math.sqrt(8)-2))
    def test_dv022(self):
        self.check_course('DV022',dict(ambiguous=True,edge_fractions=[.5,.5,.5,.5],pairs=[['top','left'],['right','bottom']],high_components=2,low_components=1),dict(ambiguous=True,edge_fractions=[.5,.5,.5,.5],pairs=[['top','right'],['bottom','left']],high_components=1,low_components=2))
    def test_sem018(self):
        self.check_course('SEM018',dict(status='complete',drawdown=[[True,False,True,True],[False,True,False,False],[True,True,False,True]]),dict(status='incomplete',drawdown=[[True,False,True,True],[False,True,False,False],None]))
    def test_sem019(self):
        self.check_course('SEM019',dict(original_signs=[1,-1,1],original_writhe=1,transformed_signs=[1,-1,1],transformed_writhe=1),dict(original_signs=[1,-1,1],original_writhe=1,transformed_signs=[-1,1,-1],transformed_writhe=-1))
    def test_sem020(self):
        self.check_course('SEM020',dict(status='valid',period=6,samples=['warp','weft','warp','warp','weft']),dict(status='invalid_run',period=None,samples=None))
    def test_phi014(self):
        self.check_course('PHI014',dict(retained_mass=3,B_given_A0=1,B_given_A1=1/2,difference=-1/2,unselected_difference=0),dict(retained_mass=4,B_given_A0=1/2,B_given_A1=1/2,difference=0,unselected_difference=0))
    def test_phi015(self):
        self.check_course('PHI015',dict(worlds=[[False,False],[False,True],[True,False]],count=3,H_false_entailed=False),dict(worlds=[[False,True]],count=1,H_false_entailed=True))
    def test_fut014(self):
        self.check_course('FUT014',dict(first_retirements=[0,0,1,2.5,2,.5,0],total=6,peak_period=3,peak_mass=2.5),dict(first_retirements=[0,2,3,1,0,0,0],total=6,peak_period=2,peak_mass=3))
    def test_fut015(self):
        self.check_course('FUT015',dict(compatible=['000','010','011','110','111'],count=5,incompatible=['001','100','101']),dict(compatible=['000','010','011','110'],count=4,incompatible=['001','100','101','111']))


if __name__ == '__main__':
    unittest.main()
