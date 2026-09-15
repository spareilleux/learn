// Lesson 4: objects are compared by reference, and copies are shallow unless you ask
import { attempt, show } from './show.js';

const a = { x: 1, y: 2 };
const b = { x: 1, y: 2 };
show('a === b', a === b);
show('a === a', a === a);

// Map and Set use the same identity: two equal-looking keys are two keys
const visits = new Map();
visits.set({ x: 1, y: 2 }, 'first');
visits.set({ x: 1, y: 2 }, 'second');
show('visits.size', visits.size);
show('visits.get({ x: 1, y: 2 })', visits.get({ x: 1, y: 2 }));
const byKey = new Map([[`${a.x},${a.y}`, 'first']]);
show("byKey.get('1,2')", byKey.get('1,2'));

// Spread and Object.assign copy one level
const course = { title: 'JavaScript', tags: ['node'], created: new Date(Date.UTC(2026, 8, 14)) };
const shallow = { ...course };
shallow.title = 'TypeScript';
shallow.tags.push('typescript');
show('course.title', course.title);
show('course.tags', course.tags);

// structuredClone copies the whole graph: Map, Set, Date, cycles
const deep = structuredClone(course);
deep.tags.push('react');
show('course.tags', course.tags);
show('deep.created instanceof Date', deep.created instanceof Date);

// but not functions, and not the prototype of a class instance
class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
  length() {
    return Math.hypot(this.x, this.y);
  }
}
const cloned = structuredClone(new Point(3, 4));
show('cloned', cloned);
show('cloned instanceof Point', cloned instanceof Point);
attempt('structuredClone({ f() {} })', () => structuredClone({ f() {} }));

// JSON.parse(JSON.stringify(...)) loses more
const viaJson = JSON.parse(JSON.stringify({ ...course, draft: undefined }));
show('viaJson', viaJson);

// Object.freeze is shallow too
const frozen = Object.freeze({ tags: ['node'] });
frozen.tags.push('still mutable');
show('frozen.tags', frozen.tags);
