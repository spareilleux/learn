// Lesson 4: class, fields, private members, accessors and inheritance
import { attempt, show } from './show.js';

class Lesson {
  static count = 0;
  title; // public field: an own property of each instance
  #minutes = 0; // private field: unreachable outside the class body

  constructor(title, minutes) {
    this.title = title;
    this.minutes = minutes; // calls the setter
    Lesson.count++;
  }

  get minutes() {
    return this.#minutes;
  }

  set minutes(value) {
    if (!Number.isInteger(value) || value < 0) {
      throw new RangeError(`minutes must be a non-negative integer, got ${value}`);
    }
    this.#minutes = value;
  }

  describe() {
    return `${this.title} (${this.#minutes} min)`;
  }

  static isLesson(value) {
    return #minutes in value; // does value have this class's private field?
  }
}

class Exercise extends Lesson {
  constructor(title, minutes, solution) {
    super(title, minutes);
    this.solution = solution;
  }

  describe() {
    return `${super.describe()}, with a solution`;
  }
}

const values = new Lesson('Values and types', 25);
const quiz = new Exercise('Coercions', 10, 'details');
show('values.describe()', values.describe());
show('quiz.describe()', quiz.describe());
show('values', values);
show('Object.keys(quiz)', Object.keys(quiz));
show('Lesson.count', Lesson.count);
attempt("values.minutes = 'ten'", () => {
  values.minutes = 'ten';
});
show('values.minutes', values.minutes);

// Underneath: a function, and methods on its prototype
show('typeof Lesson', typeof Lesson);
show("Object.hasOwn(values, 'describe')", Object.hasOwn(values, 'describe'));
const proto = Lesson.prototype;
show('values.describe === proto.describe', values.describe === proto.describe);
show('quiz.describe === proto.describe', quiz.describe === proto.describe);
show('quiz instanceof Lesson', quiz instanceof Lesson);
attempt("Lesson('no new')", () => Lesson('no new'));

// Private fields are checked by the engine, not hidden by convention
show('Lesson.isLesson(quiz)', Lesson.isLesson(quiz));
show('Lesson.isLesson({ minutes: 5 })', Lesson.isLesson({ minutes: 5 }));
show("Object.hasOwn(values, '#minutes')", Object.hasOwn(values, '#minutes'));
show('JSON.stringify(values)', JSON.stringify(values));
attempt('proto.describe.call({ title })', () => proto.describe.call({ title: 'fake' }));
