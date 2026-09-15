// examples/l02_structural.ts
import { show } from './show.ts';

interface Point {
  x: number;
  y: number;
}

function length(p: Point): number {
  return Math.hypot(p.x, p.y);
}

// A class never mentions Point, and its instances are Points all the same: only the shape counts
class Vector {
  x: number;
  y: number;
  z = 0;
  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}
show('length(new Vector(3, 4))', length(new Vector(3, 4)));
show('length({ x: 3, y: 4 })', length({ x: 3, y: 4 }));

// interface and type describe the same shape: both names are interchangeable
type PointAlias = { x: number; y: number };
const alias: PointAlias = { x: 6, y: 8 };
const point: Point = alias;
show('length(point)', length(point));

// Two classes with the same shape are the same type, whatever their names say
class Celsius {
  constructor(value: number) {
    this.value = value;
  }
  value: number;
}
class Fahrenheit {
  constructor(value: number) {
    this.value = value;
  }
  value: number;
}
function boils(t: Celsius): boolean {
  return t.value >= 100;
}
show('boils(new Fahrenheit(150))', boils(new Fahrenheit(150)));
const water: Celsius = new Fahrenheit(212);
show('water instanceof Celsius', water instanceof Celsius);

// A branded type: a number that only a function can produce
type Kelvin = number & { readonly brand: 'Kelvin' };
function kelvin(value: number): Kelvin {
  if (value < 0) throw new RangeError('below absolute zero');
  return value as Kelvin; // the one place where the brand is asserted
}
const room = kelvin(293.15);
show('room', room);
show('room - 273.15', room - 273.15);
