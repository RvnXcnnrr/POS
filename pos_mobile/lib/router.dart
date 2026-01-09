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
import 'core/utils/responsive.dart';

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
    const destinations = <({
      String label,
      IconData icon,
      IconData selectedIcon,
    })>[
      (label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
      (
        label: 'Checkout',
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
      ),
      (label: 'Reports', icon: Icons.assessment_outlined, selectedIcon: Icons.assessment),
      (label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = breakpointForWidth(constraints.maxWidth);
        final useRail = bp != ScreenBreakpoint.compact;

        return Scaffold(
          body: SafeArea(
            bottom: useRail,
            child: useRail
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: navigationShell.currentIndex,
                        onDestinationSelected: (i) => _onTap(context, ref, i),
                        extended: bp == ScreenBreakpoint.expanded,
                        labelType: bp == ScreenBreakpoint.expanded
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.selected,
                        destinations: [
                          for (final d in destinations)
                            NavigationRailDestination(
                              icon: Icon(d.icon),
                              selectedIcon: Icon(d.selectedIcon),
                              label: Text(d.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: navigationShell),
                    ],
                  )
                : navigationShell,
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (i) => _onTap(context, ref, i),
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
