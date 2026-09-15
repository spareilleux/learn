// solutions/l03_ex1_graph_ids.ts
declare const brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [brand]: B };
type NodeId = Brand<string, 'NodeId'>;
type EdgeId = Brand<string, 'EdgeId'>;

interface GovernanceNode {
  id: NodeId;
  name: string;
}
interface GovernanceEdge {
  id: EdgeId;
  source: NodeId;
  target: NodeId;
}

// GA's GraphIndex in DataLoader.ts, with the ids told apart: in GA, all five maps are keyed by string
interface GraphIndex {
  nodeMap: Map<NodeId, GovernanceNode>;
  outEdges: Map<NodeId, GovernanceEdge[]>;
  connectedEdges: Map<NodeId, Set<EdgeId>>;
}

// The data comes from JSON: the ids are branded once, where the graph is read
function readGraph(raw: { nodes: { id: string; name: string }[]; edges: { id: string; source: string; target: string }[] }) {
  const nodes = raw.nodes.map((n): GovernanceNode => ({ id: n.id as NodeId, name: n.name }));
  const edges = raw.edges.map((e): GovernanceEdge => ({ id: e.id as EdgeId, source: e.source as NodeId, target: e.target as NodeId }));
  return { nodes, edges };
}

function buildGraphIndex(graph: { nodes: GovernanceNode[]; edges: GovernanceEdge[] }): GraphIndex {
  const index: GraphIndex = { nodeMap: new Map(), outEdges: new Map(), connectedEdges: new Map() };
  for (const node of graph.nodes) index.nodeMap.set(node.id, node);
  for (const edge of graph.edges) {
    index.outEdges.set(edge.source, [...(index.outEdges.get(edge.source) ?? []), edge]);
    for (const end of [edge.source, edge.target]) {
      index.connectedEdges.set(end, (index.connectedEdges.get(end) ?? new Set()).add(edge.id));
    }
  }
  return index;
}

const graph = readGraph({
  nodes: [{ id: 'constitution', name: 'Constitution' }, { id: 'policy-7', name: 'Alignment policy' }],
  edges: [{ id: 'e1', source: 'constitution', target: 'policy-7' }],
});
const index = buildGraphIndex(graph);
const edge = graph.edges[0]!;
console.log(index.nodeMap.get(edge.target)?.name, [...(index.connectedEdges.get(edge.source) ?? [])]);

function mistakes() {
  // @ts-expect-error: an edge id is not a node id
  index.nodeMap.get(edge.id);
  // @ts-expect-error: a plain string is not a node id
  index.outEdges.get('constitution');
}
console.log(typeof mistakes);
