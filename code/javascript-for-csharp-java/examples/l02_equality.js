// Lesson 2: == converts its operands before comparing, === doesn't
import { show } from './show.js';

show("'0' == 0", '0' == 0);
show("'' == 0", '' == 0);
show("'' == '0'", '' == '0');
show("'1' === 1", '1' === 1);
show('true == 1', true == 1);
show("true == 'true'", true == 'true');
show('[] == false', [] == false);
show('[0] == false', [0] == false);
show("[1, 2] == '1,2'", [1, 2] == '1,2');
show('null == 0', null == 0);
show('null >= 0', null >= 0);
show('undefined == 0', undefined == 0);
show('NaN == NaN', NaN == NaN);

// The one common use of ==: null or undefined in a single test
for (const value of [null, undefined, 0, '', false]) {
  show(`${String(value) || "''"} == null`, value == null);
}
