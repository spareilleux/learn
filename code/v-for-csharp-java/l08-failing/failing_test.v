// Tests that fail on purpose, to read V's reports: check.sh expects exit code 1
import strconv

fn testsuite_begin() {
	println('testsuite_begin')
}

fn testsuite_end() {
	println('testsuite_end')
}

fn test_values() {
	parts := '9.5'.split('.').map(strconv.atoi(it) or { -1 })
	assert parts == [9, 5, 1]
	println('not printed: the test stops at the first failed assert')
}

fn test_message() {
	for s in ['9.5.1', '9.5', '1.0.0-beta.1'] {
		assert s.split('.').len == 3, 'version ${s}'
	}
}

fn test_propagated_error() ! {
	lines := strconv.atoi('n/a')!
	assert lines > 0
}

@[assert_continues]
fn test_continues() {
	for s in ['9.5.1', '0.*', '8.*-*'] {
		assert !s.contains('*'), s
	}
	println('printed: assert_continues goes on after a failure')
}

fn test_passes() {
	assert '9.5.1'.split('.').len == 3
}
