import 'package:go_router/go_router.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/password_reset_otp_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/update_password_screen.dart';
import '../features/bank/presentation/bank_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/ehbd_sah/presentation/GuessRightScreen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/offside/presentation/offside_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/password/presentation/password_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/rank/presentation/rank_screen.dart';
import '../features/risk_challenge/presentation/risk_challenge_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/three_in_one/presentation/three_in_one_setup_screen.dart';
import '../features/top_10/presentation/top_10_screen.dart';
import '../features/who_am_i/presentation/who_am_i_screen.dart';
import '../features/who_is_in_picture/presentation/who_is_in_picture_screen.dart';
import '../features/xo/presentation/xo_screen.dart';


class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/bank',
        builder: (context, state) {
          final allGameQuestions = state.extra as List<dynamic>? ?? [];
          return BankScreen(allGameQuestions: allGameQuestions);
        },
      ),
      GoRoute(
        path: '/GuessRightScreen',
        builder: (context, state) => const GuessRightScreen(),
      ),
      GoRoute(
        path: '/OffsideChallengeScreen',
        builder: (context, state) => const OffsideChallengeScreen(),
      ),
      GoRoute(
        path: '/password',
        builder: (context, state) => const PasswordScreen(),
      ),
      GoRoute(
        path: '/three-in-one-setup',
        builder: (context, state) => const ThreeInOneSetupScreen(),
      ),
      GoRoute(
        path: '/top-10',
        builder: (context, state) => const Top10Screen(),
      ),
      GoRoute(
        path: '/who-is-in-picture',
        builder: (context, state) => const WhoIsInPictureScreen(),
      ),
      GoRoute(
        path: '/who-am-i',
        builder: (context, state) => const WhoAmIScreen(),
      ),
      GoRoute(
        path: '/XOXOChallengeScreen',
        builder: (context, state) => const XOChallengeScreen(),
      ),
      GoRoute(
        path: '/risk-challenge',
        builder: (context, state) => const RiskChallengeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String?;
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
        GoRoute(
        path: '/password-reset-otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          return PasswordResetOtpScreen(email: email);
        },
      ),
        GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/rank',
        builder: (context, state) => const RankScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
