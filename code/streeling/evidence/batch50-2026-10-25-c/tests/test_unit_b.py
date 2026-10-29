"""Independent characterization of Unit B's sixteen finite authored cases.

No production code is introduced. Independent literals are checked before the
mutable packet expectations. Fractions remain exact except displayed real data.
"""
import copy
from fractions import Fraction as Q
import itertools as it
import json
import math
from pathlib import Path
import sys
import traceback
import unittest

PACKET = Path(__file__).resolve().parents[1] / 'unit-b.json'


def require(ok, diagnostic):
    if not ok:
        print('DIAGNOSTIC ' + json.dumps(diagnostic, default=str), flush=True)
        raise AssertionError(diagnostic)


def q(x):
    require(type(x) in (int, float, str) and not isinstance(x, bool), {'rational_input': x})
    if type(x) is float:
        require(math.isfinite(x), {'finite_input': x})
    try:
        return Q(str(x))
    except (ValueError, ZeroDivisionError):
        require(False, {'invalid_rational_input': x})


def vector(x, n=None):
    require(isinstance(x, list) and bool(x) and (n is None or len(x) == n), {'vector_shape': x, 'required_length': n})
    return [q(t) for t in x]


def numeric(x):
    if isinstance(x, Q):
        return int(x) if x.denominator == 1 else float(x)
    if isinstance(x, dict):
        return {k: numeric(v) for k, v in x.items()}
    if isinstance(x, (list, tuple)):
        return [numeric(v) for v in x]
    return x


def rational(x):
    if isinstance(x, Q):
        return str(x)
    if isinstance(x, dict):
        return {k: rational(v) for k, v in x.items()}
    if isinstance(x, (list, tuple)):
        return [rational(v) for v in x]
    return x


def rank2(m):
    require(len(m) == 2 and len(m[0]) == len(m[1]) and bool(m[0]), {'two_row_matrix': m})
    if any(m[0][i]*m[1][j] != m[0][j]*m[1][i] for i, j in it.combinations(range(len(m[0])), 2)):
        return 2
    return int(any(t for row in m for t in row))


FIELDS = {
    'COG021': 'theta items round_digits', 'COG022': 'y weights',
    'COG023': 'estimates variances covariance',
    'CYB021': 'A B initial target horizon allowed_controls',
    'CYB022': 'state desired_action action_interval next_state_upper',
    'CYB023': 'X y', 'INF022': 'prior likelihood',
    'INF023': 'blocks order erased_indices',
    'INF024': 'alphabet frequencies sequence tag',
    'NET019': 'nodes edges', 'NET020': 'nodes edges',
    'NET021': 'nodes edges root_sign', 'PM016': 'names objectives',
    'PM017': 'total_slots weights', 'PM018': 'names latency rework latency_weight',
    'PM019': 'total_samples target_weights stratum_variances',
}


