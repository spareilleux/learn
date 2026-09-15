// A CommonJS module: what it exports is whatever ends up in module.exports
const punctuation = '!';

function hello(name) {
  return `Hello, ${capitalize(name)}${punctuation}`;
}

function capitalize(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
}

module.exports = { hello };
