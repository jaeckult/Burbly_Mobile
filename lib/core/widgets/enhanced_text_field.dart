import 'package:flutter/material.dart';

class EnhancedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final VoidCallback? onSuffixIconPressed;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final String? errorText;

  /// NEW: choose border style
  final bool borderless; // removes border entirely
  final bool showDivider; // adds a divider below field

  const EnhancedTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.onSuffixIconPressed,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.errorText,
    this.borderless = false,   // default false → keep normal underline
    this.showDivider = false,  // default false → no divider
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField> {
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: widget.borderless ? InputBorder.none : null, // 👈
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: Theme.of(context).primaryColor)
            : null,
        suffixIcon: _buildSuffixIcon(),
        errorText: widget.errorText,
      ),
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      obscureText: _obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      buildCounter: widget.maxLength != null
          ? (context, {required currentLength, required isFocused, maxLength}) {
              return isFocused
                  ? Text(
                      '$currentLength/$maxLength',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    )
                  : null;
            }
          : null,
    );

    // Wrap with divider if requested
    if (widget.showDivider) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          field,
          const Divider(height: 1),
        ],
      );
    }

    return field;
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: Theme.of(context).hintColor,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon, color: Theme.of(context).hintColor),
        onPressed: widget.onSuffixIconPressed,
      );
    }

    if (widget.controller.text.isNotEmpty && widget.enabled && !widget.readOnly) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          widget.controller.clear();
          widget.onChanged?.call('');
        },
      );
    }

    return null;
  }
}
