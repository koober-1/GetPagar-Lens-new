// ignore_for_file: unused_import, use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../routing/app_routes.dart';
import '../../routing/app_router.dart';
import '../../core/api/api_constants.dart';
import '../../service/excel_export_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../models/face_scan_setting_model.dart';
import '../../service/face_scan_report_service.dart';
import '../../service/face_scan_settings_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  FaceScanSettingsModel? _stats;
  bool _isLoadingStats = false;
  String companyCode = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoadingStats = true;
      });

      final company = await LocalStorage.getCompany();

      if (company == null || company['id'] == null) {
        throw Exception('Company not selected');
      }

      companyCode = company['code']?.toString() ?? '';

      final dio = Dio(BaseOptions(baseUrl: ApiConstants.hrmBaseUrl));

      final service = FaceScanSettingsService(dio);

      final result = await service.getFaceScanSettings();

      if (mounted) {
        setState(() {
          _stats = result;
        });
      }
    } catch (e) {
      debugPrint('Stats Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _exportAllLogs(BuildContext context) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.hrmBaseUrl));

      final service = FaceScanReportService(dio);

      // Get all FaceScan logs for company
      final report = await service.faceAllFaceScanLogsExport();

      if (report.data.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No logs available')));
        return;
      }

      await ExcelExportService.exportFaceScanReport(report);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs exported successfully')),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to export logs')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            context.go(AppRoutes.employee);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),

              child: Row(
                children: [
                  Icon(
                    Icons.settings_applications_sharp,
                    color: AppTheme.primary,
                    size: 55,
                  ),

                  const SizedBox(width: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyCode,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Version: 1.2.2',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const SettingsDetailTile(title: 'App Version', value: '1.2.2'),

            const SizedBox(height: 10),

            const SettingsDetailTile(
              title: 'Double Punch Interval',
              value: '1 Minutes',
            ),

            const SizedBox(height: 10),

            SettingsDetailTile(
              title: 'Last Record Synced',
              value: _isLoadingStats
                  ? 'Loading...'
                  : '${_stats?.lastSyncDate ?? ''} - ${_stats?.lastSyncTime ?? '--'} ',
            ),

            const SizedBox(height: 10),

            SettingsDetailTile(
              title: 'Lens Upload Log Per Request',
              value: _isLoadingStats
                  ? 'Loading...'
                  : '${_stats?.totalFaceScanAttendanceCount ?? 0}',
            ),

            // const SizedBox(height: 10),

            // const SettingsDetailTile(
            //   title: 'Lens Upload Image With Log',
            //   value: 'Enabled',
            // ),

            // const SizedBox(height: 10),

            // const SettingsDetailTile(title: 'Device ID', value: '633ADS23KOL'),
            const SizedBox(height: 35),

            SettingsActionButton(
              title: 'Export All Logs',
              textColor: Colors.green,
              onTap: () => _exportAllLogs(context),
            ),

            const SizedBox(height: 10),

            SettingsActionButton(
              title: 'Clear Database',
              textColor: Colors.red,
              onTap: () {
                debugPrint('Clear Database');
              },
            ),

            const SizedBox(height: 10),

            SettingsActionButton(
              title: 'Log Out',
              textColor: Colors.red,
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showLogoutDialog(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    barrierDismissible: false,

    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        content: const Text('Are you sure you want to logout?'),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),

          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );

  if (shouldLogout != true) {
    return;
  }

  // IMPORTANT:
  // Use the SAME authNotifier instance that GoRouter
  // is listening to.
  await authNotifier.logout();

  if (!context.mounted) {
    return;
  }

  // Navigate to login.
  context.go(AppRoutes.login);
}

class SettingsDetailTile extends StatelessWidget {
  const SettingsDetailTile({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            value,
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({
    super.key,
    required this.title,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),

      onTap: onTap,

      child: Container(
        height: 55,
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),

        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
