// An ES module: what it exports is declared with export, everything else stays private to the file
const punctuation = '!';

export function hello(name) {
  return `Hello, ${capitalize(name)}${punctuation}`;
}

export default function farewell(name) {
  return `Bye, ${capitalize(name)}${punctuation}`;
}

function capitalize(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
}
