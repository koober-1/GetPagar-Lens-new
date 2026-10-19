import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:getpagar_lens/app/theme.dart';
import 'package:getpagar_lens/routing/app_routes.dart';
import '../../core/session/current_employee.dart';
import '../../core/storage/local_storage.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key, required this.child});

  final Widget child;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  String companyName = '';

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final company = await LocalStorage.getCompany();

    if (mounted) {
      setState(() {
        companyName = company?['name'] ?? '';
      });
    }
  }

  int _locationToTabIndex(String location) {
    if (location.startsWith(AppRoutes.logs)) return 2;
    return 0;
  }

  String _tabIndexToLocation(int index) {
    switch (index) {
      case 2:
        return AppRoutes.logs;
      case 0:
      default:
        return AppRoutes.employee;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToTabIndex(location);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.appBar,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          companyName.isEmpty ? 'Company' : companyName,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.setting),
            child: const Text(
              'Setting',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) {
          if (i == 1) {
            context.push(
              AppRoutes.attendanceCamera,
              extra: CurrentEmployee.employee,
            );
            return;
          }
          context.go(_tabIndexToLocation(i));
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.appBar,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Employee'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Logs',
          ),
        ],
      ),
    );
  }
}
