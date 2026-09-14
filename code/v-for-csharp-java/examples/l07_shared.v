// Lesson 7: shared, lock and rlock, on the package references of GuitarAlchemist/ga
// Lines starting with "# " depend on timing: check.sh prints them without comparing them.
import arrays
import os

struct Usage {
mut:
	by_package map[string]int
}

fn count_packages(shared usage Usage, lines []string) {
	for line in lines {
		package := line.split(',')[1]
		lock usage {
			usage.by_package[package]++
		}
	}
}

struct Counter {
mut:
	n int
}

// A mutable reference, without a lock: V compiles it
fn add_unsafely(mut c Counter, times int) {
	for _ in 0 .. times {
		c.n++
	}
}

fn add_shared(shared c Counter, times int) {
	for _ in 0 .. times {
		lock c {
			c.n++
		}
	}
}

fn main() {
	lines := os.read_lines('data/ga/package_refs.csv')![1..]

	// Four threads, one map, one lock
	shared usage := Usage{}
	mut threads := []thread{}
	chunk := (lines.len + 3) / 4
	for start := 0; start < lines.len; start += chunk {
		end := if start + chunk < lines.len { start + chunk } else { lines.len }
		threads << spawn count_packages(shared usage, lines[start..end])
	}
	threads.wait()
	rlock usage {
		println('${usage.by_package.len} packages, ${usage.by_package['Spectre.Console']} references to Spectre.Console')
	}
	// rlock and lock are expressions too
	counts := rlock usage {
		usage.by_package.values()
	}
	println('references: ${arrays.sum(counts)!}')

	// A data race: the result changes from one run to the next
	mut racy := &Counter{}
	mut racers := []thread{}
	for _ in 0 .. 8 {
		racers << spawn add_unsafely(mut racy, 100_000)
	}
	racers.wait()
	println('# without a lock: ${racy.n} of 800000')

	shared safe := Counter{}
	mut lockers := []thread{}
	for _ in 0 .. 8 {
		lockers << spawn add_shared(shared safe, 100_000)
	}
	lockers.wait()
	n := rlock safe {
		safe.n
	}
	println('with lock: ${n} of 800000')

	// A closure captures a copy, even with mut
	mut captured := 0
	h := spawn fn [mut captured] () int {
		captured += 42
		return captured
	}()
	println('in the thread: ${h.wait()}, in main: ${captured}')
}
