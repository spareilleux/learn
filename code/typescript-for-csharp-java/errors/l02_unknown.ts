// errors/l02_unknown.ts
const options: unknown = JSON.parse('{"stars": "yes"}');
const stars: boolean = options.stars;
const copy: boolean = options;

console.log(stars, copy);
