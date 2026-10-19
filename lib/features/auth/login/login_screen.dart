import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/app_sizing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../routing/app_routes.dart';
import '../../../routing/app_router.dart'; // authNotifier
import '../../../service/auth_service.dart';
import '../../../core/storage/local_storage.dart';
import 'country.dart';
import '../otp/otp_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();

  bool isLoading = false;

  Country _selectedCountry = Country.india;

  final TextEditingController _mobileController = TextEditingController();

  int get _expectedDigits {
    if (_selectedCountry == Country.india) {
      return 10;
    }

    return 15;
  }

  bool get _isMobileValid {
    final raw = _mobileController.text.trim();

    final onlyDigits = RegExp(r'^\d+$').hasMatch(raw);

    if (!onlyDigits) {
      return false;
    }

    if (_selectedCountry == Country.india) {
      return raw.length == 10;
    }

    return raw.length >= 8 && raw.length <= 15;
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _onNext() async {
    FocusScope.of(context).unfocus();

    if (!_isMobileValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid mobile number')),
      );

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final phone = _mobileController.text.trim();

      final response = await authService.sendOtp(mobile: phone);

      final data = response.data;

      if (data['success'] == true) {
        if (!mounted) return;

        await OtpDialog.show(
          context,
          phoneNumber: phone,

          // ------------------------------------------------------
          // RESEND OTP
          // ------------------------------------------------------
          onResendOtp: () async {
            final response = await authService.sendOtp(mobile: phone);

            return response.data['success'] == true;
          },

          // ------------------------------------------------------
          // VERIFY OTP
          // ------------------------------------------------------
          onVerifyOtp: (otp) async {
            try {
              final verifyResponse = await authService.verifyOtp(
                mobile: phone,
                otp: otp,
              );

              final data = verifyResponse.data;

              if (data['success'] == true) {
                final token = data['token'];

                if (token == null || token.toString().isEmpty) {
                  return false;
                }

                // Save authentication token.
                await LocalStorage.saveToken(token.toString());

                // DO NOT call authNotifier.login() here.
                //
                // We want the OTP Verified dialog
                // to appear first.

                return true;
              }

              return false;
            } catch (e) {
              debugPrint('OTP verification error: $e');

              return false;
            }
          },

          // ------------------------------------------------------
          // OTP VERIFIED
          // ------------------------------------------------------
          onVerified: () {
            if (!mounted) return;

            _showOtpVerifiedDialog(context, phone);
          },
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')),
        );
      }
    } catch (e) {
      debugPrint('Send OTP error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number is not registered.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // OTP VERIFIED DIALOG
  // ============================================================

  Future<void> _showOtpVerifiedDialog(
    BuildContext context,
    String phone,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: Color(0xFF1DB954),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),

              const SizedBox(height: 14),

              const Text(
                'OTP Verified',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 12),
            ],
          ),

          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),

          actions: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () async {
                  // Close OTP verified dialog
                  Navigator.of(dialogContext).pop();

                  // NOW mark the user as logged in.
                  //
                  // Tell GoRouter:
                  // after login → Welcome
                  await authNotifier.login(
                    nextRoute: AppRoutes.welcome,
                    mobile: phone,
                  );
                },

                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = AppSizing.maxContentWidth(context);

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  padding: AppSizing.screenPadding(context),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const SizedBox(height: 6),

                      Text(
                        'Account Login',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Please enter a valid Mobile Number to access your getpagar Lens account',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 26),

                      _MobileInput(
                        controller: _mobileController,

                        selectedCountry: _selectedCountry,

                        onCountryChanged: (country) {
                          setState(() {
                            _selectedCountry = country;
                          });
                        },

                        maxDigits: _expectedDigits,
                      ),

                      const SizedBox(height: 26),

                      PrimaryButton(
                        label: isLoading ? 'Please wait...' : 'Next',

                        onPressed: isLoading ? null : _onNext,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// MOBILE INPUT
// ================================================================

class _MobileInput extends StatelessWidget {
  const _MobileInput({
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.maxDigits,
  });

  final TextEditingController controller;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final int maxDigits;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: AppTheme.border),
      ),

      child: Row(
        children: [
          const SizedBox(width: 12),

          DropdownButtonHideUnderline(
            child: DropdownButton<Country>(
              value: selectedCountry,

              onChanged: (country) {
                if (country != null) {
                  onCountryChanged(country);
                }
              },

              items: Country.supported.map((country) {
                return DropdownMenuItem<Country>(
                  value: country,

                  child: Row(
                    children: [
                      Text(
                        country.flagEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        country.dialCode,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            height: 28,
            child: VerticalDivider(
              color: AppTheme.border.withValues(alpha: 0.9),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: controller,

              keyboardType: TextInputType.phone,

              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,

                LengthLimitingTextInputFormatter(maxDigits),
              ],

              decoration: InputDecoration(
                hintText: 'Mobile',

                hintStyle: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.8),
                ),

                border: InputBorder.none,

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),

                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),

              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
