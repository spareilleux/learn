"""Independent finite authored-case checks; no production implementation changes.

Inputs come from the actual packet. FIXED contains separately derived oracles;
both that independent oracle and the packet expectation must agree. Only the
stated finite models are characterized, with diagnostics for their assumptions.
"""
import copy
from fractions import Fraction as Q
import itertools
import json
import math
from pathlib import Path
import re
import sys
import traceback
import unittest

PACKET = Path(__file__).resolve().parents[1] / "unit-b.json"


def require(condition, diagnostic):
    if not condition:
        print("\nDIAGNOSTIC " + json.dumps(diagnostic, ensure_ascii=False), flush=True)
        raise AssertionError(diagnostic)


def q(value):
    require(type(value) in (int, float) and math.isfinite(value), {"finite_number_required": value})
    return Q(str(value))


def serial(value):
    if isinstance(value, Q):
        return int(value) if value.denominator == 1 else float(value)
    if isinstance(value, dict):
        return {k: serial(v) for k, v in value.items()}
    if isinstance(value, (tuple, list)):
        return [serial(v) for v in value]
    return value


def integers(values, minimum=0):
    require(all(type(x) is int and x >= minimum for x in values), {"integers_at_least": minimum, "observed": values})


def expression(text):
    require(isinstance(text, str), {"expression_string_required": text})
    tokens = re.findall(r"[0-9]+|[+*()]|\S", text)
    require(bool(tokens) and all(re.fullmatch(r"[0-9]+|[+*()]", x) for x in tokens), {"expression_vocabulary": tokens})
    position = 0

    def atom():
        nonlocal position
        require(position < len(tokens), {"unexpected_expression_end": text})
        token = tokens[position]
        position += 1
        if token.isdecimal():
            return ["lit", int(token)]
        require(token == "(", {"expected_literal_or_parenthesis": token})
        node = add()
        require(position < len(tokens) and tokens[position] == ")", {"missing_closing_parenthesis": text})
        position += 1
        return node

    def multiply():
        nonlocal position
        node = atom()
        while position < len(tokens) and tokens[position] == "*":
            position += 1
            node = ["mul", node, atom()]
        return node

    def add():
        nonlocal position
        node = multiply()
        while position < len(tokens) and tokens[position] == "+":
            position += 1
            node = ["add", node, multiply()]
        return node

    tree = add()
    require(position == len(tokens), {"unconsumed_expression_tokens": tokens[position:]})
    return tree


def evaluate(tree):
    if tree[0] == "lit":
        return tree[1]
    if tree[0] == "add":
        return evaluate(tree[1]) + evaluate(tree[2])
    require(tree[0] == "mul", {"unknown_ast_tag": tree[0]})
    return evaluate(tree[1]) * evaluate(tree[2])


def graph(v):
    nodes, edges = v["nodes"], v["edges"]
    require(isinstance(nodes, list) and all(isinstance(n, str) for n in nodes) and len(nodes) == len(set(nodes)), {"unique_string_nodes_required": nodes})
    require(isinstance(edges, list) and all(isinstance(e, list) and len(e) == 2 and all(n in nodes for n in e) for e in edges), {"listed_edge_endpoints_required": edges})
    require(len(edges) == len({tuple(e) for e in edges}), {"unique_edges_required": edges})
    return nodes, edges


def paths(start, target, edges, visited=None):
    visited = [start] if visited is None else visited
    if start == target:
        return [visited]
    result = []
    for left, right in edges:
        if left == start and right not in visited:
            result.extend(paths(right, target, edges, visited + [right]))
    return sorted(result)


def reachable_pairs(nodes, edges):
    return {(a, b) for a in nodes for b in nodes if a != b and paths(a, b, edges)}


