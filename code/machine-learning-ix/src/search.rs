//! Lesson 16: A* and its weighted, bidirectional and Q* variants, Monte-Carlo tree search and local search,
//! measured against IX's `ix-search`, with `ix-graph`'s Dijkstra as the reference for path costs.
//!
//! A graph state is a node index plus a shared adjacency list, compared and hashed by its index only. Mazes
//! and 8-queens boards come from the course's `Rng`, so the numpy cross-check rebuilds the same ones. IX's
//! `mcts_search` keeps its own seeded `StdRng`.

use std::cell::{Cell, RefCell};
use std::hash::{Hash, Hasher};
use std::rc::Rc;

use ix_graph::graph::Graph;
use ix_search::adversarial::{GameState, minimax};
use ix_search::astar::{SearchResult, SearchState, astar, bidirectional_astar, weighted_astar};
use ix_search::local::{
    LocalSearchState, beam_search, hill_climbing, random_restart_hill_climbing, tabu_search,
};
use ix_search::mcts::{MctsState, mcts_search};
use ix_search::qstar::{TabularQ, qstar_search, qstar_two_head};

use crate::autodiff::Rng;

/// `edges[u]` lists (v, cost) for every edge u → v
pub type Edges = Rc<Vec<Vec<(usize, f64)>>>;

/// Adjacency lists for `n` nodes from directed edges (u, v, cost), each list in the order given
pub fn edges(n: usize, list: &[(usize, usize, f64)]) -> Edges {
    let mut adjacency = vec![Vec::new(); n];
    for &(u, v, cost) in list {
        adjacency[u].push((v, cost));
    }
    Rc::new(adjacency)
}

/// A node of a graph searched by `ix-search`, equal to and hashed as its `id` only
#[derive(Clone, Debug)]
pub struct Node {
    pub id: usize,
    pub goal: usize,
    pub edges: Edges,
}

impl Node {
    pub fn new(edges: &Edges, id: usize, goal: usize) -> Self {
        Node {
            id,
            goal,
            edges: Rc::clone(edges),
        }
    }
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Eq for Node {}

impl Hash for Node {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.id.hash(state);
    }
}

impl SearchState for Node {
    /// (from, to)
    type Action = (usize, usize);

    fn successors(&self) -> Vec<(Self::Action, Self, f64)> {
        self.edges[self.id]
            .iter()
            .map(|&(v, cost)| ((self.id, v), Node::new(&self.edges, v, self.goal), cost))
            .collect()
    }

    fn is_goal(&self) -> bool {
        self.id == self.goal
    }
}

/// What a search returned: its cost, the node ids of its path, its actions and its expansions
#[derive(Clone, Debug, PartialEq)]
pub struct Found {
    pub cost: f64,
    pub path: Vec<usize>,
    pub actions: Vec<(usize, usize)>,
    pub expanded: usize,
}

impl From<SearchResult<Node>> for Found {
    fn from(result: SearchResult<Node>) -> Self {
        Found {
            cost: result.cost,
            path: result.path.iter().map(|n| n.id).collect(),
            actions: result.actions,
            expanded: result.nodes_expanded,
        }
    }
}

/// `ix-graph`'s Dijkstra distance from `from` to `to`, infinite when `to` is unreachable
pub fn dijkstra(edges: &Edges, from: usize, to: usize) -> f64 {
    let mut graph = Graph::with_nodes(edges.len());
    for (u, list) in edges.iter().enumerate() {
        for &(v, cost) in list {
            graph.add_edge(u, v, cost);
        }
    }
    graph
        .dijkstra(from)
        .0
        .get(&to)
        .copied()
        .unwrap_or(f64::INFINITY)
}

// ---------------------------------------------------------------- P1, an admissible heuristic

/// S = 0, A = 1, C = 2, G = 3: S→A 1, S→C 3, A→C 1, C→G 3. The optimum is 5, by S, A, C, G.
pub fn inconsistent_graph() -> Edges {
    edges(4, &[(0, 1, 1.0), (0, 2, 3.0), (1, 2, 1.0), (2, 3, 3.0)])
}

