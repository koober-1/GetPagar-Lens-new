// ignore_for_file: control_flow_in_finally

import 'package:flutter/material.dart';
import 'package:getpagar_lens/app/theme.dart';
import 'package:getpagar_lens/core/notifiers/employee_list_refresh_notifier.dart';
import 'package:getpagar_lens/core/utils/app_sizing.dart';
import 'package:getpagar_lens/core/widgets/employee_avatar.dart';
import 'package:getpagar_lens/models/employee_model.dart';
import 'package:getpagar_lens/routing/app_routes.dart';
import 'package:getpagar_lens/service/employee_registration_cache.dart';
import 'package:getpagar_lens/service/employee_service.dart';
import 'package:getpagar_lens/service/face_recognition_service.dart';
import 'package:go_router/go_router.dart';
import 'package:getpagar_lens/core/session/current_employee.dart';

class EmployeeTabScreen extends StatefulWidget {
  const EmployeeTabScreen({super.key});

  @override
  State<EmployeeTabScreen> createState() => _EmployeeTabScreenState();
}

class _EmployeeTabScreenState extends State<EmployeeTabScreen> {
  final _searchController = TextEditingController();
  final _employeeService = EmployeeService();
  final _faceService = FaceRecognitionService();

  List<EmployeeModel> employees = [];
  List<EmployeeModel> filteredEmployees = [];

  Set<String> _registeredCodes = {};
  Set<String> _clearedCodes = {};

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchEmployee);
    EmployeeListRefreshNotifier.instance.addListener(_onRefreshSignal);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadRegistrationFlags();

    if (!mounted) return;

    await fetchEmployees();
  }

  Future<void> _loadRegistrationFlags() async {
    final r = await EmployeeRegistrationCache.instance.readRegisteredCodes();
    final c = await EmployeeRegistrationCache.instance.readClearedCodes();
    if (!mounted) return;
    setState(() {
      _registeredCodes = r;
      _clearedCodes = c;
    });
  }

  void _onRefreshSignal() async {
    if (!mounted) return;

    await _loadRegistrationFlags();

    if (!mounted) return;

    await fetchEmployees();
  }

  bool _isRegistered(EmployeeModel e) {
    return e.isFaceRegistered(
      cachedRegisteredCodes: _registeredCodes,
      cachedClearedCodes: _clearedCodes,
    );
  }

  Future<void> fetchEmployees() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _employeeService.getAllEmployees();

      if (!mounted) return;

      setState(() {
        employees = data;
        filteredEmployees = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void _searchEmployee() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredEmployees = employees;
      });
      return;
    }

    final result = employees.where((employee) {
      return employee.employeeName.toLowerCase().contains(query) ||
          employee.employeeCode.toLowerCase().contains(query) ||
          employee.departmentName.toLowerCase().contains(query);
    }).toList();

    setState(() {
      filteredEmployees = result;
    });
  }

  Future<void> _onCardTap(EmployeeModel employee) async {
    CurrentEmployee.employee = employee;
    if (!mounted) return;
    context.push(AppRoutes.employeeProfile, extra: employee);
  }

  Future<void> _deleteFromCard(EmployeeModel employee) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete registration?'),
        content: Text(
          'Remove face data for ${employee.employeeName} (${employee.employeeCode})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _faceService.deleteRegistration(employee.employeeCode);
      await EmployeeRegistrationCache.instance.markClearedAfterDelete(
        employee.employeeCode,
      );
      EmployeeListRefreshNotifier.instance.requestRefresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    EmployeeListRefreshNotifier.instance.removeListener(_onRefreshSignal);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = AppSizing.maxContentWidth(context);

    return SafeArea(
      top: true,
      child: SizedBox(
        width: contentWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      controller: _searchController,
                      onClear: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    onPressed: fetchEmployees,
                    icon: const Icon(Icons.refresh, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Employees (${filteredEmployees.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (filteredEmployees.isEmpty) {
      return const Center(
        child: Text('No Employees Found', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadRegistrationFlags();
        await fetchEmployees();
      },
      child: ListView.separated(
        itemCount: filteredEmployees.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final employee = filteredEmployees[index];
          final registered = _isRegistered(employee);
          return _EmployeeCard(
            employee: employee,
            registered: registered,
            onTap: () => _onCardTap(employee),
            onDelete: registered ? () => _deleteFromCard(employee) : null,
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onClear});
  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
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
          const SizedBox(width: 10),
          const Icon(Icons.search, color: Color(0xFF111111)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintStyle: TextStyle(color: Colors.pink[200], fontSize: 17),
                hintText: 'Search',
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.cancel_outlined, color: Color(0xFF111111)),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.employee,
    required this.registered,
    required this.onTap,
    required this.onDelete,
  });

  final EmployeeModel employee;
  final bool registered;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE6E6E6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              EmployeeAvatar(
                imageField: employee.image,
                employeeCode: employee.employeeCode,
                size: 64,
                radius: 8,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.employeeName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.departmentName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${employee.employeeCode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (registered) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Face registered',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete registration (demo)',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
