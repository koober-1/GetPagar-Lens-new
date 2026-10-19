import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/notifiers/employee_list_refresh_notifier.dart';
import '../../models/employee_model.dart';
import '../../routing/app_routes.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({
    super.key,
    required this.employee,
  });

  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.verified, size: 88, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Registration complete',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${employee.employeeName} can now mark attendance with face verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.4, color: Colors.grey.shade700),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  EmployeeListRefreshNotifier.instance.requestRefresh();
                  context.go(AppRoutes.employee);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppTheme.primary,
                ),
                child: const Text('Back to employees'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
