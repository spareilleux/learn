// Lesson 8, exercise 1: a cycle of references
module deps

fn test_cycle() ! {
	g := Graph.parse(['from,to', 'A,B', 'B,A'])!
	assert g.reachable('A') == ['A', 'B']
	assert g.reachable('B') == ['A', 'B']
}
