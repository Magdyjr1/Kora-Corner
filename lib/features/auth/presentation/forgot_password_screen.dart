import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/game_on_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/services/logs_service.dart';
import '../../../ads/banner_ad_widget.dart';

final supabase = Supabase.instance.client;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      if (mounted) {
        context.go('/password-reset-otp', extra: {'email': _emailController.text.trim()});
      }
    } on AuthException catch (error) {
      LogsService.logAuthError('ForgotPasswordScreen._sendResetCode', error);
      if (mounted) {
        setState(() {
          _errorMessage = UIHelpers.getUserFriendlyMessage(error);
        });
      }
    } catch (error, stackTrace) {
      LogsService.logAuthError('ForgotPasswordScreen._sendResetCode', error, stackTrace: stackTrace);
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
  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نسيت كلمة المرور'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KoraCornerDimens.spacing),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Image.asset(
                      'assets/images/icon-logo.png',
                      height: 150,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'أدخل بريدك الإلكتروني المسجل لإرسال رمز استعادة كلمة المرور.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        hintText: 'البريد الإلكتروني',
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      UIHelpers.buildErrorText(_errorMessage),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KoraCornerColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KoraCornerColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: KoraCornerColors.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(color: KoraCornerColors.primaryGreen, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: KoraCornerTheme.primaryButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(KoraCornerColors.primaryGreen),
                      ),
                      onPressed: _isLoading ? null : _sendResetCode,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('إرسال الرمز'),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'العودة إلى تسجيل الدخول',
                        style: TextStyle(color: KoraCornerColors.primaryGreen),
                      ),
                    ),
                  ],
                ),  
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