/// A* on the graph above with h(A) = 4 and 0 elsewhere (admissible but not consistent), with h = 0 and with
/// h = h*, and `ix-graph`'s Dijkstra distance
pub struct Inconsistent {
    pub inconsistent: Found,
    pub zero: Found,
    pub exact: Found,
    pub dijkstra: f64,
}

pub fn inconsistent() -> Inconsistent {
    let graph = inconsistent_graph();
    let start = Node::new(&graph, 0, 3);
    let exact = [5.0, 4.0, 3.0, 0.0];
    let run = |h: &dyn Fn(&Node) -> f64| -> Found {
        astar(start.clone(), h).expect("G is reachable").into()
    };
    Inconsistent {
        inconsistent: run(&|n| if n.id == 1 { 4.0 } else { 0.0 }),
        zero: run(&|_| 0.0),
        exact: run(&|n| exact[n.id]),
        dijkstra: dijkstra(&graph, 0, 3),
    }
}

// ---------------------------------------------------------------- P2, weighted A* on mazes

pub const MAZE_SIZE: usize = 30;
pub const WALL: f64 = 0.25;
pub const MAZES: usize = 100;
pub const WEIGHTS: [f64; 3] = [1.5, 2.0, 5.0];

/// Maze `index`: a cell is a wall when `Rng(16_000 + index)` draws below `WALL`, cells taken row by row; the
/// corners (0, 0) and (29, 29) stay open
pub fn maze(index: usize) -> Vec<bool> {
    let mut rng = Rng(16_000 + index as u64);
    let cells = MAZE_SIZE * MAZE_SIZE;
    let mut open: Vec<bool> = (0..cells).map(|_| rng.next_f64() >= WALL).collect();
    open[0] = true;
    open[cells - 1] = true;
    open
}

/// Moves of cost 1 between open neighbours, tried right, left, down, up
pub fn maze_edges(open: &[bool]) -> Edges {
    let n = MAZE_SIZE;
    let mut list = Vec::new();
    for y in 0..n {
        for x in 0..n {
            let u = y * n + x;
            if !open[u] {
                continue;
            }
            let mut neighbours = Vec::new();
            if x + 1 < n {
                neighbours.push(u + 1);
            }
            if x > 0 {
                neighbours.push(u - 1);
            }
            if y + 1 < n {
                neighbours.push(u + n);
            }
            if y > 0 {
                neighbours.push(u - n);
            }
            list.extend(
                neighbours
                    .into_iter()
                    .filter(|&v| open[v])
                    .map(|v| (u, v, 1.0)),
            );
        }
    }
    edges(n * n, &list)
}

/// Manhattan distance to the far corner
pub fn manhattan(node: &Node) -> f64 {
    let (x, y) = (node.id % MAZE_SIZE, node.id / MAZE_SIZE);
    ((MAZE_SIZE - 1 - x) + (MAZE_SIZE - 1 - y)) as f64
}

/// One maze: Dijkstra's distance, then (cost, expansions) for A* and for weighted A* at each of `WEIGHTS`
pub struct MazeRun {
    pub dijkstra: f64,
    pub astar: Option<(f64, usize)>,
    pub weighted: Vec<Option<(f64, usize)>>,
}

pub fn maze_run(index: usize) -> MazeRun {
    let graph = maze_edges(&maze(index));
    let goal = MAZE_SIZE * MAZE_SIZE - 1;
    let start = Node::new(&graph, 0, goal);
    let costs = |r: SearchResult<Node>| (r.cost, r.nodes_expanded);
    MazeRun {
        dijkstra: dijkstra(&graph, 0, goal),
        astar: astar(start.clone(), manhattan).map(costs),
        weighted: WEIGHTS
            .iter()
            .map(|&w| weighted_astar(start.clone(), manhattan, w).map(costs))
            .collect(),
    }
}

