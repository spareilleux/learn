// GitHub Actions course, lesson 10, exercise: require() in a repository whose package.json says "type": "module"
const fs = require("node:fs");

function input(name, { required = false } = {}) {
  const variable = `INPUT_${name.replace(/ /g, "_").toUpperCase()}`;
  const value = (process.env[variable] ?? "").trim();
  if (required && value === "") {
    throw new Error(`Input required and not supplied: ${name}`);
  }
  return value;
}

function slugify(text) {
  return text
    .normalize("NFD")
    .replace(/\p{Mn}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

try {
  const text = input("text", { required: true });
  const maxLength = Number(input("max-length") || "0");
  let slug = slugify(text);
  if (maxLength > 0) {
    slug = slug.slice(0, maxLength).replace(/-+$/, "");
  }
  console.log(`slug of "${text}" is "${slug}"`);
  fs.appendFileSync(process.env.GITHUB_OUTPUT, `slug=${slug}\n`);
} catch (error) {
  console.log(`::error::${error.message}`);
  process.exitCode = 1;
}
