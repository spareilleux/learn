// errors/l02_null.ts
function initial(name?: string): string {
  return name.charAt(0);
}

const tunings = new Map([['standard', 'EADGBE']]);
const dropD: string = tunings.get('drop D');

let capo: number = null;
console.log(initial(), dropD.length, capo);