/// The `MAZES` mazes together. `over_bound` and `worst_ratio` compare each weighted cost with the optimum;
/// `mean_expanded` is A*'s, then each weight's, over the reachable mazes.
pub struct Mazes {
    pub reachable: usize,
    pub none_iff_unreachable: bool,
    pub astar_is_dijkstra: bool,
    pub total_cost: f64,
    pub over_bound: [usize; 3],
    pub worst_ratio: [f64; 3],
    pub mean_expanded: [f64; 4],
}

pub fn mazes() -> Mazes {
    let mut m = Mazes {
        reachable: 0,
        none_iff_unreachable: true,
        astar_is_dijkstra: true,
        total_cost: 0.0,
        over_bound: [0; 3],
        worst_ratio: [1.0; 3],
        mean_expanded: [0.0; 4],
    };
    for index in 0..MAZES {
        let run = maze_run(index);
        let Some((cost, expanded)) = run.astar else {
            m.none_iff_unreachable &= run.dijkstra.is_infinite();
            continue;
        };
        m.none_iff_unreachable &= run.dijkstra.is_finite();
        m.astar_is_dijkstra &= cost == run.dijkstra;
        m.reachable += 1;
        m.total_cost += run.dijkstra;
        m.mean_expanded[0] += expanded as f64;
        for (k, (weighted, w)) in run.weighted.iter().zip(WEIGHTS).enumerate() {
            let (c, e) = weighted.expect("a reachable maze");
            if c > w * run.dijkstra {
                m.over_bound[k] += 1;
            }
            m.worst_ratio[k] = m.worst_ratio[k].max(c / run.dijkstra);
            m.mean_expanded[k + 1] += e as f64;
        }
    }
    for e in &mut m.mean_expanded {
        *e /= m.reachable as f64;
    }
    m
}

// ---------------------------------------------------------------- P3, bidirectional A*

/// S = 0, A = 1, G = 2 on the directed cycle S→A, A→G, G→S, each of cost 1, with h = 0: what
/// `bidirectional_astar` and `astar` return
pub fn bidirectional_cycle() -> (Option<Found>, Found) {
    let graph = edges(3, &[(0, 1, 1.0), (1, 2, 1.0), (2, 0, 1.0)]);
    let start = Node::new(&graph, 0, 2);
    let goal = Node::new(&graph, 2, 2);
    (
        bidirectional_astar(start.clone(), goal, |_: &Node| 0.0, |_: &Node| 0.0).map(Found::from),
        astar(start, |_: &Node| 0.0).expect("G is reachable").into(),
    )
}

/// The undirected path 0–1–2–3–4 with h = 0: what `bidirectional_astar` and `astar` return
pub fn bidirectional_line() -> (Found, Found) {
    let list: Vec<(usize, usize, f64)> = (0..4)
        .flat_map(|i| [(i, i + 1, 1.0), (i + 1, i, 1.0)])
        .collect();
    let graph = edges(5, &list);
    let start = Node::new(&graph, 0, 4);
    let goal = Node::new(&graph, 4, 4);
    (
        bidirectional_astar(start.clone(), goal, |_: &Node| 0.0, |_: &Node| 0.0)
            .expect("4 is reachable")
            .into(),
        astar(start, |_: &Node| 0.0).expect("4 is reachable").into(),
    )
}

// ---------------------------------------------------------------- P4, Q* and dead ends

/// (cost, expansions, heuristic calls)
pub type Effort = (f64, usize, usize);

/// A*, `qstar_search` and `qstar_two_head` on S→A→G plus `k` dead ends S→D_i→X_i, every edge of cost 1
pub struct DeadEnds {
    pub astar: Effort,
    pub qstar: Effort,
    pub two_head: Effort,
}

