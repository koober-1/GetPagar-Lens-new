// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:getpagar_lens/app/theme.dart';
import 'package:getpagar_lens/core/utils/app_sizing.dart';
import 'package:getpagar_lens/routing/app_routes.dart';

import '../../core/storage/local_storage.dart';
import '../../service/welcome_service.dart';

class WelcomeScreen extends StatefulWidget {
  final String mobile;

  const WelcomeScreen({super.key, required this.mobile});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final WelcomeService _welcomeService = WelcomeService();

  bool isLoading = true;
  List companies = [];

  @override
  void initState() {
    super.initState();
    _getAdminCompanies();
  }

  Future<void> _getAdminCompanies() async {
    try {
      final response = await _welcomeService.getAdminCompanies(
        mobile: widget.mobile,
      );

      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          companies = data['companies'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectCompany(Map<String, dynamic> company) async {
    await LocalStorage.saveCompany({
      "id": company['id'],
      "name": company['name'],
      "code": company['code'],
      "adminId": company['adminId'],
      "adminName": company['adminName'],
      "adminEmail": company['adminEmail'],
      "adminContact": company['adminContact'],
    });

    if (!mounted) return;

    context.go(AppRoutes.employee);
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = AppSizing.maxContentWidth(context);

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: contentWidth,
          child: Padding(
            padding: AppSizing.screenPadding(context),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      const Text(
                        'Welcome to GetPagar Lens!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Log me as?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF777777),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),

                      ...companies.map((company) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _selectCompany(company),
                            child: _AccountCard(
                              title: 'Admin at ${company['name']}',
                              subtitle: 'Company Code : ${company['code']}',
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
