// Lesson 3, exercise 1: keep var, but give each function its own copy of i
const withParameter = [];
for (var i = 0; i < 3; i++) {
  withParameter.push(((copy) => () => copy)(i)); // the parameter is a new variable at each call
}
console.log(withParameter.map((f) => f()));

const withBind = [];
for (var j = 0; j < 3; j++) {
  withBind.push(((value) => value).bind(null, j)); // bind stores the value the argument has now
}
console.log(withBind.map((f) => f()));
