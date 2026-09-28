String numberToWordsFrench(int number) {
  if (number == 0) return 'zéro';
  
  final units = ['', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf'];
  final tens = ['', 'dix', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante', 'soixante-dix', 'quatre-vingts', 'quatre-vingt-dix'];
  final teens = ['dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf'];
  
  String convertUnder100(int n) {
    if (n < 10) return units[n];
    if (n < 20) return teens[n - 10];
    
    int t = n ~/ 10;
    int u = n % 10;
    
    if (t == 7 || t == 9) {
      if (u == 0) return tens[t];
      return tens[t - 1].replaceAll('s', '') + '-' + teens[u];
    }
    
    if (u == 0) return tens[t];
    if (u == 1 && t != 8) return tens[t].replaceAll('s', '') + ' et un';
    return tens[t].replaceAll('s', '') + '-' + units[u];
  }
  
  String convertUnder1000(int n) {
    if (n < 100) return convertUnder100(n);
    int h = n ~/ 100;
    int rem = n % 100;
    String res = '';
    if (h == 1) res = 'cent';
    else res = units[h] + ' cent' + (rem == 0 ? 's' : '');
    
    if (rem > 0) {
      res += ' ' + convertUnder100(rem);
    }
    return res;
  }
  
  String convertUnder1000000(int n) {
    if (n < 1000) return convertUnder1000(n);
    int th = n ~/ 1000;
    int rem = n % 1000;
    String res = '';
    if (th == 1) res = 'mille';
    else res = convertUnder1000(th) + ' mille';
    
    if (rem > 0) res += ' ' + convertUnder1000(rem);
    return res;
  }
  
  return convertUnder1000000(number);
}

String numberToWordsEnglish(int number) {
  if (number == 0) return 'zero';
  final units = ['', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
  final teens = ['ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'];
  final tens = ['', 'ten', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];
  
  String convertUnder100(int n) {
    if (n < 10) return units[n];
    if (n < 20) return teens[n - 10];
    int t = n ~/ 10;
    int u = n % 10;
    if (u == 0) return tens[t];
    return tens[t] + '-' + units[u];
  }
  
  String convertUnder1000(int n) {
    if (n < 100) return convertUnder100(n);
    int h = n ~/ 100;
    int rem = n % 100;
    String res = units[h] + ' hundred';
    if (rem > 0) res += ' and ' + convertUnder100(rem);
    return res;
  }
  
  String convertUnder1000000(int n) {
    if (n < 1000) return convertUnder1000(n);
    int th = n ~/ 1000;
    int rem = n % 1000;
    String res = convertUnder1000(th) + ' thousand';
    if (rem > 0) res += ' ' + convertUnder1000(rem);
    return res;
  }
  
  return convertUnder1000000(number);
}

String numberToWordsSpanish(int number) {
  if (number == 0) return 'cero';
  final units = ['', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve'];
  final teens = ['diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete', 'dieciocho', 'diecinueve'];
  final twenties = ['veinte', 'veintiuno', 'veintidós', 'veintitrés', 'veinticuatro', 'veinticinco', 'veintiséis', 'veintisiete', 'veintiocho', 'veintinueve'];
  final tens = ['', 'diez', 'veinte', 'treinta', 'cuarenta', 'cincuenta', 'sesenta', 'setenta', 'ochenta', 'noventa'];
  final hundreds = ['', 'ciento', 'doscientos', 'trescientos', 'cuatrocientos', 'quinientos', 'seiscientos', 'setecientos', 'ochocientos', 'novecientos'];
  
  String convertUnder100(int n) {
    if (n < 10) return units[n];
    if (n < 20) return teens[n - 10];
    if (n < 30) return twenties[n - 20];
    int t = n ~/ 10;
    int u = n % 10;
    if (u == 0) return tens[t];
    return tens[t] + ' y ' + units[u];
  }
  
  String convertUnder1000(int n) {
    if (n == 100) return 'cien';
    if (n < 100) return convertUnder100(n);
    int h = n ~/ 100;
    int rem = n % 100;
    String res = hundreds[h];
    if (rem > 0) res += ' ' + convertUnder100(rem);
    return res;
  }
  
  String convertUnder1000000(int n) {
    if (n < 1000) return convertUnder1000(n);
    int th = n ~/ 1000;
    int rem = n % 1000;
    String res = '';
    if (th == 1) res = 'mil';
    else res = convertUnder1000(th) + ' mil';
    
    if (rem > 0) res += ' ' + convertUnder1000(rem);
    return res;
  }
  
  return convertUnder1000000(number);
}

String numberToWordsArabic(int number) {
  if (number == 0) return 'صفر';
  final units = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة'];
  final tens = ['', 'عشرة', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];
  final teens = ['عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر'];
  final hundreds = ['', 'مائة', 'مائتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة', 'سبعمائة', 'ثمانمائة', 'تسعمائة'];
  
  String convertUnder100(int n) {
    if (n < 10) return units[n];
    if (n < 20) return teens[n - 10];
    int t = n ~/ 10;
    int u = n % 10;
    if (u == 0) return tens[t];
    return units[u] + ' و ' + tens[t];
  }
  
  String convertUnder1000(int n) {
    if (n < 100) return convertUnder100(n);
    int h = n ~/ 100;
    int rem = n % 100;
    String res = hundreds[h];
    if (rem > 0) res += ' و ' + convertUnder100(rem);
    return res;
  }
  
  String convertUnder1000000(int n) {
    if (n < 1000) return convertUnder1000(n);
    int th = n ~/ 1000;
    int rem = n % 1000;
    String res = '';
    if (th == 1) res = 'ألف';
    else if (th == 2) res = 'ألفان';
    else if (th < 11) res = convertUnder100(th) + ' آلاف';
    else res = convertUnder1000(th) + ' ألف';
    
    if (rem > 0) res += ' و ' + convertUnder1000(rem);
    return res;
  }
  
  return convertUnder1000000(number);
}

String decimalToWordsTranslated(double amount, String langCode) {
  int mainPart = amount.truncate();
  int decimalPart = ((amount - mainPart) * 100).round();
  
  String currency = 'dirhams';
  String subCurrency = 'centimes';
  String andStr = 'et';
  String Function(int) converter = numberToWordsFrench;
  
  if (langCode.startsWith('en')) {
    currency = 'dirhams';
    subCurrency = 'centimes';
    andStr = 'and';
    converter = numberToWordsEnglish;
  } else if (langCode.startsWith('es')) {
    currency = 'dirhams';
    subCurrency = 'céntimos';
    andStr = 'y';
    converter = numberToWordsSpanish;
  } else if (langCode.startsWith('ar')) {
    currency = 'درهم';
    subCurrency = 'سنتيم';
    andStr = 'و';
    converter = numberToWordsArabic;
  }
  
  String res = converter(mainPart) + ' ' + currency;
  if (decimalPart > 0) {
    res += ' ' + andStr + ' ' + converter(decimalPart) + ' ' + subCurrency;
  }
  return res;
}
