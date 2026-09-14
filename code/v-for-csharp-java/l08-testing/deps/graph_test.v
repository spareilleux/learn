module deps

const sample = ['from,to', 'App,Core', 'App,Domain', 'Domain,Core', 'Tests,App']

fn test_reachable() ! {
	g := Graph.parse(sample)!
	assert g.reachable('Tests') == ['App', 'Core', 'Domain']
	assert g.reachable('Core') == []
}

fn test_parse_errors() {
	if _ := Graph.parse(['project,reference']) {
		assert false, 'a wrong header is accepted'
	} else {
		assert err.msg() == 'expected the header from,to'
	}
	Graph.parse(['from,to', 'App']) or {
		assert err.msg() == 'line 2: expected 2 fields, got 1'
		return
	}
	assert false
}
