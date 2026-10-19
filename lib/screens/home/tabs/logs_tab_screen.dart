// ignore_for_file: unnecessary_underscores, deprecated_member_use

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:getpagar_lens/app/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:getpagar_lens/core/utils/app_sizing.dart';

import '../../../core/api/api_constants.dart';
import '../../../models/face_scan_report_model.dart';
import '../../../service/face_scan_report_service.dart';

class LogsTabScreen extends StatefulWidget {
  const LogsTabScreen({super.key});

  @override
  State<LogsTabScreen> createState() => _LogsTabScreenState();
}

class _LogsTabScreenState extends State<LogsTabScreen> {
  DateTime _selectedDate = DateTime.now();
  late final FaceScanReportService _reportService;

  bool _isLoading = false;
  FaceScanReportModel? _report;

  String _monthName(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  String _weekdayShort(int weekday) {
    const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
    _loadReport();
  }

  @override
  void initState() {
    super.initState();

    final dio = Dio(BaseOptions(baseUrl: ApiConstants.hrmBaseUrl));

    _reportService = FaceScanReportService(dio);

    _loadReport();
  }

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final result = await _reportService.getFaceScanReport(date: date);

      debugPrint("Report records: ${result.data.length}");

      if (mounted) {
        setState(() {
          _report = result;
        });
      }
    } catch (e) {
      debugPrint("Report error: $e");

      if (mounted) {
        setState(() {
          _report = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportExcel() async {
    if (_report == null || _report!.data.isEmpty) {
      debugPrint("_report: ${_report?.data}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export')),
      );
      return;
    }

    final excel = Excel.createExcel();

    final sheet = excel['Face Scan Report'];

    // Remove default Sheet1
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Header
    sheet.appendRow([
      TextCellValue('Sr No'),
      TextCellValue('Employee Code'),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      TextCellValue('Address'),
      TextCellValue('Last Sync Date'),
      TextCellValue('Last Sync Time'),
    ]);

    // Data rows
    for (final item in _report!.data) {
      sheet.appendRow([
        TextCellValue(item.srNo.toString()),
        TextCellValue(item.employeeCode),
        TextCellValue(item.date),
        TextCellValue(item.time),
        TextCellValue(item.latitude),
        TextCellValue(item.longitude),
        TextCellValue(item.address),
        TextCellValue(item.lastSyncDate),
        TextCellValue(item.lastSyncTime),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();

    final filePath =
        '${directory.path}/face_scan_report_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.xlsx';
    debugPrint("filePath: $filePath");
    final fileBytes = excel.save();

    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles([XFile(filePath)], text: 'Face Scan Report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = AppSizing.maxContentWidth(context);

    final label =
        '${_selectedDate.day.toString().padLeft(2, '0')} '
        '${_monthName(_selectedDate.month)} '
        '${_selectedDate.year} | '
        '${_weekdayShort(_selectedDate.weekday)}';

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SafeArea(
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                isMobile
                    ? Column(
                        children: [
                          _dateSelector(label),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: _exportButton(),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _dateSelector(label)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            height: 56,
                            child: _exportButton(),
                          ),
                        ],
                      ),

                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (_report == null || _report!.data.isEmpty)
                      ? const Center(
                          child: Text(
                            'Data Not Found!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _report!.data.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _report!.data[index];

                            return _reportCard(item);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportCard(FaceScanReportData item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employee: ${item.employeeCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),

                Text(
                  '#${item.srNo}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _infoRow(Icons.access_time, item.time),

            const SizedBox(height: 6),

            _infoRow(Icons.location_on, item.address),

            const SizedBox(height: 6),

            _infoRow(Icons.sync, '${item.lastSyncDate} ${item.lastSyncTime}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _dateSelector(String label) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });

              _loadReport();
            },
            icon: const Icon(Icons.chevron_left, color: AppTheme.primary),
          ),

          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),

          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month, color: Color(0xFF111111)),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });

              _loadReport();
            },
            icon: const Icon(Icons.chevron_right, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _exportButton() {
    return ElevatedButton(
      onPressed: _exportExcel,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: const Text(
        'Export',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}