/// S = 0, A = 1, G = 2, D_i = 3 + 2i, X_i = 4 + 2i; h(S) = h(A) = 1, h(G) = 0 and 100 on the dead ends
pub fn dead_ends(k: usize) -> DeadEnds {
    let n = 3 + 2 * k;
    let mut list = vec![(0, 1, 1.0)];
    for i in 0..k {
        list.push((0, 3 + 2 * i, 1.0));
        list.push((3 + 2 * i, 4 + 2 * i, 1.0));
    }
    list.push((1, 2, 1.0));
    let graph = edges(n, &list);
    let h: Vec<f64> = (0..n)
        .map(|id| match id {
            0 | 1 => 1.0,
            2 => 0.0,
            _ => 100.0,
        })
        .collect();
    let start = Node::new(&graph, 0, 2);

    let calls = Cell::new(0);
    let a = astar(start.clone(), |node: &Node| {
        calls.set(calls.get() + 1);
        h[node.id]
    })
    .expect("G is reachable");

    let mut q = TabularQ::new(0.0);
    for (id, &value) in h.iter().enumerate() {
        q.set(Node::new(&graph, id, 2), value);
    }
    let one = qstar_search(start.clone(), &q).expect("G is reachable");
    let two = qstar_two_head(start, &q).expect("G is reachable");
    DeadEnds {
        astar: (a.cost, a.nodes_expanded, calls.get()),
        qstar: (one.cost, one.nodes_expanded, one.heuristic_calls),
        two_head: (two.cost, two.nodes_expanded, two.heuristic_calls),
    }
}

// ---------------------------------------------------------------- P5, MCTS against an opponent

/// The root player takes the draw `B` or gambles on `A`, where the opponent picks the root player's `Win` or
/// `Loss`. Rewards are the root player's: 1, 0.5 and 0.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Bet {
    Root,
    A,
    B,
    Win,
    Loss,
}

impl MctsState for Bet {
    type Action = Bet;

    fn legal_actions(&self) -> Vec<Bet> {
        match self {
            Bet::Root => vec![Bet::A, Bet::B],
            Bet::A => vec![Bet::Win, Bet::Loss],
            _ => vec![],
        }
    }

    fn apply(&self, action: &Bet) -> Bet {
        *action
    }

    fn is_terminal(&self) -> bool {
        matches!(self, Bet::B | Bet::Win | Bet::Loss)
    }

    fn reward(&self) -> f64 {
        match self {
            Bet::Win => 1.0,
            Bet::B => 0.5,
            _ => 0.0,
        }
    }
}

/// The same game for IX's `minimax`: the root player maximizes, win +1, draw 0, loss −1
impl GameState for Bet {
    type Move = Bet;

    fn legal_moves(&self) -> Vec<Bet> {
        MctsState::legal_actions(self)
    }

    fn apply_move(&self, m: &Bet) -> Bet {
        *m
    }

    fn is_terminal(&self) -> bool {
        MctsState::is_terminal(self)
    }

    fn is_maximizer_turn(&self) -> bool {
        *self != Bet::A
    }

    fn evaluate(&self) -> f64 {
        match self {
            Bet::Win => 1.0,
            Bet::Loss => -1.0,
            _ => 0.0,
        }
    }
}

/// Whose turn it is, so that an MCTS can score each node for the player who moved into it
pub trait TwoPlayer: MctsState {
    fn root_to_move(&self) -> bool;
}

impl TwoPlayer for Bet {
    fn root_to_move(&self) -> bool {
        *self != Bet::A
    }
}

struct TreeNode<S: MctsState> {
    state: S,
    action: Option<S::Action>,
    visits: f64,
    total: f64,
    children: Vec<usize>,
    parent: Option<usize>,
    untried: Vec<S::Action>,
}

