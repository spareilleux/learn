// Lesson 2: two lines of GuitarAlchemist/ga, BSPDoomExplorer.tsx at a826864, reduced to plain JavaScript

// Line 4895: the rotation speed of a sample, 0.5 when missing
function speedWithOr(userData) {
  return userData.rotationSpeed || 0.5;
}
function speedWithNullish(userData) {
  return userData.rotationSpeed ?? 0.5;
}
for (const userData of [{}, { rotationSpeed: 0.3 }, { rotationSpeed: 0 }]) {
  console.log(JSON.stringify(userData).padEnd(22), '||', speedWithOr(userData), ' ??', speedWithNullish(userData));
}

// Line 5386: the time since the previous frame, stored as a property of the function itself
function updateFPS(now) {
  const delta = now - updateFPS.lastTime || 0;
  updateFPS.lastTime = now;
  return delta;
}
console.log('first frame ', updateFPS(1000));
console.log('second frame', updateFPS(1016));
console.log('undefined - 1000 =', undefined - 1000, '; NaN || 0 =', NaN || 0);
