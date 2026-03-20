import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mecca/core/theme/app_colors.dart';

class CustomTextformField extends StatelessWidget {
  const CustomTextformField({
    super.key,
    this.controller,
    this.label,
    this.validator,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLines,
    this.textInputAction,
    this.inputFormatters,
    this.fillColor = AppColors.surface,
  });
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final String? label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textInputAction: textInputAction,
      maxLines: maxLines,
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        isDense: true,
        filled: true,
        fillColor: fillColor,
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