/// IX's MCTS with one change: a node's total is scored for the player who moved into it, the root player's
/// reward r or the opponent's 1 − r (Browne et al. 2012). Random choices come from the course's `Rng`. Returns
/// the most visited root move, the first one on a tie.
pub fn negamax_mcts<S: TwoPlayer>(
    root: &S,
    iterations: usize,
    exploration: f64,
    seed: u64,
) -> Option<S::Action> {
    let mut rng = Rng(seed);
    let mut pick = |n: usize| ((rng.next_f64() * n as f64) as usize).min(n - 1);
    let actions = root.legal_actions();
    if actions.is_empty() {
        return None;
    }
    let mut nodes = vec![TreeNode {
        state: root.clone(),
        action: None,
        visits: 0.0,
        total: 0.0,
        children: Vec::new(),
        parent: None,
        untried: actions,
    }];
    for _ in 0..iterations {
        // selection by UCB1; every child has been visited once when it was expanded
        let mut i = 0;
        while nodes[i].untried.is_empty() && !nodes[i].children.is_empty() {
            let ln_parent = nodes[i].visits.ln();
            let ucb = |c: usize| {
                nodes[c].total / nodes[c].visits
                    + exploration * (ln_parent / nodes[c].visits).sqrt()
            };
            i = *nodes[i]
                .children
                .iter()
                .max_by(|&&a, &&b| ucb(a).partial_cmp(&ucb(b)).expect("finite scores"))
                .expect("children");
        }
        // expansion
        if !nodes[i].untried.is_empty() {
            let k = pick(nodes[i].untried.len());
            let action = nodes[i].untried.swap_remove(k);
            let state = nodes[i].state.apply(&action);
            let untried = if state.is_terminal() {
                Vec::new()
            } else {
                state.legal_actions()
            };
            let child = nodes.len();
            nodes.push(TreeNode {
                state,
                action: Some(action),
                visits: 0.0,
                total: 0.0,
                children: Vec::new(),
                parent: Some(i),
                untried,
            });
            nodes[i].children.push(child);
            i = child;
        }
        // random rollout, scored for the root player
        let mut state = nodes[i].state.clone();
        while !state.is_terminal() {
            let legal = state.legal_actions();
            if legal.is_empty() {
                break;
            }
            state = state.apply(&legal[pick(legal.len())]);
        }
        let reward = state.reward();
        // backpropagation, each node for the player who moved into it
        let mut node = Some(i);
        while let Some(k) = node {
            let parent = nodes[k].parent;
            let root_moved = parent.is_none_or(|p| nodes[p].state.root_to_move());
            nodes[k].visits += 1.0;
            nodes[k].total += if root_moved { reward } else { 1.0 - reward };
            node = parent;
        }
    }
    let mut best: Option<usize> = None;
    for &child in &nodes[0].children {
        if best.is_none_or(|b| nodes[child].visits > nodes[b].visits) {
            best = Some(child);
        }
    }
    best.and_then(|b| nodes[b].action.clone())
}

/// For `seeds` seeds and 2,000 iterations at exploration 1.41: how often IX's `mcts_search` takes the gamble
/// A and how often the course's `negamax_mcts` takes the draw B; then IX's `minimax` move and value
pub struct PartnerGame {
    pub ix_gambles: usize,
    pub negamax_draws: usize,
    pub minimax_move: Option<Bet>,
    pub minimax_value: f64,
}

pub const ITERATIONS: usize = 2_000;
pub const EXPLORATION: f64 = 1.41;

pub fn partner_game(seeds: usize) -> PartnerGame {
    let seeds = (0..seeds as u64).map(|s| 16_500 + s);
    let (mut ix_gambles, mut negamax_draws) = (0, 0);
    for seed in seeds {
        if mcts_search(&Bet::Root, ITERATIONS, EXPLORATION, seed) == Some(Bet::A) {
            ix_gambles += 1;
        }
        if negamax_mcts(&Bet::Root, ITERATIONS, EXPLORATION, seed) == Some(Bet::B) {
            negamax_draws += 1;
        }
    }
    let result = minimax(&Bet::Root, 2);
    PartnerGame {
        ix_gambles,
        negamax_draws,
        minimax_move: result.best_move,
        minimax_value: result.value,
    }
}

