import os
import benchmark
import term

// TODO some logic copy pasted from valgrind_test.v and compiler_test.v, move to a module
fn test_x64() {
	if os.user_os() != 'linux' {
		eprintln('x64 tests can only be run on Linux for now.')
		exit(0)
	}
	var bench := benchmark.new_benchmark()
	vexe := os.getenv('VEXE')
	vroot := os.dir(vexe)
	dir := os.join_path(vroot, 'vlib/v/gen/x64/tests')
	files := os.ls(dir) or {
		panic(err)
	}
	//
	wrkdir := os.join_path(os.temp_dir(), 'vtests', 'x64')
	os.mkdir_all(wrkdir)
	os.chdir(wrkdir)
	tests := files.filter(it.ends_with('.vv'))
	if tests.len == 0 {
		println('no x64 tests found')
		assert false
	}
	bench.set_total_expected_steps(tests.len)
	for test in tests {
		bench.step()
		full_test_path := os.real_path(test)
		println('x.v: $wrkdir/x.v')
		os.system('cp ${dir}/${test} $wrkdir/x.v') // cant run .vv file
		x := os.exec('$vexe -o exe -x64 $wrkdir/x.v') or {
			bench.fail()
			eprintln(bench.step_message_fail('x64 $test failed'))
			continue
		}
		res := os.exec('./exe') or {
			bench.fail()
			continue
		}
		if res.exit_code != 0 {
			bench.fail()
			eprintln(bench.step_message_fail('$full_test_path failed to run'))
			eprintln(res.output)
			continue
		}
		var expected := os.read_file('$dir/${test}.out') or {
			panic(err)
		}
		expected = expected.trim_space().trim('\n').replace('\r\n', '\n')
		found := res.output.trim_space().trim('\n').replace('\r\n', '\n')
		if expected != found {
			println(term.red('FAIL'))
			println('============')
			println('expected:')
			println(expected)
			println('============')
			println('found:')
			println(found)
			println('============\n')
			bench.fail()
			continue
		}
		bench.ok()
		eprintln(bench.step_message_ok('testing file: $test'))
	}
	bench.stop()
	eprintln(term.h_divider('-'))
	eprintln(bench.total_message('x64'))
	if bench.nfail > 0 {
		exit(1)
	}
}

