import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_session = """class PosSession {
  final String id;
  String title;
  String? selectedClientId;
  String? selectedClientTier;"""

new_session = """class PosSession {
  final String id;
  String title;
  String? selectedClientId;
  String? selectedClientName;
  String? selectedClientTier;"""

content = content.replace(old_session, new_session)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
