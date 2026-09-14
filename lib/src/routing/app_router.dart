import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth/auth_service.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/layout/main_layout.dart';
import '../presentation/dashboard/dashboard_screen.dart';
import '../presentation/products/products_screen.dart';
import '../presentation/clients/clients_screen.dart';
import '../presentation/sales/pos_screen.dart';
import '../presentation/suppliers/suppliers_screen.dart';
import '../presentation/stock/stock_screen.dart';
import '../presentation/stock/transfer_screen.dart';
import '../presentation/purchases/purchases_screen.dart';
import '../presentation/hr/employees_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/settings/garbage_screen.dart';
import '../presentation/documents/documents_screen.dart';
import '../presentation/sales/returns_screen.dart';
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      
      final isAdmin = currentUser?.role == 'ADMIN';
      final adminRoutes = ['/suppliers', '/purchases', '/employees', '/settings'];
      if (isLoggedIn && !isAdmin && adminRoutes.contains(state.matchedLocation)) {
        return '/';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(path: '/', name: 'dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/products', name: 'products', builder: (context, state) => const ProductsScreen()),
          GoRoute(path: '/clients', name: 'clients', builder: (context, state) => const ClientsScreen()),
          GoRoute(path: '/suppliers', name: 'suppliers', builder: (context, state) => const SuppliersScreen()),
          GoRoute(path: '/stock', name: 'stock', builder: (context, state) => const StockScreen()),
          GoRoute(path: '/transfers', name: 'transfers', builder: (context, state) => const TransferScreen()),
          GoRoute(path: '/pos', name: 'pos', builder: (context, state) => const PosScreen()),
          GoRoute(path: '/purchases', name: 'purchases', builder: (context, state) => const PurchasesScreen()),
          GoRoute(path: '/employees', name: 'employees', builder: (context, state) => const EmployeesScreen()),
          GoRoute(path: '/settings', name: 'settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: '/garbage', name: 'garbage', builder: (context, state) => const GarbageScreen()),
          GoRoute(path: '/documents', name: 'documents', builder: (context, state) => const DocumentsScreen()),
          GoRoute(path: '/returns', name: 'returns', builder: (context, state) => const ReturnsScreen()),
        ],
      ),
    ],
  );
});
