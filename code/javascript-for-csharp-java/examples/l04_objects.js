// Lesson 4: an object is a set of properties that can change at run time
import { show } from './show.js';

const page = { title: 'Mission', order: 0 };
page.locale = 'en'; // add
delete page.order; // remove
show('page', page);
show('page.author', page.author);
show("'title' in page", 'title' in page);
show("Object.hasOwn(page, 'title')", Object.hasOwn(page, 'title'));

// Property names are strings (or symbols): other keys are converted
const grid = {};
grid[1] = 'one';
grid['1'] = 'one, again';
grid[{ x: 1 }] = 'an object';
grid[{ y: 2 }] = 'another object';
show('grid', grid);

// Order: integer-like keys first, in ascending order, then the others in insertion order
const lessons = { journal: 99, 10: 'ten', index: 0, 2: 'two' };
show('Object.keys(lessons)', Object.keys(lessons));

// Shorthand properties, computed names and methods
const field = 'draft';
const title = 'Values and types';
const lesson = {
  title,
  [field]: true,
  describe() {
    return `${this.title} (${this.draft ? 'draft' : 'published'})`;
  },
};
show('lesson.describe()', lesson.describe());
show('Object.entries(lesson)', Object.entries(lesson));
