import 'dart:io';

void main() {
  var list = ['MG1', 'MG20508', 'MG20509', 'MG44', 'MG020'];
  list.sort((a, b) {
    if (a.length != b.length) {
      return a.length.compareTo(b.length);
    }
    return a.compareTo(b);
  });
  print(list.reversed.toList());
}