def compute(code, v):
    require(set(v) == set(FIELDS[code].split()), {'code': code, 'input_fields': list(v)})
    if code == 'COG021':
        theta, digits = float(q(v['theta'])), v['round_digits']
        require(type(digits) is int and digits >= 0 and isinstance(v['items'], list) and bool(v['items']), {'item_inputs': v})
        rows = [vector(row, 2) for row in v['items']]
        require(all(a > 0 for a, b in rows), {'positive_discriminations': rows})
        probabilities = [1/(1+math.exp(-float(a)*(theta-float(b)))) for a, b in rows]
        info = [float(rows[i][0])**2 * p * (1-p) for i, p in enumerate(probabilities)]
        return dict(probabilities=[round(p, digits) for p in probabilities], information=[round(t, digits) for t in info], best_indices=[i for i, t in enumerate(info) if t == max(info)])
    if code == 'COG022':
        y = vector(v['y']); w = vector(v['weights'], len(y))
        require(all(t > 0 for t in w), {'positive_weights': v['weights']})
        # Enumerate contiguous partitions independently of the authored PAVA.
        candidates = []
        for cuts in it.product((False, True), repeat=len(y)-1):
            boundaries = [0]+[i+1 for i, cut in enumerate(cuts) if cut]+[len(y)]
            fit = []
            for j in range(len(boundaries)-1):
                start, end = boundaries[j:j+2]
                mean = sum(w[i]*y[i] for i in range(start, end))/sum(w[start:end])
                fit += [mean]*(end-start)
            if all(fit[i] <= fit[i+1] for i in range(len(y)-1)):
                candidates.append((sum(w[i]*(fit[i]-y[i])**2 for i in range(len(y))), fit))
        error, fit = min(candidates)
        return numeric(dict(fit=fit, weighted_squared_error=error))
    if code == 'COG023':
        x = vector(v['estimates'], 2); a, b = vector(v['variances'], 2); c = q(v['covariance'])
        require(a > 0 and b > 0 and a*b > c*c, {'positive_definite_covariance': v})
        # Complete the variance quadratic: coefficient a+b-2c, linear 2(c-b).
        w = (b-c)/(a+b-2*c); z = 1-w; independent = b/(a+b)
        variance = lambda t: t*t*a+(1-t)**2*b+2*t*(1-t)*c
        return numeric(dict(weights=[w,z], fused=w*x[0]+z*x[1], variance=variance(w), independence_weight_variance=variance(independent)))
    if code == 'CYB021':
        require(isinstance(v['A'], list) and len(v['A']) == 2, {'A_shape': v['A']})
        A = [vector(row, 2) for row in v['A']]; B = vector(v['B'], 2)
        initial = vector(v['initial'], 2); target = vector(v['target'], 2)
        h = v['horizon']; controls = vector(v['allowed_controls'])
        require(type(h) is int and h > 0 and controls == sorted(set(controls)), {'horizon_and_lexicographic_alphabet': v})
        mv = lambda x: [sum(A[i][j]*x[j] for j in range(2)) for i in range(2)]
        cols = [B]
        for _ in range(h-1): cols.append(mv(cols[-1]))
        matrix = [[col[i] for col in reversed(cols)] for i in range(2)]
        feasible = []
        for sequence in it.product(controls, repeat=h):
            x = initial[:]
            for u in sequence:
                ax = mv(x); x = [ax[i]+B[i]*u for i in range(2)]
            if x == target: feasible.append(list(sequence))
        energy = min((sum(u*u for u in seq) for seq in feasible), default=None)
        return numeric(dict(reachability_matrix=matrix, rank=rank2(matrix), feasible_sequences=feasible, minimum_energy=energy, optimal_controls=[seq for seq in feasible if sum(u*u for u in seq) == energy], final_state=target if feasible else None))
    if code == 'CYB022':
        state, desired, cap = [q(v[k]) for k in ('state','desired_action','next_state_upper')]
        lower, upper = vector(v['action_interval'], 2)
        require(lower <= upper, {'ordered_action_interval': v['action_interval']})
        upper = min(upper, cap-state)
        if lower > upper:
            return dict(feasible=False, feasible_interval=None, action=None, next_state=None, squared_change=None)
        action = max(lower, min(desired, upper))
        return numeric(dict(feasible=True, feasible_interval=[lower,upper], action=action, next_state=state+action, squared_change=(action-desired)**2))
    if code == 'CYB023':
        require(isinstance(v['X'], list) and bool(v['X']), {'design_rows': v['X']})
        X = [vector(row, 2) for row in v['X']]; y = vector(v['y'], len(X))
        gram = [[sum(row[i]*row[j] for row in X) for j in range(2)] for i in range(2)]
        rhs = [sum(X[k][i]*y[k] for k in range(len(y))) for i in range(2)]
        a,b = gram[0]; c,d = gram[1]; det = a*d-b*c
        theta = [(d*rhs[0]-b*rhs[1])/det, (a*rhs[1]-c*rhs[0])/det] if det else None
        return numeric(dict(gram=gram, rhs=rhs, determinant=det, rank=rank2(gram), unique_parameters=theta))
    if code == 'INF022':
        prior = vector(v['prior']); likelihood = vector(v['likelihood'], len(prior))
        require(sum(prior) == 1 and all(0 <= x <= 1 for x in prior+likelihood), {'probability_domain': v})
        products = [prior[i]*likelihood[i] for i in range(len(prior))]; normalizer = sum(products)
        require(normalizer > 0, {'impossible_observation': str(normalizer)})
        posterior = [p/normalizer for p in products]
        return rational(dict(unnormalized=products, normalizer=normalizer, posterior=posterior, total_variation=sum(abs(posterior[i]-prior[i]) for i in range(len(prior)))/2))
    if code == 'INF023':
        blocks, order, erased = v['blocks'], v['order'], v['erased_indices']
        require(isinstance(blocks,list) and bool(blocks) and all(isinstance(row,list) and len(row) == len(blocks[0]) and bool(row) for row in blocks), {'rectangular_blocks': blocks})
        flat = [x for row in blocks for x in row]
        require(all(isinstance(x,str) for x in flat) and len(set(flat)) == len(flat), {'distinct_symbols': flat})
        rows, cols = len(blocks), len(blocks[0])
        require(order in ('row-major','column-major') and isinstance(erased,list) and len(set(erased)) == len(erased) and all(type(i) is int and 0 <= i < len(flat) for i in erased), {'wire_semantics': v})
        positions = [(i,j) for i in range(rows) for j in range(cols)] if order == 'row-major' else [(i,j) for j in range(cols) for i in range(rows)]
        wire = [blocks[i][j] for i,j in positions]; reconstructed = [[None]*cols for _ in range(rows)]
        for k,(i,j) in enumerate(positions): reconstructed[i][j] = None if k in erased else wire[k]
        missing = [row.count(None) for row in reconstructed]
        return dict(wire=wire, reconstructed=reconstructed, missing_per_block=missing, missing_total=sum(missing))
    if code == 'INF024':
        alphabet, frequency, sequence = v['alphabet'], v['frequencies'], v['sequence']
        require(isinstance(alphabet,list) and bool(alphabet) and all(isinstance(s,str) and len(s) == 1 for s in alphabet) and len(set(alphabet)) == len(alphabet), {'single_character_alphabet': alphabet})
        f = vector(frequency, len(alphabet))
        require(all(type(t) is int and t > 0 for t in frequency) and isinstance(sequence,str) and bool(sequence) and set(sequence) <= set(alphabet), {'frequency_and_sequence': v})
        cumulative = [sum(f[:i])/sum(f) for i in range(len(f)+1)]
        def refine(low, high, i):
            width = high-low
            return low+width*cumulative[i], low+width*cumulative[i+1]
        low, high = Q(0), Q(1); intervals = []
        for symbol in sequence:
            low, high = refine(low, high, alphabet.index(symbol)); intervals.append([low,high])
        tag = q(v['tag']); require(0 <= tag < 1, {'tag_in_unit_interval': v['tag']})
        decoded = ''; dl, du = Q(0), Q(1)
        for _ in sequence:
            bins = [refine(dl,du,i) for i in range(len(alphabet))]
            hits = [i for i,(l,u) in enumerate(bins) if l <= tag < u]
            require(len(hits) == 1, {'half_open_decoding': rational(bins), 'tag': str(tag)})
            idx = hits[0]; decoded += alphabet[idx]; dl,du = bins[idx]
        return rational(dict(intervals=intervals, width=high-low, tag_inside=low <= tag < high, decoded=decoded))
    if code.startswith('NET'):
        nodes, edges = v['nodes'], v['edges']; width = 2 if code == 'NET020' else 3
        require(isinstance(nodes,list) and bool(nodes) and all(isinstance(n,str) and len(n) == 1 for n in nodes) and len(set(nodes)) == len(nodes), {'distinct_node_labels': nodes})
        require(isinstance(edges,list) and all(isinstance(e,list) and len(e) == width and e[0] in nodes and e[1] in nodes and e[0] != e[1] for e in edges), {'undirected_edges': edges})
        require(len({frozenset(e[:2]) for e in edges}) == len(edges), {'simple_graph': edges})
        index = {n:i for i,n in enumerate(nodes)}
        if code == 'NET019':
            weights = [q(e[2]) for e in edges]; require(all(w >= 0 for w in weights), {'nonnegative_costs': edges})
            trees = []
            for subset in it.combinations(range(len(edges)), len(nodes)-1):
                reached = {nodes[0]}
                for _ in nodes:
                    for k in subset:
                        a,b,_ = edges[k]
                        if a in reached or b in reached: reached.update((a,b))
                if len(reached) == len(nodes): trees.append((sum(weights[k] for k in subset), sorted(''.join(sorted(edges[k][:2])) for k in subset)))
            require(bool(trees), {'connected_input_required': v})
            minimum = min(cost for cost, tree in trees)
            return numeric(dict(minimum_cost=minimum, optimal_trees=sorted(tree for cost,tree in trees if cost == minimum)))
        if code == 'NET020':
            for k in range(1,len(nodes)+1):
                for colors in it.product(range(k),repeat=len(nodes)):
                    if all(colors[index[a]] != colors[index[b]] for a,b in edges): return dict(chromatic_number=k, colors=list(colors))
        require(len(nodes) == 3 and len(edges) == 3 and type(v['root_sign']) is int and v['root_sign'] in (1,-1) and all(type(e[2]) is int and e[2] in (1,-1) for e in edges), {'signed_triangle': v})
        labels = None
        for rest in it.product((1,-1),repeat=2):
            candidate = [v['root_sign'],*rest]
            if all(candidate[index[a]]*candidate[index[b]] == sign for a,b,sign in edges): labels = candidate; break
        return dict(cycle_product=math.prod(e[2] for e in edges), consistent=labels is not None, labels=labels)
    if code == 'PM016':
        names, objectives = v['names'], v['objectives']
        require(isinstance(names,list) and bool(names) and all(isinstance(n,str) for n in names) and len(set(names)) == len(names) and isinstance(objectives,list) and len(names) == len(objectives), {'option_rows': v})
        rows = [vector(row, len(objectives[0])) for row in objectives]
        pairs = [[names[i],names[j]] for i in range(len(names)) for j in range(len(names)) if i != j and all(rows[i][k] <= rows[j][k] for k in range(len(rows[i]))) and any(rows[i][k] < rows[j][k] for k in range(len(rows[i])))]
        return dict(nondominated=[n for n in names if not any(b == n for a,b in pairs)], dominance_pairs=pairs)
    if code == 'PM017':
        n, weights = v['total_slots'], v['weights']; w = vector(weights)
        require(type(n) is int and n >= 0 and all(type(t) is int and t >= 0 for t in weights) and sum(w) > 0, {'integer_slots_weights': v})
        quotas = [n*t/sum(w) for t in w]; floors = [t.numerator//t.denominator for t in quotas]
        order = sorted(range(len(w)),key=lambda i:(-(quotas[i]-floors[i]),i)); allocation = floors[:]
        for i in order[:n-sum(floors)]: allocation[i] += 1
        return rational(dict(quotas=quotas, floors=floors, remainder_order=order, allocation=allocation))
    if code == 'PM018':
        names = v['names']; require(isinstance(names,list) and len(names) == 2 and all(isinstance(n,str) for n in names) and len(set(names)) == 2, {'two_options': names})
        latency = vector(v['latency'],2); rework = vector(v['rework'],2); w = q(v['latency_weight'])
        require(0 <= w <= 1, {'unit_preference_weight': v['latency_weight']})
        slopes = [latency[i]-rework[i] for i in range(2)]
        require(slopes[0] != slopes[1], {'unique_crossover': v})
        cross = (rework[1]-rework[0])/(slopes[0]-slopes[1]); scores = [rework[i]+w*slopes[i] for i in range(2)]; at_cross = [rework[i]+cross*slopes[i] for i in range(2)]
        require(0 <= cross <= 1, {'crossover_in_allowed_interval': str(cross)})
        return rational(dict(scores=scores, winners=[names[i] for i in range(2) if scores[i] == min(scores)], crossover_weight=cross, crossover_scores=at_cross, crossover_winners=[names[i] for i in range(2) if at_cross[i] == min(at_cross)]))
    if code == 'PM019':
        n = v['total_samples']; w = vector(v['target_weights'],2); variances = vector(v['stratum_variances'],2)
        require(type(n) is int and n >= 2 and all(t >= 0 for t in w) and sum(w) == 1 and all(t > 0 for t in variances), {'stratified_sampling_domain': v})
        candidates = [w[0]**2*variances[0]/i+w[1]**2*variances[1]/(n-i) for i in range(1,n)]
        minimum = min(candidates)
        return rational(dict(candidate_variances=candidates, optimal_allocations=[[i,n-i] for i in range(1,n) if candidates[i-1] == minimum], minimum_variance=minimum))
    raise AssertionError(code)


# Independently worked exact fractions, endpoint propagation and graph witnesses.
# Never initialize these constants from mutable packet expected fields.
FIXED = {
 'COG021': [dict(probabilities=[.5,.119202922022], information=[.25,.419974341614],best_indices=[1]), dict(probabilities=[.268941421370,.017986209962],information=[.196611933241,.070650824853],best_indices=[0])],
 'COG022': [dict(fit=[.2,.5,.5,.9],weighted_squared_error=.12),dict(fit=[.2,.7,.7,.9],weighted_squared_error=.12)],
 'COG023': [dict(weights=[1.25,-.25],fused=9,variance=.875,independence_weight_variance=1.28),dict(weights=[.8,.2],fused=10.8,variance=.8,independence_weight_variance=.8)],
 'CYB021': [dict(reachability_matrix=[[2,1,0],[1,1,1]],rank=2,feasible_sequences=[[1,0,0]],minimum_energy=1,optimal_controls=[[1,0,0]],final_state=[2,1]),dict(reachability_matrix=[[1,0],[1,1]],rank=2,feasible_sequences=[],minimum_energy=None,optimal_controls=[],final_state=None)],
 'CYB022': [dict(feasible=True,feasible_interval=[-2,1],action=1,next_state=1,squared_change=4),dict(feasible=False,feasible_interval=None,action=None,next_state=None,squared_change=None)],
 'CYB023': [dict(gram=[[2,1],[1,2]],rhs=[7,8],determinant=3,rank=2,unique_parameters=[2,3]),dict(gram=[[14,14],[14,14]],rhs=[70,70],determinant=0,rank=1,unique_parameters=None)],
 'INF022': [dict(unnormalized=['2/5','1/10'],normalizer='1/2',posterior=['4/5','1/5'],total_variation='3/10'),dict(unnormalized=['1/5','1/5'],normalizer='2/5',posterior=['1/2','1/2'],total_variation='0')],
 'INF023': [dict(wire=list('ADGBEHCFI'),reconstructed=[[None,'B','C'],[None,'E','F'],[None,'H','I']],missing_per_block=[1,1,1],missing_total=3),dict(wire=list('ABCDEFGHI'),reconstructed=[[None,None,None],list('DEF'),list('GHI')],missing_per_block=[3,0,0],missing_total=3)],
 'INF024': [dict(intervals=[['0','1/4'],['1/16','1/4'],['1/16','7/64']],width='3/64',tag_inside=True,decoded='ABA'),dict(intervals=[['0','1/4'],['1/16','1/4'],['7/64','1/4']],width='9/64',tag_inside=True,decoded='ABB')],
 'NET019': [dict(minimum_cost=6,optimal_trees=[['AB','BC','CD']]),dict(minimum_cost=8,optimal_trees=[['AB','BC','BD']])],
 'NET020': [dict(chromatic_number=2,colors=[0,1,0,1]),dict(chromatic_number=3,colors=[0,1,2,1])],
 'NET021': [dict(cycle_product=1,consistent=True,labels=[1,1,-1]),dict(cycle_product=-1,consistent=False,labels=None)],
 'PM016': [dict(nondominated=['A','B','D'],dominance_pairs=[['A','C'],['B','C'],['D','C']]),dict(nondominated=['A','B'],dominance_pairs=[['A','C'],['A','D'],['B','C'],['B','D'],['D','C']])],
 'PM017': [dict(quotas=['7/2','21/10','7/5'],floors=[3,2,1],remainder_order=[0,2,1],allocation=[4,2,1]),dict(quotas=['4','12/5','8/5'],floors=[4,2,1],remainder_order=[2,1,0],allocation=[4,2,2])],
 'PM018': [dict(scores=['13/2','3'],winners=['B'],crossover_weight='3/5',crossover_scores=['22/5','22/5'],crossover_winners=['A','B']),dict(scores=['7/2','5'],winners=['A'],crossover_weight='3/5',crossover_scores=['22/5','22/5'],crossover_winners=['A','B'])],
 'PM019': [dict(candidate_variances=['4/7','1/2','8/15','5/8','4/5','7/6','16/7'],optimal_allocations=[[2,6]],minimum_variance='1/2'),dict(candidate_variances=['16/7','7/6','4/5','5/8','8/15','1/2','4/7'],optimal_allocations=[[6,2]],minimum_variance='1/2')],
}

SCOPES = {
 'COG021': 'Stipulated one-dimensional Bernoulli logistic item curves, fixed ability and no guessing; no fitted learner result.',
 'COG022': 'Four ordered training frequencies with positive case weights, weighted nondecreasing least squares; no held-out calibration.',
 'COG023': 'Two unbiased scalar estimates, known positive-definite covariance and unconstrained weights summing to one; no measured perception.',
 'CYB021': 'Exact two-dimensional discrete recurrence, finite horizon and bounded finite action alphabet; energy is squared commands.',
 'CYB022': 'Scalar exact next-state equation and one actuator interval; no disturbance or physical safety certification.',
 'CYB023': 'Finite exact two-column design and normal equations; rank is not an infinite persistent-excitation guarantee.',
 'INF022': 'Complete finite prior/likelihood vectors and positive marginal; total variation measures movement, not truth.',
 'INF023': 'Rectangular position permutation and known erasure indices; no redundancy, symbol recovery or measured audio quality.',
 'INF024': 'Exact rational half-open interval coding with declared single-character alphabet, frequencies and message length; no bitstream implementation.',
 'NET019': 'Connected simple undirected four-node graph and stipulated setup costs; minimum spanning trees do not provide failover.',
 'NET020': 'Finite undirected conflict graph, exact color enumeration; slots are not workers and durations are absent.',
 'NET021': 'Three-node scalar-sign triangle with fixed root convention; no noncommuting spatial transformation claim.',
 'PM016': 'Fictional comparable minimization coordinates, strict Pareto dominance; no unique preference or release decision.',
 'PM017': 'Indivisible fictional slots, exact nonnegative integer weights and lower-index tie rule; no universal fairness.',
 'PM018': 'Two comparable point-scale affine scores with unit-interval preference weight; no measured workflow recommendation.',
 'PM019': 'Two independent strata, known positive variances, with-replacement samples and positive integer splits of eight; no actual study.',
}


def assert_matches(observed, expected, path='result'):
    if isinstance(expected,dict):
        require(isinstance(observed,dict) and set(observed) == set(expected), {'path':path,'observed':observed,'expected':expected})
        for k in expected: assert_matches(observed[k],expected[k],path+'.'+k)
    elif isinstance(expected,list):
        require(isinstance(observed,list) and len(observed) == len(expected), {'path':path,'observed':observed,'expected':expected})
        for i in range(len(expected)): assert_matches(observed[i],expected[i],f'{path}[{i}]')
    elif isinstance(expected,bool) or expected is None:
        assert observed is expected, (path,observed,expected)
    elif type(expected) in (int,float):
        assert type(observed) in (int,float) and math.isclose(observed,expected,rel_tol=1e-12,abs_tol=1e-12), (path,observed,expected)
    else:
        assert observed == expected, (path,observed,expected)


def check_course(code, course):
    model = course['authored_model']
    for i,(case,data) in enumerate((('model',model),('negative',model['negative_control']))):
        observed = compute(code,data['values'])
        print('\nOBSERVATION '+json.dumps(dict(code=code,case=case,observed=observed,expected=FIXED[code][i],scope=SCOPES[code]),sort_keys=True),flush=True)
        assert_matches(observed,FIXED[code][i])
        assert_matches(observed,data['expected'])


class UnitB(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        rows = json.loads(PACKET.read_text(encoding='utf-8'))['courses']
        require(len(rows) == 16 and len({r['code'] for r in rows}) == 16 and {r['code'] for r in rows} == set(FIXED), {'assigned_codes':[r['code'] for r in rows]})
        cls.courses = {r['code']:r for r in rows}

    def test_cog021(self): check_course('COG021',self.courses['COG021'])
    def test_cog022(self): check_course('COG022',self.courses['COG022'])
    def test_cog023(self): check_course('COG023',self.courses['COG023'])
    def test_cyb021(self): check_course('CYB021',self.courses['CYB021'])
    def test_cyb022(self): check_course('CYB022',self.courses['CYB022'])
    def test_cyb023(self): check_course('CYB023',self.courses['CYB023'])
    def test_inf022(self): check_course('INF022',self.courses['INF022'])
    def test_inf023(self): check_course('INF023',self.courses['INF023'])
    def test_inf024(self): check_course('INF024',self.courses['INF024'])
    def test_net019(self): check_course('NET019',self.courses['NET019'])
    def test_net020(self): check_course('NET020',self.courses['NET020'])
    def test_net021(self): check_course('NET021',self.courses['NET021'])
    def test_pm016(self): check_course('PM016',self.courses['PM016'])
    def test_pm017(self): check_course('PM017',self.courses['PM017'])
    def test_pm018(self): check_course('PM018',self.courses['PM018'])
    def test_pm019(self): check_course('PM019',self.courses['PM019'])


def mutation_probe():
    course = copy.deepcopy(next(c for c in json.loads(PACKET.read_text(encoding='utf-8'))['courses'] if c['code'] == 'COG023'))
    before = copy.deepcopy(course['authored_model'])
    course['authored_model']['values']['covariance'] = 0
    course['authored_model']['expected'] = copy.deepcopy(course['authored_model']['negative_control']['expected'])
    observed = compute('COG023',course['authored_model']['values'])
    assert_matches(observed,course['authored_model']['expected'])
    print('MUTATION_INPUT '+json.dumps(dict(code='COG023',before=before,after=course['authored_model'],observed=observed,packet_expectation_would_accept=True,canonical_mutated=False)),flush=True)
    try:
        check_course('COG023',course)
    except AssertionError:
        traceback.print_exc(file=sys.stdout)
        print('MUTATION_REJECTED '+json.dumps(dict(code='COG023',expectation_also_mutated=True,canonical_mutated=False,scope='Intended substantive wrong-input rejection; canonical lesson did not fail.')),flush=True)
        return
    raise AssertionError('Co-mutated input and expectation escaped independent fixed oracle')


if __name__ == '__main__':
    if '--mutation-probe' in sys.argv: mutation_probe()
    else: unittest.main(verbosity=2)
