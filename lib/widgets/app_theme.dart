import 'package:flutter/material.dart';

class AppTheme {
  static const Color purple = Color(0xFF7C3AFF);
  static const Color cyan = Color(0xFF00D4FF);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color cardBg = Color(0xFFF8F6FF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient verticalGradient = LinearGradient(
    colors: [purple, cyan],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: purple.withOpacity(0.15),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: purple.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration neonCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: purple.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: purple.withOpacity(0.12),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: cyan.withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? AppTheme.primaryGradient
              : const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: AppTheme.purple.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: ShaderMask(
        shaderCallback: (bounds) =>
            AppTheme.primaryGradient.createShader(bounds),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
    );
  }
}

class NeonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmitted;

  const NeonTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.purple.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.purple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  color: AppTheme.purple.withOpacity(0.7), size: 20)
              : null,
          suffix: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
