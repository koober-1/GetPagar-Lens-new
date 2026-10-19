import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/employee_model.dart';
import '../../routing/app_routes.dart';

/// Shown **only** before first-time face registration from the employee directory.
class RegistrationInstructionScreen extends StatelessWidget {
  const RegistrationInstructionScreen({super.key, required this.employee});

  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register your face'),
        backgroundColor: AppTheme.appBar,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            employee.employeeName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Code: ${employee.employeeCode} · ${employee.departmentName}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 28),
          const Text(
            'Before we open the camera',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const _Bullet(
            text: 'Use good, even lighting (avoid strong backlight).',
          ),
          const SizedBox(height: 12),
          const _Bullet(
            text: 'Keep your whole face visible — no masks or sunglasses.',
          ),
          const SizedBox(height: 12),
          const _Bullet(
            text:
                'Look straight at the camera and hold still when you tap capture.',
          ),
          const SizedBox(height: 12),
          const _Bullet(text: 'Only one face should be in the frame.'),
          const SizedBox(height: 36),
          FilledButton(
            onPressed: () {
              context.push(AppRoutes.registrationCamera, extra: employee);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Continue to camera'),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.45)),
        ),
      ],
    );
  }
}
