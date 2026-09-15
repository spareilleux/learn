// Lesson 2, exercise 3: the answers, printed by Node.js
import { show } from '../examples/show.js';

show("'2' + 2 * '2'", '2' + 2 * '2');
show('null + 1', null + 1);
show('undefined + 1', undefined + 1);
show('[] == ![]', [] == ![]);
show("'b' + 'a' + +'a' + 'a'", 'b' + 'a' + +'a' + 'a');
show('0.1 * 3 === 0.3', 0.1 * 3 === 0.3);
show('10n ** 400n > Number.MAX_VALUE', 10n ** 400n > Number.MAX_VALUE);
