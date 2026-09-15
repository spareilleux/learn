// Lesson 2: the type is carried by the value, and typeof reads it
import { show } from './show.js';

let value = 42;
show('typeof value', typeof value);
value = 'forty-two'; // no error: the variable has no type
show('typeof value', typeof value);

show('typeof undefined', typeof undefined);
show('typeof true', typeof true);
show('typeof 3.14', typeof 3.14);
show('typeof 10n', typeof 10n);
show("typeof 'text'", typeof 'text');
show('typeof Symbol()', typeof Symbol());
show('typeof {}', typeof {});
show('typeof []', typeof []);
show('typeof null', typeof null);
show('typeof (() => 1)', typeof (() => 1));
show('Array.isArray([])', Array.isArray([]));
