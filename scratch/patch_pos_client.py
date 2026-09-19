import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_session = """class PosSession {
  final String id;
  String title;
  String? selectedClientId;
  String selectedClientTier = 'Tier 1';
  String selectedDocumentType = 'BON';"""

new_session = """class PosSession {
  final String id;
  String title;
  String? selectedClientId;
  String? selectedClientName;
  String selectedClientTier = 'Tier 1';
  String selectedDocumentType = 'BON';"""

content = content.replace(old_session, new_session)

old_autocomplete = """                  child: AutocompleteSearchField<Client>(
                    labelText: 'Select Client',
                    prefixIcon: const Icon(Icons.person_search),
                    displayStringForOption: (client) => client.name,
                    getSuggestions: (query) async {
                      return ref.read(clientRepositoryProvider).searchClients(query);
                    },
                    onSelected: (client) {
                      setState(() {
                        _activeSession.selectedClientId = client.id;
                        _activeSession.selectedClientTier = client.tier;
                        _recalculateCartPrices();
                      });
                    },
                  ),"""

new_autocomplete = """                  child: AutocompleteSearchField<Client>(
                    key: ValueKey(_activeSession.id),
                    labelText: 'Select Client',
                    prefixIcon: const Icon(Icons.person_search),
                    initialText: _activeSession.selectedClientName,
                    displayStringForOption: (client) => client.name,
                    getSuggestions: (query) async {
                      return ref.read(clientRepositoryProvider).searchClients(query);
                    },
                    onSelected: (client) {
                      setState(() {
                        _activeSession.selectedClientId = client.id;
                        _activeSession.selectedClientName = client.name;
                        _activeSession.selectedClientTier = client.tier;
                        _recalculateCartPrices();
                      });
                    },
                  ),"""

content = content.replace(old_autocomplete, new_autocomplete)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
