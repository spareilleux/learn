// Lesson 2: let, const and Object.freeze
import { attempt, show } from './show.js';

let count = 1;
count = 2; // let: the binding can change
show('count', count);

const settings = { theme: 'dark', tabs: ['lessons'] };
settings.theme = 'light'; // const: the binding can't change, the object can
settings.tabs.push('journal');
show('settings', settings);
attempt('settings = {}', () => {
  settings = {};
});

const frozen = Object.freeze({ theme: 'dark', tabs: ['lessons'] });
attempt("frozen.theme = 'light'", () => {
  frozen.theme = 'light'; // a module is strict code: the assignment throws
});
frozen.tabs.push('journal'); // freeze is shallow
show('frozen', frozen);
