// Lesson 2: implicit conversions with +, -, if, and the parsing functions
import { show } from './show.js';

show("'1' + 2", '1' + 2);
show("1 + 2 + '3'", 1 + 2 + '3');
show("'3' - 1", '3' - 1);
show("'5' * '2'", '5' * '2');
show("'3' + -'1'", '3' + -'1');
show('[] + []', [] + []);
show('[] + {}', [] + {});
show("+'42'", +'42');

// Parsing: Number reads the whole string, parseInt stops at the first invalid character
show("Number('')", Number(''));
show("Number(' 12 ')", Number(' 12 '));
show("Number('12px')", Number('12px'));
show("parseInt('12px', 10)", parseInt('12px', 10));
show("parseInt('', 10)", parseInt('', 10));
show("parseInt('0x1F')", parseInt('0x1F'));
show("parseInt('1e3', 10)", parseInt('1e3', 10));
show("Number('1e3')", Number('1e3'));
show('parseInt(0.0000005)', parseInt(0.0000005));

// Truthy and falsy: if converts any value to a boolean
const values = [false, 0, -0, 0n, '', null, undefined, NaN, '0', 'false', [], {}, -1];
const falsy = values.filter((v) => !v);
const truthy = values.filter((v) => v);
show('falsy', falsy);
show('truthy', truthy);
