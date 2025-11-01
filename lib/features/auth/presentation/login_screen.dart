import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/game_on_theme.dart';
import 'google_sign_in_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user != null && mounted) {
        context.go('/home');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(KoraCornerDimens.spacing),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Image.asset(
                    'assets/images/word.png',
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Kora Corner',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: KoraCornerColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'البريد الإلكتروني',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    validator: _validatePassword,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: KoraCornerColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'كلمة المرور',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => context.go('/forgot-password'), // Corrected navigation
                      child: const Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(color: KoraCornerColors.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: KoraCornerTheme.primaryButtonStyle,
                    onPressed: _signIn,
                    child: const Text('دخول'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ليس لديك حساب ؟ ',
                        style: TextStyle(color: KoraCornerColors.textSecondary),
                      ),
                      InkWell(
                        onTap: () => context.go('/signup'),
                        child: const Text(
                          'انشاء حساب',
                          style: TextStyle(color: KoraCornerColors.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(
                        child:
                        Divider(thickness: 1, indent: 40, endIndent: 10),
                      ),
                      Text("أو"),
                      Expanded(
                        child:
                        Divider(thickness: 1, indent: 10, endIndent: 40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const GoogleSignInButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