def compute(code, v):
    if code == "CS024":
        a, b = expression(v["source"]), expression(v["printed"])
        return dict(source_ast=a, printed_ast=b, same_ast=a == b, same_text=v["source"] == v["printed"], values=[evaluate(a), evaluate(b)])
    if code == "CS025":
        rows, fields = v["rows"], v["key_fields"]
        require(isinstance(rows, list) and bool(rows) and isinstance(fields, list) and bool(fields) and len(set(fields)) == len(fields) and all(k in ("item", "revision") for k in fields), {"cache_catalogue_or_key_fields": v})
        require(all(isinstance(r, dict) and isinstance(r.get("item"), str) and isinstance(r.get("revision"), str) and type(r.get("score")) is int for r in rows), {"typed_cache_rows_required": rows})
        witnesses = [[i,j] for i in range(len(rows)) for j in range(i+1, len(rows)) if all(rows[i][k] == rows[j][k] for k in fields) and rows[i]["score"] != rows[j]["score"]]
        return dict(witness_pairs=witnesses, sufficient=not witnesses)
    if code == "CYB018":
        A, C, x = v["A"], v["C"], v["x0"]
        require(isinstance(A, list) and len(A) == 2 and all(isinstance(r, list) and len(r) == 2 for r in A) and isinstance(C, list) and len(C) == 2 and isinstance(x, list) and len(x) == 2, {"observation_shapes_required": v})
        A, C, x = [[q(z) for z in r] for r in A], list(map(q,C)), list(map(q,x))
        O = [C, [sum(C[k]*A[k][j] for k in range(2)) for j in range(2)]]
        det = O[0][0]*O[1][1]-O[0][1]*O[1][0]
        y = [sum(O[i][j]*x[j] for j in range(2)) for i in range(2)]
        reconstructed = [(y[0]*O[1][1]-O[0][1]*y[1])/det, (O[0][0]*y[1]-y[0]*O[1][0])/det] if det else None
        rank = 2 if det else int(any(z for row in O for z in row))
        return serial(dict(O=O, determinant=det, rank=rank, outputs=y, reconstructed=reconstructed))
    if code == "CYB019":
        a, b = q(v["diagonal"]), q(v["coupling"])
        require(isinstance(v["initial"], list) and len(v["initial"]) == 2, {"two_initial_coordinates_required": v})
        integers([v["steps"]])
        x = list(map(q,v["initial"]))
        trajectory = [x]
        for _ in range(v["steps"]):
            x = [a*x[0]+b*x[1], b*x[0]+a*x[1]]
            trajectory.append(x)
        eigenvalues = [a+b, a-b]
        radius = max(map(abs,eigenvalues))
        return serial(dict(eigenvalues=eigenvalues, spectral_radius=radius, stable=radius < 1, trajectory=trajectory))
    if code == "CYB020":
        safe, disturbances, service = v["safe_states"], v["disturbances"], v["service"]
        require(isinstance(safe, list) and bool(safe) and len(safe) == len(set(safe)) and isinstance(disturbances, list) and bool(disturbances) and len(disturbances) == len(set(disturbances)), {"nonempty_state_and_disturbance_sets_required": v})
        integers(safe+disturbances+[service])
        triples = sorted([s,d,max(0,s-service)+d] for s in safe for d in disturbances)
        escaping = [t for t in triples if t[2] not in safe]
        return dict(successor_set=sorted({t[2] for t in triples}), escaping=escaping, closed=not escaping)
    if code == "COG018":
        a,b,c,d = [v[k] for k in ("both_correct","old_only","new_only","both_wrong")]
        integers([a,b,c,d])
        total, discordant = a+b+c+d, b+c
        require(total > 0, {"positive_paired_total_required": v})
        # Enumerate null direction strings directly, independently of the
        # packet's doubled-combination-tail expression.
        extreme = sum(abs(2*sum(bits)-discordant) >= abs(c-b) for bits in itertools.product((0,1), repeat=discordant))
        probability = Q(extreme, 2**discordant)
        return serial(dict(paired=total, discordant=discordant, old_correct=a+b, new_correct=a+c, accuracy_difference=Q(c-b,total), p_value=probability))
    if code == "COG019":
        a,b,c,d = [v[k] for k in ("both_pass","A_only","B_only","both_fail")]
        integers([a,b,c,d])
        n = a+b+c+d
        require(n > 0, {"positive_rating_total_required": v})
        observed, pa, pb = Q(a+d,n), Q(a+b,n), Q(a+c,n)
        chance = pa*pb+(1-pa)*(1-pb)
        corrected = (observed-chance)/(1-chance) if chance != 1 else None
        return serial(dict(N=n, observed_agreement=observed, expected_agreement=chance, kappa_fraction=str(corrected) if corrected is not None else None))
    if code == "COG020":
        scores, answers = v["rest_scores"], v["item_correct"]
        require(isinstance(scores,list) and isinstance(answers,list) and len(scores) == len(answers) and len(scores) > 0 and len(scores)%2 == 0 and len(set(scores)) == len(scores), {"equal_even_distinct_rest_score_rows_required": v})
        integers(scores)
        require(all(type(x) is int and x in (0,1) for x in answers), {"binary_item_responses_required": answers})
        ranked = [answers[i] for i in sorted(range(len(scores)), key=lambda i:scores[i])]
        half = len(scores)//2
        low, high = sum(ranked[:half]), sum(ranked[half:])
        return serial(dict(lower_correct=low, upper_correct=high, group_size=half, overall_fraction=Q(sum(answers),len(scores)), discrimination=Q(high-low,half)))
    if code == "INF019":
        book, stream = v["codebook"], v["stream"]
        require(isinstance(book,dict) and bool(book) and all(isinstance(k,str) and isinstance(w,str) and bool(w) and set(w) <= set("01") for k,w in book.items()), {"nonempty_binary_codewords_required": book})
        require(len(set(book.values())) == len(book) and isinstance(stream,str) and set(stream) <= set("01"), {"distinct_codewords_and_bitstream_required": v})
        violations = sorted([s,t] for s in book for t in book if s != t and len(book[s]) < len(book[t]) and book[t].startswith(book[s]))
        def decode(offset):
            if offset == len(stream):
                return [[]]
            return [[s]+tail for s,w in sorted(book.items()) if stream.startswith(w,offset) for tail in decode(offset+len(w))]
        decodings = sorted(decode(0))
        return dict(prefix_violations=violations, prefix_free=not violations, decodings=decodings, decoding_count=len(decodings))
    if code == "INF020":
        data, flips = v["data"], v["flip_indices"]
        require(isinstance(data,list) and all(type(x) is int and x in (0,1) for x in data) and isinstance(flips,list), {"parity_bits_and_indices_required": v})
        require(all(type(i) is int and 0 <= i <= len(data) for i in flips) and len(set(flips)) == len(flips), {"distinct_valid_flip_indices_required": flips})
        parity = sum(data)%2
        word = data+[parity]
        received = [bit ^ int(i in flips) for i,bit in enumerate(word)]
        syndrome = sum(received)%2
        distance = sum(received[i] != word[i] for i in range(len(word)))
        return dict(parity_bit=parity, codeword=word, received=received, syndrome=syndrome, detected=syndrome == 1, hamming_distance=distance)
    if code == "INF021":
        p, initial, length = q(v["flip_probability"]), v["stationary"], v["block_length"]
        require(isinstance(initial,list) and len(initial) == 2 and list(map(q,initial)) == [Q(1,2),Q(1,2)] and 0 <= p <= 1, {"declared_balanced_stationary_source_required": v})
        integers([length],1)
        def entropy(probabilities):
            return -sum(float(t)*math.log2(float(t)) for t in probabilities if t)
        marginal = entropy(list(map(q,initial)))
        rate = entropy([p,1-p])
        # Independent block enumeration checks the initial-state term instead
        # of producing a block result by copying the packet's formula.
        block = []
        for sequence in itertools.product((0,1),repeat=length):
            probability = q(initial[sequence[0]])
            for i in range(1,length):
                probability *= p if sequence[i] != sequence[i-1] else 1-p
            block.append(probability)
        return dict(marginal_entropy_bits=marginal, entropy_rate_bits_per_symbol=rate, block_entropy_bits=entropy(block))
    if code == "NET016":
        nodes, edges = graph(v)
        require(all(v[k] in nodes for k in ("start","target","candidate")), {"listed_dominance_nodes_required": v})
        routes = paths(v["start"],v["target"],edges)
        require(bool(routes), {"target_unreachable": v["target"], "start":v["start"]})
        common = set.intersection(*(set(r) for r in routes))
        bypasses = [r for r in routes if v["candidate"] not in r]
        return dict(dominators=[n for n in nodes if n in common], candidate_mandatory=v["candidate"] in common, bypass=bypasses[0] if bypasses else None)
    if code == "NET017":
        candidates = v["candidates"]
        require(isinstance(candidates,dict) and bool(candidates) and all(isinstance(r,str) and isinstance(ws,list) and all(isinstance(w,str) for w in ws) and len(set(ws)) == len(ws) for r,ws in candidates.items()), {"typed_role_candidate_sets_required": v})
        roles = sorted(candidates)
        matchings = []
        for choices in itertools.product(*([None]+sorted(candidates[r]) for r in roles)):
            workers = [w for w in choices if w is not None]
            if len(set(workers)) == len(workers):
                matchings.append([[roles[i],w] for i,w in enumerate(choices) if w is not None])
        maximum = max(map(len,matchings))
        matching = min(m for m in matchings if len(m) == maximum)
        obstruction = None
        for count in range(1,len(roles)+1):
            for subset in itertools.combinations(roles,count):
                neighbours = sorted(set().union(*(set(candidates[r]) for r in subset)))
                if len(neighbours) < count:
                    obstruction = dict(roles=list(subset),workers=neighbours,deficiency=count-len(neighbours))
                    break
            if obstruction is not None:
                break
        return dict(all_roles_covered=all(bool(candidates[r]) for r in roles), maximum_count=maximum, matching=matching, obstruction=obstruction)
    if code == "NET018":
        nodes, edges = graph(v)
        require(not any(left == right or paths(right,left,edges) for left,right in edges), {"DAG_required": edges})
        retained = sorted(e for e in edges if not paths(e[0],e[1],[x for x in edges if x != e]))
        before, after = reachable_pairs(nodes,edges), reachable_pairs(nodes,retained)
        require(before == after, {"reachability_pairs_changed": [sorted(before),sorted(after)]})
        return dict(retained_edges=retained, removed_edges=sorted(e for e in edges if e not in retained), reachable_pairs_before=len(before), reachable_pairs_after=len(after))
    if code == "PM014":
        items, budget = v["items"], v["budget"]
        require(isinstance(items,dict) and bool(items) and all(isinstance(k,str) and isinstance(row,dict) and isinstance(row.get("requires"),list) and all(r in items for r in row["requires"]) for k,row in items.items()), {"portfolio_dependency_names_required": v})
        integers([budget]+[row[k] for row in items.values() for k in ("cost","value")])
        dependency_edges = [[r,k] for k,row in items.items() for r in row["requires"]]
        require(not any(a == b or paths(b,a,dependency_edges) for a,b in dependency_edges), {"acyclic_portfolio_required": dependency_edges})
        feasible = []
        names = sorted(items)
        for mask in itertools.product((0,1),repeat=len(names)):
            selected = [names[i] for i,take in enumerate(mask) if take]
            cost = sum(items[k]["cost"] for k in selected)
            if cost <= budget and all(all(r in selected for r in items[k]["requires"]) for k in selected):
                feasible.append((sum(items[k]["value"] for k in selected),selected,cost))
        best = max(row[0] for row in feasible)
        winners = sorted((s,c) for value,s,c in feasible if value == best)
        return dict(feasible_count=len(feasible),optimal_sets=[s for s,c in winners],optimal_costs=[c for s,c in winners],optimal_value=best)
    if code == "PM015":
        n, sizes = v["items"], v["candidate_sizes"]
        integers([n],1)
        require(isinstance(sizes,list) and bool(sizes) and len(set(sizes)) == len(sizes), {"distinct_candidate_sizes_required": sizes})
        integers(sizes,1)
        require(all(n%s == 0 for s in sizes), {"complete_batch_divisors_required": v})
        setup, waiting = q(v["setup_cost"]), q(v["waiting_cost_per_item_tick"])
        require(setup >= 0 and waiting >= 0, {"nonnegative_common_point_costs_required": v})
        waits = [sum(((i//size)+1)*size-(i+1) for i in range(n)) for size in sizes]
        costs = [setup*(n//sizes[i])+waiting*waits[i] for i in range(len(sizes))]
        minimum = min(costs)
        return serial(dict(total_costs=costs,waiting_item_ticks=waits,optimal_sizes=[sizes[i] for i,cost in enumerate(costs) if cost == minimum],minimum_cost=minimum))
    raise ValueError("Unassigned course: " + code)


# Separately derived exact trees, fractions, exhaustive assignments and arrivals.
# These are literals, never populated from the packet's mutable expected fields.
TREE = ["add",["lit",1],["mul",["lit",2],["lit",3]]]
FIXED = {
    "CS024": [dict(source_ast=TREE,printed_ast=TREE,same_ast=True,same_text=False,values=[7,7]),dict(source_ast=TREE,printed_ast=["mul",["add",["lit",1],["lit",2]],["lit",3]],same_ast=False,same_text=False,values=[7,9])],
    "CS025": [dict(witness_pairs=[[0,1]],sufficient=False),dict(witness_pairs=[],sufficient=True)],
    "CYB018": [dict(O=[[1,1],[1,2]],determinant=1,rank=2,outputs=[7,11],reconstructed=[3,4]),dict(O=[[1,1],[1,1]],determinant=0,rank=1,outputs=[7,7],reconstructed=None)],
    "CYB019": [dict(eigenvalues=[1.25,-.25],spectral_radius=1.25,stable=False,trajectory=[[1,1],[1.25,1.25],[1.5625,1.5625],[1.953125,1.953125]]),dict(eigenvalues=[.75,.25],spectral_radius=.75,stable=True,trajectory=[[1,1],[.75,.75],[.5625,.5625],[.421875,.421875]])],
    "CYB020": [dict(successor_set=[0,1,2],escaping=[],closed=True),dict(successor_set=[0,1,2,3],escaping=[[2,2,3]],closed=False)],
    "COG018": [dict(paired=12,discordant=8,old_correct=3,new_correct=9,accuracy_difference=.5,p_value=18/256),dict(paired=12,discordant=8,old_correct=6,new_correct=6,accuracy_difference=0,p_value=1)],
    "COG019": [dict(N=10,observed_agreement=.8,expected_agreement=.56,kappa_fraction="6/11"),dict(N=10,observed_agreement=1,expected_agreement=1,kappa_fraction=None)],
    "COG020": [dict(lower_correct=3,upper_correct=1,group_size=4,overall_fraction=.5,discrimination=-.5),dict(lower_correct=1,upper_correct=3,group_size=4,overall_fraction=.5,discrimination=.5)],
    "INF019": [dict(prefix_violations=[],prefix_free=True,decodings=[["A","B","C"]],decoding_count=1),dict(prefix_violations=[["A","B"]],prefix_free=False,decodings=[["A","C"],["B"]],decoding_count=2)],
    "INF020": [dict(parity_bit=1,codeword=[1,0,1,1,1],received=[1,1,1,1,1],syndrome=1,detected=True,hamming_distance=1),dict(parity_bit=1,codeword=[1,0,1,1,1],received=[1,1,0,1,1],syndrome=0,detected=False,hamming_distance=2)],
    "INF021": [dict(marginal_entropy_bits=1,entropy_rate_bits_per_symbol=.8112781244591328,block_entropy_bits=3.4338343733773984),dict(marginal_entropy_bits=1,entropy_rate_bits_per_symbol=1,block_entropy_bits=4)],
    "NET016": [dict(dominators=["S","R","P"],candidate_mandatory=True,bypass=None),dict(dominators=["S","P"],candidate_mandatory=False,bypass=["S","B","P"])],
    "NET017": [dict(all_roles_covered=True,maximum_count=2,matching=[["draft","w1"],["translate","w2"]],obstruction=dict(roles=["draft","review"],workers=["w1"],deficiency=1)),dict(all_roles_covered=True,maximum_count=3,matching=[["draft","w1"],["review","w2"],["translate","w3"]],obstruction=None)],
    "NET018": [dict(retained_edges=[["A","B"],["B","C"],["C","D"]],removed_edges=[["A","C"],["A","D"],["B","D"]],reachable_pairs_before=6,reachable_pairs_after=6),dict(retained_edges=[["A","B"],["A","C"],["B","D"],["C","D"]],removed_edges=[["A","D"]],reachable_pairs_before=5,reachable_pairs_after=5)],
    "PM014": [dict(feasible_count=7,optimal_sets=[["C","D"]],optimal_costs=[6],optimal_value=10),dict(feasible_count=9,optimal_sets=[["B","D"]],optimal_costs=[5],optimal_value=11)],
    "PM015": [dict(total_costs=[108,60,48,45,48,75],waiting_item_ticks=[0,6,12,18,30,66],optimal_sizes=[4],minimum_cost=45),dict(total_costs=[12,12,16,21,32,67],waiting_item_ticks=[0,6,12,18,30,66],optimal_sizes=[1,2],minimum_cost=12)],
}

SCOPES = {
    "CS024":"Two expressions in the integer/add/multiply grammar; structural equality, not a production parser.",
    "CS025":"Three stipulated pure result rows; finite-catalogue key sufficiency only.",
    "CYB018":"Exact known autonomous 2x2 dynamics, noiseless synchronized outputs and no unknown inputs.",
    "CYB019":"Symmetric fixed 2x2 autonomous linear dynamics; stability means asymptotic decay of every mode.",
    "CYB020":"All stated finite states/disturbances, service before arrivals; no arrival probabilities or real queue.",
    "COG018":"Independent discordant paired Bernoulli directions under p=1/2; authored counts, no causal learner result.",
    "COG019":"Fictional paired binary ratings with separate empirical marginals; undefined correction retained.",
    "COG020":"Eight complete fictional responses, distinct rest scores excluding the item and declared equal halves.",
    "INF019":"Finite distinct nonempty binary codewords; enumerate complete parses, no HPACK implementation.",
    "INF020":"Known word boundaries, distinct bit substitutions and one even parity bit; no correction or authentication.",
    "INF021":"Known stationary balanced symmetric first-order binary Markov source; base-2 random-symbol entropy.",
    "NET016":"Complete allowed-route graph, fixed entry and reachable target; no conjunctive join or authorization.",
    "NET017":"Simultaneous single-worker roles and worker exclusivity; candidate coverage differs from full matching.",
    "NET018":"Finite precedence-only DAG; actual reachable pair sets preserved, no payload or receipt deletion.",
    "PM014":"Finite additive fictional costs/values, all required items selected once and acyclic prerequisites.",
    "PM015":"Twelve deterministic one-per-tick arrivals, instant verification and stipulated common cost points; all ties retained.",
}


def assert_matches(observed, expected, path="result"):
    if isinstance(expected, dict):
        assert isinstance(observed,dict) and observed.keys() == expected.keys(), (path,observed,expected)
        for key in expected:
            assert_matches(observed[key],expected[key],path+"."+key)
    elif isinstance(expected,list):
        assert isinstance(observed,list) and len(observed) == len(expected), (path,observed,expected)
        for i in range(len(expected)):
            assert_matches(observed[i],expected[i],f"{path}[{i}]")
    elif isinstance(expected,bool) or expected is None:
        assert observed is expected, (path,observed,expected)
    elif isinstance(expected,(int,float)):
        assert type(observed) in (int,float) and math.isclose(observed,expected,rel_tol=1e-12,abs_tol=1e-12), (path,observed,expected)
    else:
        assert observed == expected, (path,observed,expected)


def check_course(code, course):
    model = course["authored_model"]
    for i,(case,data) in enumerate((("model",model),("negative",model["negative_control"]))):
        observed = compute(code,data["values"])
        print("\nOBSERVATION "+json.dumps(dict(code=code,case=case,observed=observed,expected=FIXED[code][i],scope=SCOPES[code]),ensure_ascii=False,sort_keys=True),flush=True)
        assert_matches(observed,FIXED[code][i])
        assert_matches(observed,data["expected"])


class UnitB(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        rows = json.loads(PACKET.read_text(encoding="utf-8"))["courses"]
        require(len(rows) == 16 and len({c["code"] for c in rows}) == 16 and {c["code"] for c in rows} == set(FIXED), {"assigned_course_identity_mismatch": [c["code"] for c in rows]})
        cls.courses = {c["code"]:c for c in rows}

    def test_cs024(self): check_course("CS024",self.courses["CS024"])
    def test_cs025(self): check_course("CS025",self.courses["CS025"])
    def test_cyb018(self): check_course("CYB018",self.courses["CYB018"])
    def test_cyb019(self): check_course("CYB019",self.courses["CYB019"])
    def test_cyb020(self): check_course("CYB020",self.courses["CYB020"])
    def test_cog018(self): check_course("COG018",self.courses["COG018"])
    def test_cog019(self): check_course("COG019",self.courses["COG019"])
    def test_cog020(self): check_course("COG020",self.courses["COG020"])
    def test_inf019(self): check_course("INF019",self.courses["INF019"])
    def test_inf020(self): check_course("INF020",self.courses["INF020"])
    def test_inf021(self): check_course("INF021",self.courses["INF021"])
    def test_net016(self): check_course("NET016",self.courses["NET016"])
    def test_net017(self): check_course("NET017",self.courses["NET017"])
    def test_net018(self): check_course("NET018",self.courses["NET018"])
    def test_pm014(self): check_course("PM014",self.courses["PM014"])
    def test_pm015(self): check_course("PM015",self.courses["PM015"])


def mutation_probe():
    course = copy.deepcopy(next(c for c in json.loads(PACKET.read_text(encoding="utf-8"))["courses"] if c["code"] == "PM015"))
    before = copy.deepcopy(course["authored_model"])
    # Substantive premise mutation: cheap setup changes the optimum and creates
    # a tie. Co-mutate the packet expectation; the fixed baseline still rejects.
    course["authored_model"]["values"]["setup_cost"] = 1
    course["authored_model"]["expected"] = copy.deepcopy(course["authored_model"]["negative_control"]["expected"])
    observed = compute("PM015",course["authored_model"]["values"])
    assert_matches(observed,course["authored_model"]["expected"])
    print("MUTATION_INPUT "+json.dumps(dict(code="PM015",before=before,after=course["authored_model"],packet_expectation_would_accept=True,canonical_mutated=False)),flush=True)
    try:
        check_course("PM015",course)
    except AssertionError:
        traceback.print_exc(file=sys.stdout)
        print("MUTATION_REJECTED "+json.dumps(dict(code="PM015",expectation_also_mutated=True,canonical_mutated=False,scope="Intended wrong-input rejection, not a failing course.")),flush=True)
        return
    raise AssertionError("Incorrect input with co-mutated expectation escaped fixed oracle")


if __name__ == "__main__":
    if "--mutation-probe" in sys.argv:
        mutation_probe()
    else:
        unittest.main(verbosity=2)
