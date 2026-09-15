// Lesson 3, exercise 2: once returns a function that calls fn the first time only, with its this and arguments
function once(fn) {
  let called = false;
  let result;
  return function (...args) {
    if (!called) {
      called = true;
      result = fn.apply(this, args);
    }
    return result;
  };
}

const player = {
  starts: 0,
  start: once(function (label) {
    this.starts++;
    return `${label} started`;
  }),
};
console.log(player.start('first'));
console.log(player.start('second'));
console.log('starts:', player.starts);
