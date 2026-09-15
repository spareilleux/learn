// Lesson 3, exercise 3: the answers, printed by Node.js
import { attempt, show } from '../examples/show.js';

class Tuner {
  note = 'E';
  read() {
    return this.note;
  }
  readArrow = () => this.note;
}
const tuner = new Tuner();
const other = new Tuner();

const { read, readArrow } = tuner;
attempt('read()', () => read());
show('readArrow()', readArrow());
show("read.call({ note: 'A' })", read.call({ note: 'A' }));
show("readArrow.call({ note: 'A' })", readArrow.call({ note: 'A' }));
show('tuner.read === other.read', tuner.read === other.read);
show('readArrow === other.readArrow', readArrow === other.readArrow);
