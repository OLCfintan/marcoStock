import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import '../../application/auth/auth_service.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == 'ADMIN';

    Widget buildSidebar() {
      return Container(
        width: 250,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              color: const Color(0xff0f172a),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(clipBehavior: Clip.antiAliasWithSaveLayer, child: Image.asset('assets/images/logo.jpeg', width: 32, height: 32, fit: BoxFit.cover, filterQuality: FilterQuality.high)),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.appTitle ?? 'Marko Group',
                          style: const TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentUser?.name ?? ''} (${currentUser?.role ?? ''})',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavItem(context, Icons.dashboard, l10n?.dashboard ?? 'Dashboard', '/'),
                  _buildNavItem(context, Icons.inventory_2, l10n?.products ?? 'Products', '/products'),
                  _buildNavItem(context, Icons.store, l10n?.stock ?? 'Stock', '/stock'),
                  _buildNavItem(context, Icons.people, l10n?.clients ?? 'Clients', '/clients'),
                  _buildNavItem(context, Icons.point_of_sale, l10n?.salesPos ?? 'Sales (POS)', '/pos'),
                  _buildNavItem(context, Icons.assignment_return, l10n?.returns ?? 'Returns', '/returns'),
                  _buildNavItem(context, Icons.folder_open, l10n?.archiveDocs ?? 'Archive & Docs', '/documents'),
                  
                  if (isAdmin) ...[
                    const Divider(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(l10n?.administration ?? 'ADMINISTRATION', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                    _buildNavItem(context, Icons.local_shipping, l10n?.suppliers ?? 'Suppliers', '/suppliers'),
                    _buildNavItem(context, Icons.shopping_cart, l10n?.purchases ?? 'Purchases', '/purchases'),

                    _buildNavItem(context, Icons.badge, l10n?.employeesHr ?? 'Employees (HR)', '/employees'),
                  ],
                  const Divider(height: 32),
                  _buildNavItem(context, Icons.delete_outline, l10n?.garbage ?? 'Garbage / Deleted', '/garbage'),
                  _buildNavItem(context, Icons.settings, l10n?.settings ?? 'Settings', '/settings'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(clipBehavior: Clip.antiAliasWithSaveLayer, child: Image.asset('assets/images/logo.jpeg', width: 28, height: 28, fit: BoxFit.cover, filterQuality: FilterQuality.high)),
                  const SizedBox(width: 8),
                  Text(l10n?.appTitle ?? 'Marko Group'),
                ],
              ),
              
            ),
            drawer: Drawer(
              child: buildSidebar(),
            ),
            body: child,
          );
        } else {
          return Scaffold(
            body: Row(
              children: [
                buildSidebar(),
                Expanded(
                  child: child,
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String routePath) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isSelected = currentPath == routePath;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer,
        leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (MediaQuery.of(context).size.width < 800) {
            Navigator.of(context).pop();
            Future.microtask(() {
               if (context.mounted) context.go(routePath);
            });
          } else {
            context.go(routePath);
          }
        },
      ),
      ),
    );
  }
}
