import 'package:flutter/material.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';

void main() async {
  final l = await AppLocalizations.delegate.load(Locale('ar'));
  print(l.invoice);
}
