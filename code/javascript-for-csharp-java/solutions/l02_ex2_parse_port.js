// Lesson 2, exercise 2: parsePort accepts a string of digits between 1 and 65535, and throws otherwise
function parsePort(text) {
  if (typeof text !== 'string' || !/^\d+$/.test(text)) {
    throw new TypeError(`not a port: ${JSON.stringify(text)}`);
  }
  const port = Number(text);
  if (port < 1 || port > 65535) {
    throw new RangeError(`port out of range: ${port}`);
  }
  return port;
}

for (const text of ['8080', '443', '', ' 80', '8080abc', '0x50', '1e3', '70000', '0', 8080]) {
  try {
    console.log(JSON.stringify(text).padEnd(10), parsePort(text));
  } catch (err) {
    console.log(JSON.stringify(text).padEnd(10), `${err.name}: ${err.message}`);
  }
}
