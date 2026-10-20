import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import '../../application/clients/client_providers.dart';
import '../../application/products/product_providers.dart';
import '../../utils/arabic_transliterator.dart';
import '../widgets/item_navigator.dart';
import '../widgets/human_profile_dialog.dart';

class QuickCommandPalette extends ConsumerStatefulWidget {
  const QuickCommandPalette({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => const QuickCommandPalette(),
    );
  }

  @override
  ConsumerState<QuickCommandPalette> createState() => _QuickCommandPaletteState();
}

class _QuickCommandPaletteState extends ConsumerState<QuickCommandPalette> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allProducts = ref.watch(productsStreamProvider).valueOrNull ?? [];
    final allClients = ref.watch(clientsStreamProvider).valueOrNull ?? [];

    final cleanQuery = _query.trim().toLowerCase();
    final arabicQuery = ArabicTransliterator.transliterate(cleanQuery);

    final navCommands = <Map<String, dynamic>>[
      {'title': l10n?.dashboard ?? 'Dashboard', 'subtitle': 'Analytics & KPIs', 'icon': Icons.dashboard, 'route': '/'},
      {'title': l10n?.salesPos ?? 'Sales (POS)', 'subtitle': 'Point of Sale & Invoicing', 'icon': Icons.point_of_sale, 'route': '/pos'},
      {'title': l10n?.clients ?? 'Clients', 'subtitle': 'Customer Accounts & Debts', 'icon': Icons.people, 'route': '/clients'},
      {'title': l10n?.stock ?? 'Stock', 'subtitle': 'Warehouse & Store Balances', 'icon': Icons.store, 'route': '/stock'},
      {'title': l10n?.products ?? 'Products', 'subtitle': 'Catalog, Prices & BOM', 'icon': Icons.inventory_2, 'route': '/products'},
      {'title': l10n?.archiveDocs ?? 'Archive & Docs', 'subtitle': 'Delivery Notes, Factures & History', 'icon': Icons.folder_open, 'route': '/documents'},
      {'title': l10n?.purchases ?? 'Purchases', 'subtitle': 'Supplier Orders & Stock Inflow', 'icon': Icons.shopping_cart, 'route': '/purchases'},
      {'title': l10n?.suppliers ?? 'Suppliers', 'subtitle': 'Supplier Accounts & Debts', 'icon': Icons.local_shipping, 'route': '/suppliers'},
      {'title': l10n?.employeesHr ?? 'Employees (HR)', 'subtitle': 'Staff & Payroll Ledger', 'icon': Icons.badge, 'route': '/employees'},
      {'title': l10n?.settings ?? 'Settings', 'subtitle': 'Configuration & Preferences', 'icon': Icons.settings, 'route': '/settings'},
      {'title': l10n?.garbage ?? 'Garbage / Deleted', 'subtitle': 'Recycle Bin & Restore', 'icon': Icons.delete_outline, 'route': '/garbage'},
    ];

    final filteredNav = navCommands.where((cmd) {
      if (cleanQuery.isEmpty) return true;
      final t = (cmd['title'] as String).toLowerCase();
      final s = (cmd['subtitle'] as String).toLowerCase();
      return t.contains(cleanQuery) || s.contains(cleanQuery);
    }).toList();

    final filteredProducts = cleanQuery.isEmpty
        ? []
        : allProducts.where((p) {
            final name = p.name.toLowerCase();
            final refStr = p.reference.toLowerCase();
            return name.contains(cleanQuery) || name.contains(arabicQuery) || refStr.contains(cleanQuery);
          }).take(5).toList();

    final filteredClients = cleanQuery.isEmpty
        ? []
        : allClients.where((c) {
            final name = c.name.toLowerCase();
            final phone = c.phone?.toLowerCase() ?? '';
            return name.contains(cleanQuery) || name.contains(arabicQuery) || phone.contains(cleanQuery);
          }).take(5).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650, maxHeight: 520),
          child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Search Input Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search modules, products, or clients (Ctrl+K)...',
                    prefixIcon: const Icon(Icons.search, size: 24),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) => setState(() => _query = val),
                ),
              ),
              const Divider(height: 1),

              // Results List
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  children: [
                    if (filteredNav.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          'MODULES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      ...filteredNav.map((cmd) => ListTile(
                            leading: Icon(cmd['icon'] as IconData, color: theme.colorScheme.primary),
                            title: Text(cmd['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(cmd['subtitle'] as String, style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              Navigator.pop(context);
                              context.go(cmd['route'] as String);
                            },
                          )),
                    ],

                    if (filteredProducts.isNotEmpty) ...[
                      const Divider(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          'PRODUCTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                      ...filteredProducts.map((p) => ListTile(
                            leading: const Icon(Icons.inventory_2, color: Colors.indigo),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Ref: ${p.reference} | Price: ${p.sellingPrice.toStringAsFixed(2)} Dhs'),
                            onTap: () {
                              Navigator.pop(context);
                              ItemNavigator.openProduct(context, p);
                            },
                          )),
                    ],

                    if (filteredClients.isNotEmpty) ...[
                      const Divider(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          'CLIENTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      ...filteredClients.map((c) => ListTile(
                            leading: const Icon(Icons.person, color: Colors.green),
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Phone: ${c.phone ?? "N/A"} | Balance: ${c.balance.toStringAsFixed(2)} Dhs'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HumanProfileDialog(
                                    type: HumanType.client,
                                    id: c.id,
                                    name: c.name,
                                    roleOrType: 'Client',
                                    phone: c.phone,
                                    email: c.email,
                                    imagePath: c.imagePath,
                                    balance: c.balance,
                                  ),
                                ),
                              );
                            },
                          )),
                    ],

                    if (filteredNav.isEmpty && filteredProducts.isEmpty && filteredClients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No matching modules, products, or clients found.'),
                        ),
                      ),
                  ],
                ),
              ),

              // Footer shortcut hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildKbdHint('Esc', 'to close'),
                        const SizedBox(width: 16),
                        _buildKbdHint('Ctrl+K', 'shortcut'),
                        const SizedBox(width: 16),
                        _buildKbdHint('Enter', 'to navigate'),
                      ],
                    ),
                    Text(
                      'ERP Quick Command',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildKbdHint(String keyLabel, String hint) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400, width: 0.8),
          ),
          child: Text(
            keyLabel,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 4),
        Text(hint, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
