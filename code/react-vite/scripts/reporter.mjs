// A Vitest reporter for the course's expected outputs: every test in file order, with its result and what it printed.
// Vitest's own reporters print console output as it arrives, grouped by timing, which differs between machines.
// npx vitest run src/l03/Capo.test.tsx --reporter=./scripts/reporter.mjs
export default class CourseReporter {
  logs = new Map();

  onUserConsoleLog(log) {
    const logs = this.logs.get(log.taskId) ?? [];
    logs.push(log);
    this.logs.set(log.taskId, logs);
  }

  onTestRunEnd(testModules, unhandledErrors) {
    const lines = [];
    for (const testModule of testModules) {
      for (const test of testModule.children.allTests()) {
        const { state, errors = [] } = test.result();
        lines.push(`${{ passed: '✓', failed: '×', skipped: '-' }[state] ?? state} ${test.fullName}`);
        for (const log of this.logs.get(test.id) ?? []) {
          const text = log.content.replace(/\n$/, '');
          lines.push(...(log.type === 'stderr' ? `console.error: ${text}` : text).split('\n').map((line) => `  ${line}`));
        }
        for (const error of errors) lines.push(`  ${error.name}: ${error.message}`);
      }
      for (const error of testModule.errors()) lines.push(`× ${testModule.moduleId}: ${error.message}`);
    }
    for (const error of unhandledErrors) lines.push(`× unhandled: ${error.message}`);
    console.log(lines.join('\n'));
  }
}
