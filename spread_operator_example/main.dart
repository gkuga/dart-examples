void main() {
  var numbers = [1, 2, 3];
  var numbers2;
  var numbers3 = [0, ...numbers, ...?numbers2];
  print(numbers3);
  print([
    if (true) ...[0, ...numbers, ...?numbers2]
  ]);
}