// ---------------------------------------------------------------- P6, MCTS ties

thread_local! {
    /// The moves `Draws::apply` has made, in order: with terminal children, that is the expansion order
    static APPLIED: RefCell<Vec<usize>> = const { RefCell::new(Vec::new()) };
}

/// Three moves from the root, each to a terminal draw
#[derive(Clone, Debug)]
pub struct Draws(pub Option<usize>);

impl MctsState for Draws {
    type Action = usize;

    fn legal_actions(&self) -> Vec<usize> {
        if self.0.is_none() {
            vec![0, 1, 2]
        } else {
            vec![]
        }
    }

    fn apply(&self, action: &usize) -> Self {
        APPLIED.with(|log| log.borrow_mut().push(*action));
        Draws(Some(*action))
    }

    fn is_terminal(&self) -> bool {
        self.0.is_some()
    }

    fn reward(&self) -> f64 {
        0.5
    }
}

/// Over `seeds` seeds, 3 iterations each: how often `mcts_search` returns the last child it expanded, and
/// how often the first
pub fn tie_breaks(seeds: usize) -> (usize, usize) {
    let (mut last, mut first) = (0, 0);
    for seed in (0..seeds as u64).map(|s| 16_600 + s) {
        APPLIED.with(|log| log.borrow_mut().clear());
        let chosen = mcts_search(&Draws(None), 3, EXPLORATION, seed);
        let order = APPLIED.with(|log| log.borrow().clone());
        if chosen.as_ref() == order.last() {
            last += 1;
        }
        if chosen.as_ref() == order.first() {
            first += 1;
        }
    }
    (last, first)
}

/// How many moves the last `tie_breaks` seed expanded
pub fn expansions_logged() -> usize {
    APPLIED.with(|log| log.borrow().len())
}

// ---------------------------------------------------------------- P7, what local searches return

/// f(x) = −(x − 10)², neighbours x + 1 then x − 1
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub struct Parabola(pub i32);

impl LocalSearchState for Parabola {
    fn neighbors(&self) -> Vec<Self> {
        vec![Parabola(self.0 + 1), Parabola(self.0 - 1)]
    }

    fn evaluate(&self) -> f64 {
        -((self.0 - 10) as f64).powi(2)
    }
}

/// `beam_search` from the optimum with a beam of 1: (x, f(x)) after `steps` steps
pub fn beam_from_optimum(steps: usize) -> (i32, f64) {
    let (state, value) = beam_search(vec![Parabola(10)], 1, steps);
    (state.0, value)
}

/// `hill_climbing` and `tabu_search` from the optimum, one step each: (x, f(x))
pub fn climbs_from_optimum() -> ((i32, f64), (i32, f64)) {
    let (h, hv) = hill_climbing(Parabola(10), 1);
    let (t, tv) = tabu_search(Parabola(10), 1, 5);
    ((h.0, hv), (t.0, tv))
}

/// `random_restart_hill_climbing` with a generator that always starts at x = 3: (x, value, generator calls)
pub fn restarts_from_three(restarts: usize) -> (i32, f64, usize) {
    let calls = Cell::new(0);
    let generate = || {
        calls.set(calls.get() + 1);
        Parabola(3)
    };
    let (state, value) = random_restart_hill_climbing(generate, 100, restarts);
    (state.0, value, calls.get())
}

// ---------------------------------------------------------------- P8, the 8 queens

thread_local! {
    /// Calls to `Queens::neighbors`: `hill_climbing` makes one per step, plus the one that finds no better move
    static NEIGHBOUR_CALLS: Cell<usize> = const { Cell::new(0) };
}

/// One queen per column; `Queens.0[c]` is the row of column c's queen
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub struct Queens(pub [u8; 8]);

impl Queens {
    /// Eight draws of the course's `Rng`, column by column
    pub fn random(rng: &mut Rng) -> Self {
        let mut rows = [0u8; 8];
        for row in &mut rows {
            *row = (rng.next_f64() * 8.0) as u8;
        }
        Queens(rows)
    }

