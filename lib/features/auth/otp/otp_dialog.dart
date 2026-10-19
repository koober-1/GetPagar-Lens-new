import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/utils/app_sizing.dart';
import '../../../core/widgets/primary_button.dart';

class OtpDialog extends StatefulWidget {
  const OtpDialog({
    super.key,
    required this.phoneNumber,
    required this.onVerifyOtp,
    required this.onResendOtp,
    required this.onVerified,
  });

  final String phoneNumber;

  final Future<bool> Function(String otp) onVerifyOtp;

  final Future<bool> Function() onResendOtp;

  final VoidCallback onVerified;

  static Future<void> show(
    BuildContext context, {

    required String phoneNumber,

    required Future<bool> Function(String otp) onVerifyOtp,

    required Future<bool> Function() onResendOtp,

    required VoidCallback onVerified,
  }) {
    return showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (_) => OtpDialog(
        phoneNumber: phoneNumber,

        onVerifyOtp: onVerifyOtp,

        onResendOtp: onResendOtp,

        onVerified: onVerified,
      ),
    );
  }

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  static const int _otpLength = 6;

  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );

  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  int _secondsLeft = 60;

  Timer? _timer;

  bool _isVerifying = false;

  bool _isResending = false;

  @override
  void initState() {
    super.initState();

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsLeft = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsLeft <= 1) {
        timer.cancel();

        setState(() {
          _secondsLeft = 0;
        });
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  String get _otpValue {
    return _controllers.map((e) => e.text).join();
  }

  Future<void> _verify() async {
    final otp = _otpValue;

    if (otp.length != _otpLength) {
      _showSnack('Please enter valid OTP');

      return;
    }

    try {
      setState(() {
        _isVerifying = true;
      });

      final success = await widget.onVerifyOtp(otp);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);

        widget.onVerified();
      } else {
        _showSnack('Invalid OTP');
      }
    } catch (e) {
      _showSnack('OTP verification failed');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    try {
      setState(() {
        _isResending = true;
      });

      final success = await widget.onResendOtp();

      if (!mounted) return;

      if (success) {
        _startTimer();

        _showSnack('OTP resent successfully');
      } else {
        _showSnack('Failed to resend OTP');
      }
    } catch (e) {
      _showSnack('Failed to resend OTP');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final c in _controllers) {
      c.dispose();
    }

    for (final f in _focusNodes) {
      f.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogMaxWidth = AppSizing.dialogMaxWidth(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen
            ? 12
            : AppSizing.dialogHorizontalInset(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogMaxWidth),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 14 : 18,
              18,
              isSmallScreen ? 14 : 18,
              16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),

                Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _OtpBoxes(
                  controllers: _controllers,
                  focusNodes: _focusNodes,
                  onFilled: _verify,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: _isVerifying ? 'Verifying...' : 'Verify OTP',
                    isDisabled: _isVerifying,
                    onPressed: _isVerifying ? null : _verify,
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    Text(
                      _secondsLeft == 0
                          ? '00:00'
                          : '00:${_secondsLeft.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    TextButton(
                      onPressed: (_secondsLeft == 0 && !_isResending)
                          ? _resendOtp
                          : null,
                      child: Text(_isResending ? 'Sending...' : 'Resend'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controllers,

    required this.focusNodes,

    required this.onFilled,
  });

  final List<TextEditingController> controllers;

  final List<FocusNode> focusNodes;

  final VoidCallback onFilled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(controllers.length, (i) {
            final isLast = i == controllers.length - 1;

            return Flexible(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : gap),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: TextField(
                    controller: controllers[i],
                    focusNode: focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.textMuted),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.isEmpty) {
                        if (i > 0) {
                          focusNodes[i - 1].requestFocus();
                        }
                        return;
                      }

                      if (!isLast) {
                        focusNodes[i + 1].requestFocus();
                      } else {
                        FocusScope.of(context).unfocus();

                        final otp = controllers.map((e) => e.text).join();

                        if (otp.length == controllers.length) {
                          onFilled();
                        }
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
