import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/game_on_theme.dart';
import '../../../ads/banner_ad_widget.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/services/logs_service.dart';

final supabase = Supabase.instance.client;

class PasswordResetOtpScreen extends StatefulWidget {
  const PasswordResetOtpScreen({super.key, required this.email, this.digits = 6});

  final String email;
  final int digits;

  @override
  State<PasswordResetOtpScreen> createState() => _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState extends State<PasswordResetOtpScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
    Timer? _timer;
    int _seconds = 59;
    bool _isLoading = false;
    String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.digits, (_) => TextEditingController());
    _focusNodes = List.generate(widget.digits, (_) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else if (value.isNotEmpty && index < widget.digits - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_code.length != widget.digits) {
      setState(() {
        _errorMessage = 'الرجاء إدخال الرمز المكون من 6 أرقام';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await supabase.auth.verifyOTP(
        email: widget.email,
        token: _code,
        type: OtpType.recovery,
      );

      if (response.session != null && mounted) {
        context.go('/update-password');
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'رمز تحقق غير صحيح أو منتهي الصلاحية';
          });
        }
      }
    } on AuthException catch (error) {
      LogsService.logAuthError('PasswordResetOtpScreen._verifyOtp', error);
      if (mounted) {
        setState(() {
          _errorMessage = UIHelpers.getUserFriendlyMessage(error);
        });
      }
    } catch (error, stackTrace) {
      LogsService.logAuthError('PasswordResetOtpScreen._verifyOtp', error, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = UIHelpers.getUserFriendlyMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _errorMessage = null);
    try {
      await supabase.auth.resetPasswordForEmail(widget.email);
      if (mounted) {
        _startTimer();
      }
    } catch (error, stackTrace) {
      LogsService.logAuthError('PasswordResetOtpScreen._resendOtp', error, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل إعادة الإرسال. يرجى المحاولة مرة أخرى';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KoraCornerDimens.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'رمز التحقق',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'تم إرسال الرمز إلى بريدك الإلكتروني',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.digits, (i) {
                      final reversedIndex = widget.digits - 1 - i;
                      return Directionality(
                        textDirection: TextDirection.ltr,
                        child: Container(
                          width: 52,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: KoraCornerColors.surface,
                            borderRadius: BorderRadius.circular(KoraCornerDimens.radius),
                            border: Border.all(
                              color: KoraCornerColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _controllers[reversedIndex],
                              focusNode: _focusNodes[reversedIndex],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (v) => _onChanged(reversedIndex, v),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: KoraCornerColors.accentGold),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _seconds == 0 ? _resendOtp : null,
                        child: Text(
                          'إعادة إرسال',
                          style: TextStyle(
                            color: _seconds == 0
                                ? KoraCornerColors.primaryGreen
                                : KoraCornerColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    UIHelpers.buildErrorText(_errorMessage),
                  ],
                  const Spacer(),
                ElevatedButton(
                  style: KoraCornerTheme.primaryButtonStyle,
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('تحقق'),
                ),
                const SizedBox(height: 12),
              ],
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