    /// Pairs on one row or one diagonal, whatever stands between them (Russell and Norvig's h)
    pub fn attacking_pairs(&self) -> usize {
        let q = &self.0;
        let mut pairs = 0;
        for i in 0..8 {
            for j in i + 1..8 {
                if q[i] == q[j] || q[i].abs_diff(q[j]) as usize == j - i {
                    pairs += 1;
                }
            }
        }
        pairs
    }
}

impl LocalSearchState for Queens {
    /// The 56 boards with one queen moved within its column, column by column, rows in increasing order
    fn neighbors(&self) -> Vec<Self> {
        NEIGHBOUR_CALLS.with(|calls| calls.set(calls.get() + 1));
        let mut boards = Vec::with_capacity(56);
        for column in 0..8 {
            for row in 0..8u8 {
                if row != self.0[column] {
                    let mut rows = self.0;
                    rows[column] = row;
                    boards.push(Queens(rows));
                }
            }
        }
        boards
    }

    fn evaluate(&self) -> f64 {
        -(self.attacking_pairs() as f64)
    }
}

/// IX's `hill_climbing` on `boards` random boards from `Rng(16_800)`: how many it solves, and its mean number
/// of steps on the solved and on the stuck ones
pub struct QueensClimb {
    pub boards: usize,
    pub solved: usize,
    pub steps_solved: f64,
    pub steps_stuck: f64,
}

pub fn queens_climb(boards: usize) -> QueensClimb {
    let mut rng = Rng(16_800);
    let (mut solved, mut steps_solved, mut steps_stuck) = (0, 0, 0);
    for _ in 0..boards {
        let board = Queens::random(&mut rng);
        NEIGHBOUR_CALLS.with(|calls| calls.set(0));
        let (_, value) = hill_climbing(board, 100);
        let steps = NEIGHBOUR_CALLS.with(|calls| calls.get()) - 1;
        if value == 0.0 {
            solved += 1;
            steps_solved += steps;
        } else {
            steps_stuck += steps;
        }
    }
    QueensClimb {
        boards,
        solved,
        steps_solved: steps_solved as f64 / solved as f64,
        steps_stuck: steps_stuck as f64 / (boards - solved) as f64,
    }
}

