import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

final supabase = Supabase.instance.client;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Timer? _usernameDebounce;
  String? _usernameError;
  bool _isCheckingUsername = false;

  Timer? _emailDebounce;
  String? _emailError;
  bool _isCheckingEmail = false;

  final _emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.removeListener(_onEmailChanged);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), _checkUsername);
  }

  void _onEmailChanged() {
    if (_emailDebounce?.isActive ?? false) _emailDebounce!.cancel();
    _emailDebounce = Timer(const Duration(milliseconds: 500), _checkEmail);
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();
    if (username.length < 4) {
      if (mounted) setState(() => _usernameError = null);
      return;
    }
    if (mounted) setState(() => _isCheckingUsername = true);
    try {
      final response = await supabase.from('profiles').select('username').eq('username', username);
      if (mounted) {
        setState(() {
          _usernameError = response.isNotEmpty ? 'اسم المستخدم هذا مستخدم بالفعل' : null;
        });
      }
    } catch (e) {
      print('Error checking username: $e');
    } finally {
      if (mounted) setState(() => _isCheckingUsername = false);
    }
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegExp.hasMatch(email)) {
      if (mounted) setState(() => _emailError = null);
      return;
    }
    if (mounted) setState(() => _isCheckingEmail = true);
    try {
      final response = await supabase.from('profiles').select('email').eq('email', email);
      if (mounted) {
        setState(() {
          _emailError = response.isNotEmpty ? 'هذا البريد الإلكتروني مستخدم بالفعل' : null;
        });
      }
    } catch (e) {
      print('Error checking email: $e');
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال اسم المستخدم';
    if (value.length < 4) return 'يجب أن يكون اسم المستخدم 4 أحرف على الأقل';
    return _usernameError;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    if (!_emailRegExp.hasMatch(value)) return 'صيغة البريد الإلكتروني غير صحيحة';
    return _emailError;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
    if (value.length < 8) return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
    if (!value.contains(RegExp(r'[a-z]'))) return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
    if (!value.contains(RegExp(r'[0-9]'))) return 'يجب أن تحتوي على رقم واحد على الأقل';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'يجب أن تحتوي على رمز خاص واحد على الأقل';
    return null;
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false) || _usernameError != null || _emailError != null) {
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final checks = await supabase
          .from('profiles')
          .select('username, email')
          .or('username.eq.$username,email.eq.$email');

      if (checks.isNotEmpty) {
        final isUsernameTaken = checks.any((p) => p['username'] == username);
        if (isUsernameTaken) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسم المستخدم هذا مستخدم بالفعل')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا البريد الإلكتروني مستخدم بالفعل')));
        }
        return;
      }

      await supabase.auth.signUp(email: email, password: password, data: {'username': username});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني')),
        );
        context.go('/otp', extra: {'email': email});
      }
    } on AuthException catch (error) {
      if (mounted) {
        final message = error.message.toLowerCase().contains('user already registered')
            ? 'هذا البريد الإلكتروني مسجل بالفعل'
            : 'Authentication Error: ${error.message}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.lightGrey),
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.gameOnGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.gameOnGreen, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.gameOnGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.red, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUsernameFormatValid = _usernameController.text.length >= 4;
    final isEmailFormatValid = _emailController.text.isNotEmpty && _emailRegExp.hasMatch(_emailController.text);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.darkPitch,
        resizeToAvoidBottomInset: true,
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16).copyWith(bottom: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Image.asset('assets/images/word.png', height: 150),
                  const SizedBox(height: 20),
                  Text(
                    'إنشاء حساب',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Vexa',
                      color: AppColors.gameOnGreen,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    validator: _validateUsername,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: const TextStyle(color: AppColors.white),
                    decoration: _buildInputDecoration(
                      'اسم المستخدم',
                      suffixIcon: _isCheckingUsername
                          ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : (_usernameError == null && isUsernameFormatValid
                          ? const Icon(Icons.check, color: Colors.green)
                          : null),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: const TextStyle(color: AppColors.white),
                    decoration: _buildInputDecoration(
                      'البريد الإلكتروني',
                      suffixIcon: _isCheckingEmail
                          ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : (_emailError == null && isEmailFormatValid
                          ? const Icon(Icons.check, color: Colors.green)
                          : null),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    validator: _validatePassword,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: const TextStyle(color: AppColors.white),
                    decoration: _buildInputDecoration('كلمة المرور'),
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gameOnGreen,
                      foregroundColor: AppColors.black,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: (_isLoading ||
                        _isCheckingUsername ||
                        _isCheckingEmail ||
                        _usernameError != null ||
                        _emailError != null)
                        ? null
                        : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('إنشاء الحساب'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لديك حساب بالفعل؟ ',
                          style: TextStyle(color: AppColors.lightGrey)),
                      InkWell(
                        onTap: () => context.go('/login'),
                        child: const Text('تسجيل الدخول',
                            style: TextStyle(color: AppColors.gameOnGreen)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}