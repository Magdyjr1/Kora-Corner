import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Helper functions for displaying inline error messages
class UIHelpers {
  /// Get user-friendly error message from technical error
  static String getUserFriendlyMessage(Object error, {String? context}) {
    final errorString = error.toString().toLowerCase();
    
    // Handle common auth errors
    if (errorString.contains('invalid_grant') || 
        errorString.contains('invalid login credentials') ||
        errorString.contains('email not confirmed')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    
    if (errorString.contains('email already registered') ||
        errorString.contains('user already registered')) {
      return 'هذا البريد الإلكتروني مسجل بالفعل';
    }
    
    if (errorString.contains('username') && errorString.contains('already')) {
      return 'اسم المستخدم هذا مستخدم بالفعل';
    }
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'يرجى التحقق من اتصال الإنترنت';
    }
    
    if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
    }
    
    // Generic fallback
    return 'حدث خطأ. يرجى المحاولة مرة أخرى';
  }

  /// Build inline error text widget
  static Widget buildErrorText(String? error, {EdgeInsets? padding}) {
    if (error == null || error.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 8, right: 12, left: 12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.red,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: AppColors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build generic error container
  static Widget buildGenericError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

