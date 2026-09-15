// Lesson 2: strings are immutable sequences of UTF-16 code units, like string in C# and String in Java
import { attempt, show } from './show.js';

const course = 'JavaScript';
show('course.length', course.length);
show('course[4]', course[4]);
show('course.at(-1)', course.at(-1));
show('`${course} for C#`', `${course} for C#`);
attempt("course[0] = 'X'", () => {
  course[0] = 'X';
});
show("'é'.length", 'é'.length);
show("'e\\u0301'.length", 'é'.length);
show("'é' === 'e\\u0301'", 'é' === 'é');
show("'e\\u0301'.normalize() === 'é'", 'é'.normalize() === 'é');
show("'🎸'.length", '🎸'.length);
show("[...'🎸'].length", [...'🎸'].length);
show("'🎸'.codePointAt(0)", '🎸'.codePointAt(0));
show("'b' > 'a'", 'b' > 'a');
show("'B' > 'a'", 'B' > 'a');
show("'10' < '9'", '10' < '9');
