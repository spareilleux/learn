// Lesson 3: this is decided by the call, not by the place where the function is written
import { attempt, show } from './show.js';

function whoAmI() {
  return this?.name;
}
const lesson = { name: 'lesson', whoAmI };
const journal = { name: 'journal' };

// Implicit binding: the object before the dot
show('lesson.whoAmI()', lesson.whoAmI());

// Default binding: a plain call, undefined in strict code (modules and classes)
show('whoAmI()', whoAmI());
const detached = lesson.whoAmI;
show('detached()', detached());

// Explicit binding: call, apply and bind
show('whoAmI.call(journal)', whoAmI.call(journal));
show('whoAmI.apply(journal, [])', whoAmI.apply(journal, []));
const bound = whoAmI.bind(journal);
show('bound()', bound());
lesson.bound = bound;
show('lesson.bound()', lesson.bound());
show('bound.call(lesson)', bound.call(lesson));

// New binding: a new object
function Page(name) {
  this.name = name;
}
show("new Page('index')", new Page('index'));
const BoundPage = Page.bind(journal);
show("new BoundPage('index')", new BoundPage('index'));
show('journal, unchanged', journal);

// Arrow functions have no this of their own: they use the one around them
const site = {
  name: 'site',
  pages: ['mission', 'journal'],
  withArrow() {
    return this.pages.map((page) => `${this.name}/${page}`);
  },
  withFunction() {
    return this.pages.map(function (page) {
      return `${this?.name}/${page}`;
    });
  },
  arrowMethod: () => typeof this,
};
show('site.withArrow()', site.withArrow());
show('site.withFunction()', site.withFunction());
show('site.arrowMethod()', site.arrowMethod());

// A class method passed as a callback loses its object
class Player {
  name = 'GA';
  play() {
    return `${this.name} plays`;
  }
}
const player = new Player();
attempt("['C'].map(player.play)", () => ['C'].map(player.play));
show("['C'].map(() => player.play())", ['C'].map(() => player.play()));
const play = player.play.bind(player);
show("['C'].map(play)", ['C'].map(play));
