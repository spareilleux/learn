// Lesson 3: three ways GuitarAlchemist/ga keeps this in event listeners (at a826864), with Node's EventTarget
const target = new EventTarget();
const ping = () => target.dispatchEvent(new Event('ping'));

// A method passed as is: this is the EventTarget, not the object
class Naive {
  count = 0;
  onPing() {
    this.count++;
  }
  start() {
    target.addEventListener('ping', this.onPing);
  }
}

// LunarLanderEngine.ts: bind once, keep the bound function to remove it later
class BindOnce {
  count = 0;
  constructor() {
    this.boundPing = this.onPing.bind(this);
  }
  onPing() {
    this.count++;
  }
  start() {
    target.addEventListener('ping', this.boundPing);
  }
  stop() {
    target.removeEventListener('ping', this.boundPing);
  }
}

// InteractionHandler.ts: an arrow function in a class field, one per instance
class ArrowField {
  count = 0;
  onPing = () => {
    this.count++;
  };
  start() {
    target.addEventListener('ping', this.onPing);
  }
  stop() {
    target.removeEventListener('ping', this.onPing);
  }
}

// The mistake the three avoid: bind creates a new function, so this remove removes nothing
class BindTwice {
  count = 0;
  onPing() {
    this.count++;
  }
  start() {
    target.addEventListener('ping', this.onPing.bind(this));
  }
  stop() {
    target.removeEventListener('ping', this.onPing.bind(this));
  }
}

const naive = new Naive();
naive.start();
const listeners = [new BindOnce(), new ArrowField(), new BindTwice()];
for (const listener of listeners) listener.start();
ping();
for (const listener of listeners) listener.stop();
ping();

console.log('Naive.count     ', naive.count, '; target.count', target.count);
for (const listener of listeners) {
  console.log(`${listener.constructor.name}.count`.padEnd(16), listener.count);
}
console.log('bind returns a new function each time:', naive.onPing.bind(naive) === naive.onPing.bind(naive));
