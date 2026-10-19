// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/face_scan_logs_export_model.dart';

class ExcelExportService {
  static Future<String?> exportFaceScanReport(
    FaceScanLogsExportModel report,
  ) async {
    if (report.data.isEmpty) {
      return null;
    }

    final excel = Excel.createExcel();

    // Create required sheet
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

    // Data
    for (final item in report.data) {
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

    // Column width
    for (var i = 0; i < 9; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Address column wider
    sheet.setColumnWidth(6, 50);

    final directory = await getApplicationDocumentsDirectory();

    final fileName =
        'face_scan_logs_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.xlsx';

    final filePath = '${directory.path}/$fileName';

    final bytes = excel.save();

    if (bytes == null) {
      return null;
    }

    final file = File(filePath);

    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(filePath)], text: 'Face Scan Logs Report');

    return filePath;
  }
}
