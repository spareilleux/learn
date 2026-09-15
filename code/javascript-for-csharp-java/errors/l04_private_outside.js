// Lesson 4: reading a private field outside its class is rejected before the module runs
class Lesson {
  #minutes = 25;
}
console.log('this line never runs');
console.log(new Lesson().#minutes);
