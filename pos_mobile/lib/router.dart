import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/checkout/presentation/checkout_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/products/presentation/products_screen.dart';
import 'features/products/presentation/product_form_screen.dart';
import 'features/customers/presentation/customers_screen.dart';
import 'features/customers/presentation/customer_form_screen.dart';
import 'features/customers/presentation/customer_detail_screen.dart';
import 'features/customers/presentation/add_payment_screen.dart';
import 'core/security/pin_auth.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/checkout',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _RootScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/checkout',
                builder: (context, state) => const CheckoutScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'products',
                    builder: (context, state) => const ProductsScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const ProductFormScreen(),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          return ProductFormScreen(productId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'customers',
                    builder: (context, state) => const CustomersScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const CustomerFormScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          return CustomerDetailScreen(customerId: id);
                        },
                        routes: [
                          GoRoute(
                            path: 'edit',
                            builder: (context, state) {
                              final id = int.parse(state.pathParameters['id']!);
                              return CustomerFormScreen(customerId: id);
                            },
                          ),
                          GoRoute(
                            path: 'payment',
                            builder: (context, state) {
                              final id = int.parse(state.pathParameters['id']!);
                              return AddPaymentScreen(customerId: id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RootScaffold extends ConsumerWidget {
  const _RootScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _onTap(BuildContext context, WidgetRef ref, int index) async {
    // Settings access is PIN-protected when configured.
    if (index == 3) {
      final ok = await PinAuth.requirePin(
        context,
        ref,
        reason: 'Unlock Settings',
      );
      if (!ok) return;
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => _onTap(context, ref, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Checkout',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
