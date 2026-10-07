import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Quiet, flat search field — no Material border/underline, small radius,
/// warm neutral fill. Matches the AQARATI reference search bar exactly
/// (not a default TextField, not a pill).
class AqaratiSearchField extends StatefulWidget {
  final String hint;
  final String? initialValue;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final bool autofocus;

  const AqaratiSearchField({
    super.key,
    required this.hint,
    this.initialValue,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.autofocus = false,
  });

  @override
  State<AqaratiSearchField> createState() => _AqaratiSearchFieldState();
}

class _AqaratiSearchFieldState extends State<AqaratiSearchField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: TextField(
        controller: _controller,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        onTap: widget.onTap,
        onChanged: (v) {
          setState(() {});
          widget.onChanged?.call(v);
        },
        onSubmitted: widget.onSubmitted,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mist),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate, size: AppIconSize.compact),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: AppIconSize.compact, color: AppColors.mist),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                    widget.onChanged?.call('');
                  },
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
