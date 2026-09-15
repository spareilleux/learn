// Lesson 4, exercise 2: a private field, a pair of accessors, a static factory and toJSON
class Temperature {
  #celsius;

  constructor(celsius) {
    this.#celsius = celsius;
  }

  static fromFahrenheit(fahrenheit) {
    return new Temperature(((fahrenheit - 32) * 5) / 9);
  }

  get fahrenheit() {
    return (this.#celsius * 9) / 5 + 32;
  }

  set fahrenheit(value) {
    this.#celsius = ((value - 32) * 5) / 9;
  }

  toJSON() {
    return { celsius: this.#celsius };
  }
}

const room = new Temperature(20);
console.log(room.fahrenheit);
room.fahrenheit = 212;
console.log(JSON.stringify(room));
console.log(JSON.stringify(Temperature.fromFahrenheit(32)));
console.log(Object.keys(room), room);
