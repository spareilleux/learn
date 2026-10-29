"""Independent finite characterizations of UNIT C; no production behavior changes."""
import copy
import itertools
import json
import math
from collections import Counter
from fractions import Fraction
from pathlib import Path
import unittest

PACKET_PATH = Path(__file__).resolve().parents[1] / 'unit-c.json'
COURSES = {c['code']: c for c in json.loads(PACKET_PATH.read_text(encoding='utf-8'))['courses']}
SCOPE = 'Authored finite model/control only; no scene, physical, musician, human, learner or production acceptance.'


def q(value):
    return Fraction(str(value))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def calculate(code, v):
    """Narrow evaluators consume packet inputs, never packet expected results."""
    if code == 'DV023':
        xs, scale = v['clearance'], float(v['scale'])
        require(xs and math.isfinite(scale) and scale > 0 and all(math.isfinite(x) for x in xs), 'finite clearances and positive finite scale required')
        positions = [math.copysign(math.log1p(abs(x)/scale), x) if x else 0.0 for x in xs]
        recovered = [math.copysign(scale*math.expm1(abs(y)), y) if y else 0.0 for y in positions]
        return dict(positions=positions, roundtrip=recovered)
    if code == 'DV024':
        rows = v['endpoints']
        require(len(rows) == 2 and len(rows[0]) >= 2 and len(rows[0]) == len(rows[1]), 'two equal nonempty cumulative stage arrays with baselines required')
        rows = [list(map(q, row)) for row in rows]
        require(all(row[0] == 0 and all(row[j+1] >= row[j] for j in range(len(row)-1)) for row in rows), 'zero baselines and nondecreasing common-unit endpoints required')
        layers = [[row[j+1]-row[j] for j in range(len(row)-1)] for row in rows]
        return dict(layers=[[float(x) for x in row] for row in layers], equal_totals=rows[0][-1] == rows[1][-1], equal_last_layers=layers[0][-1] == layers[1][-1])
    if code == 'DV025':
        fg, bg, threshold = [q(v[k]) for k in ('foreground_luminance', 'background_luminance', 'threshold')]
        require(0 <= fg <= 1 and 0 <= bg <= 1 and threshold > 0, 'linear relative luminances in [0,1] and positive threshold required')
        ratio = (max(fg,bg)+Fraction(1,20))/(min(fg,bg)+Fraction(1,20))
        return dict(ratio=float(ratio), passes=ratio >= threshold)
    if code == 'FUT016':
        initial, capacity = q(v['initial']), q(v['capacity'])
        growth, last = list(map(q,v['growth_bounds'])), v['last_period']
        require(initial > 0 and capacity > 0 and len(growth) == 2 and 0 < growth[0] <= growth[1] and type(last) is int and last >= 0, 'positive ordered endpoint growths, initial inventory/capacity and finite nonnegative integer horizon required')
        paths = [[initial*g**t for t in range(last+1)] for g in growth]
        crossings = [next((t for t,load in enumerate(path) if load >= capacity),None) for path in paths]
        present = [t for t in crossings if t is not None]
        return dict(paths=[[float(x) for x in path] for path in paths], crossings=crossings, earliest=min(present) if present else None, latest=max(crossings) if len(present) == len(crossings) else None)
    if code == 'FUT017':
        first, ratio = q(v['first_cost']), float(v['doubling_ratio'])
        units = v['units']
        require(first > 0 and math.isfinite(ratio) and ratio > 0 and units and all(type(n) is int and n > 0 for n in units) and len(set(units)) == len(units), 'positive unit cost, ratio and distinct positive integer unit indexes required')
        exponent = math.log2(ratio)
        costs = [float(first)*n**exponent for n in units]
        total = math.fsum(costs)
        return dict(exponent=exponent, unit_costs=costs, total=total, average=total/len(units))
    if code == 'FUT018':
        demands, probabilities = list(map(q,v['demands'])), list(map(q,v['probabilities']))
        reserves, capacity, limit = list(map(q,v['reserves'])), q(v['base_capacity']), q(v['maximum_exceedance'])
        require(len(demands) == len(probabilities) and demands and all(p >= 0 for p in probabilities) and sum(probabilities) == 1, 'each demand needs one normalized nonnegative probability; unequal arrays cannot be truncated')
        require(capacity >= 0 and all(d >= 0 for d in demands) and reserves and all(r >= 0 for r in reserves) and len(set(reserves)) == len(reserves) and 0 <= limit <= 1, 'nonnegative demand/capacity and distinct candidate reserves with probability limit required')
        exceedance = [sum(probabilities[i] for i in range(len(demands)) if demands[i] > capacity+r) for r in reserves]
        passing = [reserves[i] for i in range(len(reserves)) if exceedance[i] <= limit]
        return dict(exceedance=list(map(float,exceedance)), passing_reserves=list(map(float,passing)), chosen_reserve=float(min(passing)) if passing else None)
    if code == 'FUT019':
        baseline, capacity = q(v['base_load']), q(v['capacity'])
        increments = {k:q(x) for k,x in v['increments'].items()}
        require(increments and baseline >= 0 and capacity >= 0 and all(x >= 0 for x in increments.values()), 'nonnegative additive stresses, baseline and capacity required')
        names = sorted(increments)
        subsets = [s for n in range(len(names)+1) for s in itertools.combinations(names,n)]
        overloaded = [s for s in subsets if baseline+sum(increments[k] for k in s) > capacity]
        minimal = sorted(s for s in overloaded if not any(set(t) < set(s) for t in overloaded))
        return dict(minimal_overloads=[list(s) for s in minimal], loads=[float(baseline+sum(increments[k] for k in s)) for s in minimal])
    if code == 'GAA020':
        positions = {k:q(x) for k,x in v['positions'].items()}
        k = v['centres_required']
        require(type(k) is int and 1 <= k <= len(positions), 'positive centre budget no larger than the candidate set required')
        radii = [(s,max(min(abs(x-positions[c]) for c in s) for x in positions.values())) for s in itertools.combinations(sorted(positions),k)]
        best = min(radius for s,radius in radii)
        return dict(best_radius=float(best), optimal_centres=[list(s) for s,radius in radii if radius == best])
    if code == 'GAA021':
        target, attempt = v['target'], v['attempt']
        require(all(type(x) is int and 0 <= x <= 127 for x in target+attempt), 'MIDI integer note sequences required')
        table = [[0]*(len(attempt)+1) for _ in range(len(target)+1)]
        for i in range(len(target)+1):
            table[i][0] = i
        for j in range(len(attempt)+1):
            table[0][j] = j
        for i in range(1,len(target)+1):
            for j in range(1,len(attempt)+1):
                table[i][j] = min(table[i-1][j]+1,table[i][j-1]+1,table[i-1][j-1]+int(target[i-1] != attempt[j-1]))
        return dict(table=table, distance=table[-1][-1])
    if code == 'GAA022':
        target, attempt = list(map(q,v['target_ioi'])), list(map(q,v['attempt_ioi']))
        require(len(target) == len(attempt) and target and all(x > 0 for x in target+attempt), 'equal nonempty positive IOI vectors required; no truncation')
        a,b = [x/sum(target) for x in target], [x/sum(attempt) for x in attempt]
        errors = [abs(a[i]-b[i]) for i in range(len(a))]
        return dict(target_normalized=list(map(float,a)), attempt_normalized=list(map(float,b)), errors=list(map(float,errors)), shape_L1=float(sum(errors)), duration_ratio=float(sum(attempt)/sum(target)))
    if code == 'PHI016':
        order, p, other = v['order'], v['p'], v['q']
        require(order == ['F','U','T'] and p in order and other in order, 'declared strong Kleene order F<U<T and values required')
        a,b = order.index(p),order.index(other)
        negated = order[len(order)-1-a]
        return {'and':order[min(a,b)],'or':order[max(a,b)],'not_p':negated,'excluded_middle':order[max(a,order.index(negated))]}
    if code == 'PHI017':
        facts, rule, default = set(v['facts']), v['strict_rule'], v['normal_default']
        require(len(rule) == 2 and all(isinstance(x,str) for x in rule) and set(default) == {'prerequisite','justification','conclusion'}, 'one strict literal implication and one default triple required')
        require(default['justification'] == default['conclusion'] and not default['justification'].startswith('not_'), 'sole positive normal default required, not a general extension solver')
        if rule[0] in facts:
            facts.add(rule[1])
        require(not any('not_'+x in facts for x in facts if not x.startswith('not_')), 'consistent strict facts required')
        fired = default['prerequisite'] in facts and 'not_'+default['justification'] not in facts
        if fired:
            facts.add(default['conclusion'])
        return dict(literals=sorted(facts), default_fired=fired)
    if code == 'PHI018':
        arguments, pairs = v['arguments'], v['attacks']
        require(arguments and len(arguments) == len(set(arguments)) and all(len(pair) == 2 and all(x in arguments for x in pair) for pair in pairs), 'distinct arguments and directed attack pairs within their domain required')
        attacks = set(map(tuple,pairs))
        current, iterations = set(), [[]]
        while True:
            defended = {a for a in arguments if all(any((s,b) in attacks for s in current) for b in arguments if (b,a) in attacks)}
            iterations.append(sorted(defended))
            if defended == current:
                break
            current = defended
        out = {a for a in arguments if any((s,a) in attacks for s in current)}
        return dict(iterations=iterations, grounded=sorted(current), out=sorted(out), undecided=sorted(set(arguments)-current-out))
    if code == 'SEM021':
        derivations, valuation = v['derivations'], v['valuation']
        require(derivations and all(row and all(isinstance(t,str) and t.isidentifier() and t in valuation for t in row) for row in derivations), 'nonempty source-token products with defined valuations required')
        require(all(type(x) is int and x >= 0 for x in valuation.values()), 'natural-number valuation required for this multiplicity case')
        counts = Counter('*'.join(sorted(row)) for row in derivations)
        multiplicity = sum(math.prod(valuation[t] for t in row) for row in derivations)
        return dict(coefficients=dict(sorted(counts.items())), evaluated_multiplicity=multiplicity)
    if code == 'SEM022':
        original = copy.deepcopy(v['original'])
        mode, mutation = v['copy_mode'], v['mutation']
        require(original and all(isinstance(row,list) for row in original) and mode in ('shallow','deep'), 'simple list-of-lists and declared shallow/deep mode required')
        row,column = mutation['row'],mutation['column']
        require(type(row) is int and type(column) is int and 0 <= row < len(original) and 0 <= column < len(original[row]), 'mutation must address an existing nested element')
        copied = copy.copy(original) if mode == 'shallow' else copy.deepcopy(original)
        copied[row][column] = mutation['value']
        return dict(original_after=original, copy_after=copied, same_outer=original is copied, same_first_child=original[0] is copied[0])
    if code == 'SEM023':
        arrays = [v[k] for k in ('p','q','translation')]
        require(all(len(a) == 3 for a in arrays), 'two points and one translation must each have three coordinates')
        p,other,translation = [list(map(q,a)) for a in arrays]
        pw,qw = [p[i]+translation[i] for i in range(3)], [other[i]+translation[i] for i in range(3)]
        return dict(p_world=list(map(float,pw)), q_world=list(map(float,qw)), displacement=[float(other[i]-p[i]) for i in range(3)], translated_difference=[float(qw[i]-pw[i]) for i in range(3)])
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

    def test_dv023(self):
        # log(4), log(2), and log(4/3), independently from the declared magnitudes/scales.
        self.check_course('DV023',dict(positions=[-math.log(4),-math.log(2),0,math.log(2),math.log(4)],roundtrip=[-3,-1,0,1,3]),dict(positions=[-math.log(2),-math.log(4/3),0,math.log(4/3),math.log(2)],roundtrip=[-3,-1,0,1,3]))
    def test_dv024(self):
        self.check_course('DV024',dict(layers=[[2,6],[5,3]],equal_totals=True,equal_last_layers=False),dict(layers=[[2,6],[5,6]],equal_totals=False,equal_last_layers=True))
    def test_dv025(self):
        self.check_course('DV025',dict(ratio=21/5,passes=False),dict(ratio=7,passes=True))
    def test_fut016(self):
        paths = [[8,10,25/2,125/8,625/32],[8,12,18,27,81/2]]
        self.check_course('FUT016',dict(paths=paths,crossings=[4,2],earliest=2,latest=4),dict(paths=paths,crossings=[None,None],earliest=None,latest=None))
    def test_fut017(self):
        self.check_course('FUT017',dict(exponent=-1,unit_costs=[16,8,16/3,4],total=100/3,average=25/3),dict(exponent=0,unit_costs=[16,16,16,16],total=64,average=16))
    def test_fut018(self):
        self.check_course('FUT018',dict(exceedance=[1/5,1/5,0],passing_reserves=[4],chosen_reserve=4),dict(exceedance=[1/5,1/5,0],passing_reserves=[0,2,4],chosen_reserve=0))
    def test_fut019(self):
        self.check_course('FUT019',dict(minimal_overloads=[['A','B']],loads=[11]),dict(minimal_overloads=[['A','B'],['A','C'],['B','C']],loads=[11,9,9]))
    def test_gaa020(self):
        # The six pair radii AB,AC,AD,BC,BD,CD are 6,3,3,3,3,5.
        self.check_course('GAA020',dict(best_radius=3,optimal_centres=[['A','C'],['A','D'],['B','C'],['B','D']]),dict(best_radius=5,optimal_centres=[['C']]))
    def test_gaa021(self):
        self.check_course('GAA021',dict(table=[[0,1,2,3,4],[1,0,1,2,3],[2,1,1,1,2],[3,2,2,2,1]],distance=1),dict(table=[[0,1,2,3],[1,1,2,2],[2,2,1,2],[3,2,2,2]],distance=2))
    def test_gaa022(self):
        self.check_course('GAA022',dict(target_normalized=[1/4,1/2,1/4],attempt_normalized=[1/4,1/2,1/4],errors=[0,0,0],shape_L1=0,duration_ratio=2),dict(target_normalized=[1/4,1/2,1/4],attempt_normalized=[1/4,3/8,3/8],errors=[0,1/8,1/8],shape_L1=1/4,duration_ratio=2))
    def test_phi016(self):
        self.check_course('PHI016',{'and':'F','or':'U','not_p':'U','excluded_middle':'U'},{'and':'U','or':'T','not_p':'U','excluded_middle':'U'})
    def test_phi017(self):
        self.check_course('PHI017',dict(literals=['asset','usable'],default_fired=True),dict(literals=['asset','fragile','not_usable'],default_fired=False))
    def test_phi018(self):
        self.check_course('PHI018',dict(iterations=[[],['A'],['A','C'],['A','C']],grounded=['A','C'],out=['B'],undecided=[]),dict(iterations=[[],[]],grounded=[],out=[],undecided=['A','B','C']))
    def test_sem021(self):
        self.check_course('SEM021',dict(coefficients={'a*b':2,'c':1},evaluated_multiplicity=2),dict(coefficients={'a*b':1,'c':1},evaluated_multiplicity=1))
    def test_sem022(self):
        self.check_course('SEM022',dict(original_after=[[9,2],[3]],copy_after=[[9,2],[3]],same_outer=False,same_first_child=True),dict(original_after=[[1,2],[3]],copy_after=[[9,2],[3]],same_outer=False,same_first_child=False))
    def test_sem023(self):
        self.check_course('SEM023',dict(p_world=[11,0,5],q_world=[14,4,5],displacement=[3,4,0],translated_difference=[3,4,0]),dict(p_world=[-4,10,1],q_world=[-1,14,1],displacement=[3,4,0],translated_difference=[3,4,0]))


if __name__ == '__main__':
    unittest.main()
