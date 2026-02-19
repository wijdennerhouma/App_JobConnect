import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/responsive_helper.dart';
import '../../widgets/glass_container.dart';
import '../employee/employee_home_screen.dart';
import '../entreprise/company_home_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

import '../../core/translations.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isEmployee = auth.isEmployee;
    final lang = context.watch<AppSettings>().language;
    final isWeb = ResponsiveHelper.isWeb(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    final pages = [
      if (isEmployee) const EmployeeHomeScreen() else const CompanyHomeScreen(),
      const ProfileScreen(),
    ];

    if (isWeb && isDesktop) {
      // Desktop layout with sidebar
      return Scaffold(
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'JobConnect',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildNavItem(
                    context,
                    icon: isEmployee ? Icons.work_outline : Icons.cases_outlined,
                    selectedIcon: isEmployee ? Icons.work : Icons.cases_rounded,
                    label: isEmployee ? lang.tr('offers') : lang.tr('my_offers'),
                    index: 0,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: lang.tr('profile_title'),
                    index: 1,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: lang.tr('settings'),
                    index: 2,
                    isSettings: true,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(child: SafeArea(child: pages[_index])),
          ],
        ),
      );
    }

    // Mobile/Tablet layout with bottom nav
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          } else {
            setState(() => _index = i);
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(isEmployee ? Icons.work_outline : Icons.cases_outlined),
            selectedIcon: Icon(isEmployee ? Icons.work : Icons.cases_rounded),
            label: isEmployee ? lang.tr('offers') : lang.tr('my_offers'),
            tooltip: '',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: lang.tr('profile_title'),
            tooltip: '',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: lang.tr('settings'),
            tooltip: '',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    bool isSettings = false,
  }) {
    final isSelected = _index == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        if (isSettings) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        } else {
          setState(() => _index = index);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

