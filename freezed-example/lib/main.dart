import 'models.dart';

void main() {
  final myClassexample = MyClass(a: '42', b: 42);

  // clone
  print(myClassexample.copyWith(a: null)); // MyClass(a: null, b: 42)
  print(myClassexample.copyWith()); // MyClass(a: '42', b: 42)

  // ------------------

  // == override
  print(MyClass(a: '42', b: 42) == MyClass(a: '42', b: 42)); // true
  print(MyClass(a: '42', b: 42) == MyClass()); // false

  // ------------------

  // destructuring pattern-matching
  const unionExample = Union.complex(1, "2");
  print(
    // `when` requires all callbacks to be not null
    unionExample.when(
      (value) => '$value',
      loading: () => 'loading',
      error: (message) => 'Error: $message',
      complex: (a, b) => 'complex $a $b',
    ),
  ); // 42

  print(
    // maybeWhen allows some callbacks to be missing, but requires an `orElse` callback
    unionExample.maybeWhen(
      null,
      loading: () => 'loading',
      // voluntarily didn't pass error/complex callbacks
      orElse: () => 42,
    ),
  ); // 42

  // ------------------

  // non-destructuring pattern-matching
  // works the same as `when`, but the callback is slightly different
  print(
    // `map` requires all callbacks to be not null
    unionExample.map(
      (Data value) => '$value',
      loading: (Loading value) => 'loading',
      error: (ErrorDetails error) => 'Error: ${error.message}',
      complex: (Complex value) => 'complex ${value.a} ${value.b}',
    ),
  ); // 42

  print(
    // maybeMap allows some callbacks to be missing, but requires an `orElse` callback
    unionExample.maybeMap(
      null,
      error: (ErrorDetails value) => value.message,
      // voluntarily didn't pass error/complex callbacks
      orElse: () => 'fallthrough',
    ),
  ); // fallthrough

  // ------------------

  // nice toString
  print(const Union(42)); // Union(value: 42)
  print(const Union.loading()); // Union.loading()
  print(const Union.error(
      'Failed to fetch')); // Union.error(message: Failed to fetch)

  // ------------------

  // shared properties between union possibilities
  var example = SharedProperty.person(name: 'Remi', age: 24);
  // OK, `name` is shared between both .person and .city constructor
  print(example.name); // Remi
  example = SharedProperty.city(name: 'London', population: 8900000);
  print(example.name); // London

  // COMPILE ERROR
  // print(example.age);
  // print(example.population);
  print(
    example.map(
      person: (value) => {value.age},
      city: (value) => {value.population},
    ),
  );
}
