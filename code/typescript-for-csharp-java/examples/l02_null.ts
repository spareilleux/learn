// examples/l02_null.ts
import { attempt, show } from './show.ts';

function initial(name?: string): string {
  return name === undefined ? '?' : name.charAt(0); // narrowed: name is a string in the second branch
}
show('initial()', initial());
show("initial('Ada')", initial('Ada'));

const tunings = new Map([['standard', 'EADGBE']]);
show("tunings.get('drop D')?.length", tunings.get('drop D')?.length);
show("tunings.get('drop D') ?? 'DADGBE'", tunings.get('drop D') ?? 'DADGBE');

// The non-null assertion ! silences tsc, and checks nothing
attempt("tunings.get('drop D')!.length", () => tunings.get('drop D')!.length);
