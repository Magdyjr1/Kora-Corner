import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wrapper widget that intercepts native back button presses
/// and navigates to Home Screen instead of going back in navigation stack
/// Note: Banner ads should be added individually to each screen's Scaffold
class BackToHomeWrapper extends StatelessWidget {
  final Widget child;

  const BackToHomeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home screen, clearing the navigation stack
        context.go('/home');
        return false; // Prevent default back behavior
      },
      child: child,
    );
  }
}

