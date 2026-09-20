class ArabicTransliterator {
  static String transliterate(String input) {
    if (input.isEmpty) return input;
    
    // Multi-character rules
    String out = input
      .replaceAll('y--', 'ئ')
      .replaceAll('w--', 'ؤ')
      .replaceAll('a--', 'إ')
      .replaceAll('-a', 'أ')
      .replaceAll('--a', 'ءا')
      .replaceAll('aa', 'آ')
      .replaceAll('la', 'لا')
      .replaceAll('t\'', 'ث')
      .replaceAll('H\'', 'خ')
      .replaceAll('d\'', 'ذ')
      .replaceAll('s\'', 'ش')
      .replaceAll('S\'', 'ض')
      .replaceAll('T\'', 'ظ')
      .replaceAll('g\'', 'غ')
      .replaceAll('q\'', 'ڨ')
      .replaceAll('k\'', 'ڭ')
      .replaceAll('b\'', 'پ')
      .replaceAll('f\'', 'ڤ')
      .replaceAll('j\'', 'چ')
      .replaceAll('h\'', 'ة')
      .replaceAll('ch', 'ش')
      .replaceAll('kh', 'خ')
      .replaceAll('gh', 'غ')
      .replaceAll('th', 'ث')
      .replaceAll('sh', 'ش')
      .replaceAll('dh', 'ذ')
      .replaceAll('=a', 'َ')
      .replaceAll('=i', 'ِ')
      .replaceAll('=u', 'ُ')
      .replaceAll('==a', 'ً')
      .replaceAll('==i', 'ٍ')
      .replaceAll('==u', 'ٌ')
      .replaceAll('=w', 'ّ')
      .replaceAll('=o', 'ْ');

    // Single character rules
    final map = {
      '-': 'ء',
      'a': 'ا',
      'b': 'ب',
      't': 'ت',
      'j': 'ج',
      'H': 'ح',
      'd': 'د',
      'r': 'ر',
      'z': 'ز',
      's': 'س',
      'S': 'ص',
      'D': 'ض',
      'T': 'ط',
      'Z': 'ظ',
      'g': 'ع',
      'e': 'ع',
      'c': 'ع',
      '3': 'ع',
      'f': 'ف',
      'q': 'ق',
      'k': 'ك',
      'l': 'ل',
      'm': 'م',
      'n': 'ن',
      'h': 'ه',
      'w': 'و',
      'y': 'ي',
      'Y': 'ى',
      'p': 'پ',
      'v': 'ڤ',
    };

    final buffer = StringBuffer();
    for (int i = 0; i < out.length; i++) {
      final char = out[i];
      if (map.containsKey(char)) {
        buffer.write(map[char]);
      } else {
        buffer.write(char);
      }
    }
    
    return buffer.toString();
  }
}
