// Lesson 3: at the top level of a module, two functions with the same name are a syntax error
function describe(page) {
  return `page ${page}`;
}
function describe(page, locale) {
  return `page ${page} in ${locale}`;
}
console.log(describe('mission'));
