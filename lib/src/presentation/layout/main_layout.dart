import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import '../../application/auth/auth_service.dart';
import '../../application/system/shortcuts_provider.dart';
import 'package:flutter/services.dart';
import '../widgets/quick_command_palette.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == 'ADMIN';

    Widget buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    Widget buildSidebar() {
      return Container(
        width: 250,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              width: double.infinity,
              color: const Color(0xff0f172a),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n?.appTitle ?? 'Marko Group',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${currentUser?.name ?? ''} (${currentUser?.role ?? ''})',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                        ),
                        InkWell(
                          onTap: () => QuickCommandPalette.show(context),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Ctrl+K', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  // Overview
                  _buildNavItem(context, Icons.dashboard_outlined, l10n?.dashboard ?? 'Dashboard', '/'),

                  // Commerce Section (Hick's Law grouping)
                  buildSectionTitle('COMMERCE'),
                  _buildNavItem(context, Icons.point_of_sale_outlined, l10n?.salesPos ?? 'Sales (POS)', '/pos'),
                  _buildNavItem(context, Icons.people_outline, l10n?.clients ?? 'Clients', '/clients'),
                  _buildNavItem(context, Icons.folder_open_outlined, l10n?.archiveDocs ?? 'Archive & Docs', '/documents'),
                  _buildNavItem(context, Icons.assignment_return_outlined, l10n?.returns ?? 'Returns', '/returns'),

                  // Stock Section (Hick's Law grouping)
                  buildSectionTitle('STOCK'),
                  _buildNavItem(context, Icons.store_outlined, l10n?.stock ?? 'Stock', '/stock'),
                  _buildNavItem(context, Icons.inventory_2_outlined, l10n?.products ?? 'Products', '/products'),

                  // Finance & Purchasing (Hick's Law grouping)
                  if (isAdmin) ...[
                    buildSectionTitle('FINANCE & PURCHASES'),
                    _buildNavItem(context, Icons.shopping_cart_outlined, l10n?.purchases ?? 'Purchases', '/purchases'),
                    _buildNavItem(context, Icons.local_shipping_outlined, l10n?.suppliers ?? 'Suppliers', '/suppliers'),
                  ],

                  // Administration (Hick's Law grouping)
                  buildSectionTitle(l10n?.administration ?? 'ADMINISTRATION'),
                  if (isAdmin)
                    _buildNavItem(context, Icons.badge_outlined, l10n?.employeesHr ?? 'Employees (HR)', '/employees'),
                  _buildNavItem(context, Icons.delete_outline, l10n?.garbage ?? 'Garbage / Deleted', '/garbage'),
                  _buildNavItem(context, Icons.settings_outlined, l10n?.settings ?? 'Settings', '/settings'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          final currentPath = GoRouterState.of(context).matchedLocation;
          if (currentPath == '/purchases') {
            ref.read(newPurchaseCartTriggerProvider.notifier).state++;
          } else {
            ref.read(newSaleCartTriggerProvider.notifier).state++;
            if (currentPath != '/pos') {
              context.go('/pos');
            }
          }
        },
        SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          QuickCommandPalette.show(context);
        },
      },
      child: Focus(
        autofocus: true,
        canRequestFocus: true,
        descendantsAreFocusable: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return Scaffold(
                appBar: AppBar(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: Image.asset(
                          'assets/images/logo.jpeg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n?.appTitle ?? 'Marko Group'),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'Quick Command (Ctrl+K)',
                      onPressed: () => QuickCommandPalette.show(context),
                    ),
                  ],
                ),
                drawer: Drawer(child: buildSidebar()),
                body: child,
              );
            } else {
              return Scaffold(
                body: Row(
                  children: [
                    buildSidebar(),
                    Expanded(child: child),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String routePath) {
    return _HoverNavItem(icon: icon, title: title, routePath: routePath);
  }
}

class _HoverNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String routePath;
  const _HoverNavItem({required this.icon, required this.title, required this.routePath});

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isSelected = currentPath == widget.routePath;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: () {
            if (MediaQuery.of(context).size.width < 800) {
              Navigator.of(context).pop();
              Future.microtask(() {
                if (context.mounted) context.go(widget.routePath);
              });
            } else {
              context.go(widget.routePath);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? colorScheme.primaryContainer
                  : (_isHovered
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
                      : Colors.transparent),
              border: isSelected
                  ? Border(left: BorderSide(color: colorScheme.primary, width: 4))
                  : null,
            ),
            child: Row(
              children: [
                // Circle icon with hover color effect
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : (_isHovered
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: isSelected
                          ? colorScheme.primary
                          : (_isHovered ? colorScheme.primary : colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : (_isHovered ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
