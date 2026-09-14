// An external test: it imports the module, and sees only its public API
import deps
import os

const data = os.join_path(@VMODROOT, '..', 'data', 'ga')

fn testsuite_begin() {
	assert os.exists(data)
}

fn test_every_version_parses() ! {
	lines := os.read_lines(os.join_path(data, 'package_refs.csv'))!
	mut floating := []string{}
	for line in lines[1..] {
		f := line.split(',')
		v := deps.parse_version(f[2])!
		if v is deps.Floating {
			floating << f[1]
		}
	}
	assert floating == ['ModelContextProtocol', 'Microsoft.AspNetCore.SpaProxy']
}

fn test_gacli_references() ! {
	g := deps.Graph.parse(os.read_lines(os.join_path(data, 'project_refs.csv'))!)!
	reachable := g.reachable('Apps/GaCli/GaCli.fsproj')
	assert reachable.len == 7
	assert 'Common/GA.Core/GA.Core.csproj' in reachable
}
