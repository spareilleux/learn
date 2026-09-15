// Lesson 4: the prototype chain, what class is built on
import { show } from './show.js';

const base = {
  kind: 'page',
  describe() {
    return `${this.title} is a ${this.kind}`;
  },
};
const mission = Object.create(base); // mission's prototype is base
mission.title = 'Mission';

show('mission.describe()', mission.describe());
show('Object.keys(mission)', Object.keys(mission));
show("Object.hasOwn(mission, 'kind')", Object.hasOwn(mission, 'kind'));
const { getPrototypeOf } = Object;
show('getPrototypeOf(mission) === base', getPrototypeOf(mission) === base);

// Reading walks up the chain; writing creates an own property that hides the prototype's
mission.kind = 'lesson';
show('mission.describe()', mission.describe());
show('base.kind', base.kind);

// A change to the prototype is seen by every object that inherits from it, even existing ones
const journal = Object.create(base);
journal.title = 'Journal';
base.describe = function () {
  return `${this.title}, ${this.kind}, changed at run time`;
};
show('journal.describe()', journal.describe());

// The end of the chain
show('getPrototypeOf(base)', getPrototypeOf(base));
show('getPrototypeOf(Object.prototype)', getPrototypeOf(Object.prototype));
const dictionary = Object.create(null);
show("'toString' in {}", 'toString' in {});
show("'toString' in dictionary", 'toString' in dictionary);
