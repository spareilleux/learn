// Lesson 3: hoisting, var and the temporal dead zone
import { attempt, show } from './show.js';

// A function declaration can be called before its line
show('square(4)', square(4));
function square(n) {
  return n * n;
}

// var is hoisted with the value undefined, for the whole function
function withVar() {
  const before = total;
  var total = 10;
  return [before, total];
}
show('withVar()', withVar());

// let, const and class are hoisted too, but reading them before their line throws
function withLet() {
  const before = total;
  let total = 10;
  return [before, total];
}
attempt('withLet()', withLet);
attempt('typeof total, in the TDZ', () => {
  const kind = typeof total;
  let total = 1;
  return kind;
});
show('typeof neverDeclared', typeof neverDeclared);
attempt('new Later()', () => new Later());
class Later {}

// var has no block scope: the if doesn't contain it
function blocks() {
  if (true) {
    var fromVar = 'visible';
    let fromLet = 'hidden';
  }
  return [fromVar, typeof fromLet];
}
show('blocks()', blocks());
