import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  final l = await AppLocalizations.delegate.load(Locale('ar'));
  print(l.invoice);
}
