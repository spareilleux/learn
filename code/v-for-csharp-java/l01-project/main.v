module main

import os
import greet

fn main() {
	names := if os.args.len > 1 { os.args[1..] } else { ['world'] }
	for name in names {
		println(greet.hello(name))
	}
}