/// `runs` calls of `random_restart_hill_climbing` with `restarts` restarts, boards from `Rng(16_900)`: how
/// many end on a solution
pub fn queens_restarts(runs: usize, restarts: usize) -> usize {
    let rng = RefCell::new(Rng(16_900));
    (0..runs)
        .filter(|_| {
            let generate = || Queens::random(&mut rng.borrow_mut());
            random_restart_hill_climbing(generate, 100, restarts).1 == 0.0
        })
        .count()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn p1_an_admissible_inconsistent_heuristic_returns_a_longer_path() {
        let r = inconsistent();
        assert_eq!(r.inconsistent.cost, 6.0);
        assert_eq!(r.inconsistent.path, vec![0, 2, 3]);
        assert_eq!(r.inconsistent.expanded, 3);
        // control: h = 0, h = h* and ix-graph's Dijkstra all find 5 by S, A, C, G
        for found in [&r.zero, &r.exact] {
            assert_eq!(found.cost, 5.0);
            assert_eq!(found.path, vec![0, 1, 2, 3]);
        }
        assert_eq!(r.dijkstra, 5.0);
    }

    #[test]
    fn p2_weighted_astar_keeps_its_bound_on_mazes() {
        let m = mazes();
        assert!(m.reachable > 0);
        assert!(m.none_iff_unreachable);
        assert!(m.astar_is_dijkstra);
        assert_eq!(m.over_bound, [0, 0, 0]);
        for (ratio, w) in m.worst_ratio.iter().zip(WEIGHTS) {
            assert!(*ratio <= w, "{ratio} > {w}");
        }
        assert!(
            m.mean_expanded[2] < 0.7 * m.mean_expanded[0],
            "{:?}",
            m.mean_expanded
        );
    }

    #[test]
    fn p3_bidirectional_astar_searches_back_along_forward_edges() {
        let (bidirectional, forward) = bidirectional_cycle();
        let bidirectional = bidirectional.expect("a result");
        assert_eq!(bidirectional.cost, 1.0);
        assert_eq!(bidirectional.path, vec![0, 2]);
        assert_eq!(forward.cost, 2.0);
        assert_eq!(forward.path, vec![0, 1, 2]);

        let (line, control) = bidirectional_line();
        assert_eq!(line.path, vec![0, 1, 2, 3, 4]);
        assert_eq!(line.cost, 4.0);
        assert_eq!(line.actions, vec![(0, 1), (1, 2), (3, 2), (4, 3)]);
        assert_eq!(control.actions, vec![(0, 1), (1, 2), (2, 3), (3, 4)]);
    }

    #[test]
    fn p4_single_head_qstar_expands_every_dead_end() {
        let d = dead_ends(100);
        assert_eq!(d.astar, (2.0, 2, 103));
        assert_eq!(d.qstar, (2.0, 102, 103));
        assert_eq!(d.two_head, (2.0, 2, 103));
    }

    #[test]
    fn p5_mcts_plays_the_opponent_as_a_partner() {
        let g = partner_game(20);
        assert_eq!(g.ix_gambles, 20);
        // control: IX's minimax and the course's negamax MCTS take the draw
        assert_eq!(g.minimax_move, Some(Bet::B));
        assert_eq!(g.minimax_value, 0.0);
        assert_eq!(g.negamax_draws, 20);
    }

    #[test]
    fn p6_mcts_ties_go_to_the_last_expanded_child() {
        assert_eq!(tie_breaks(20), (20, 0));
        assert_eq!(expansions_logged(), 3);
    }

    #[test]
    fn p7_beam_search_returns_its_last_beam() {
        assert_eq!(beam_from_optimum(1), (11, -1.0));
        assert_eq!(beam_from_optimum(2), (10, 0.0));
        assert_eq!(beam_from_optimum(101), (11, -1.0));
        // control: hill climbing and tabu search return the optimum they started from
        assert_eq!(climbs_from_optimum(), ((10, 0.0), (10, 0.0)));
        // random restarts: an extra first state scored −∞
        assert_eq!(restarts_from_three(0), (3, f64::NEG_INFINITY, 1));
        assert_eq!(restarts_from_three(5), (10, 0.0, 6));
    }

    #[test]
    fn p8_hill_climbing_solves_about_one_board_in_seven() {
        let q = queens_climb(1_000);
        let rate = q.solved as f64 / q.boards as f64;
        assert!((0.10..=0.18).contains(&rate), "{rate}");
        assert!((3.0..=5.0).contains(&q.steps_solved), "{}", q.steps_solved);
        assert!((2.0..=4.0).contains(&q.steps_stuck), "{}", q.steps_stuck);
        let solved = queens_restarts(100, 20);
        assert!((85..=100).contains(&solved), "{solved}");
    }

    #[test]
    fn a_solved_board_has_no_attacking_pair() {
        // a known solution: rows 0, 4, 7, 5, 2, 6, 1, 3
        assert_eq!(Queens([0, 4, 7, 5, 2, 6, 1, 3]).attacking_pairs(), 0);
        // all eight on one row: every pair attacks
        assert_eq!(Queens([0; 8]).attacking_pairs(), 28);
        assert_eq!(Queens([0; 8]).neighbors().len(), 56);
    }

    #[test]
    fn a_maze_is_the_same_on_every_call_and_keeps_its_corners_open() {
        let a = maze(7);
        assert_eq!(a, maze(7));
        assert!(a[0] && a[MAZE_SIZE * MAZE_SIZE - 1]);
    }
}
