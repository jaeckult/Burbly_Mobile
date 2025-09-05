import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class KeyboardDismissWrapper extends StatelessWidget {
  final Widget child;
  final Duration paddingDuration;

  const KeyboardDismissWrapper({
    super.key,
    required this.child,
    this.paddingDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return GestureDetector(
          onTap: () {
            if (isKeyboardVisible) {
              FocusScope.of(context).unfocus();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedPadding(
            duration: paddingDuration,
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(
              bottom: isKeyboardVisible
                  ? MediaQuery.of(context).viewInsets.bottom
                  : 0,
            ),
            child: child,
          ),
        );
      },
    );
  }
}