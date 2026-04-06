import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/styles.dart';

class NumericPad extends StatelessWidget {
  final Function(String) onInput;
  final VoidCallback onBackspace;
  final VoidCallback? onDone;

  const NumericPad({
    super.key,
    required this.onInput,
    required this.onBackspace,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppStyles.kDefaultRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildButton(context, '1'),
              _buildButton(context, '2'),
              _buildButton(context, '3'),
              _buildOperatorButton(context, '/', Icons.divide),
            ],
          ),
          Row(
            children: [
              _buildButton(context, '4'),
              _buildButton(context, '5'),
              _buildButton(context, '6'),
              _buildOperatorButton(context, '*', Icons.close),
            ],
          ),
          Row(
            children: [
              _buildButton(context, '7'),
              _buildButton(context, '8'),
              _buildButton(context, '9'),
              _buildOperatorButton(context, '-', Icons.remove),
            ],
          ),
          Row(
            children: [
              _buildButton(context, '.'),
              _buildButton(context, '0'),
              _buildButton(context, null, icon: Icons.backspace_rounded, isBackspace: true),
              _buildOperatorButton(context, '+', Icons.add),
            ],
          ),
          if (onDone != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                ),
                child: const Text('OK / VALIDER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOperatorButton(BuildContext context, String op, IconData icon) {
    final theme = Theme.of(context);
    return _buildButton(context, op, icon: icon, isOperator: true);
  }

  Widget _buildButton(BuildContext context, String? value, {IconData? icon, bool isBackspace = false, bool isOperator = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color? getBgColor() {
      if (isOperator) return theme.colorScheme.primary.withValues(alpha: 0.1);
      if (isBackspace) return theme.colorScheme.error.withValues(alpha: 0.05);
      return isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02);
    }

    Color? getTextColor() {
      if (isOperator) return theme.colorScheme.primary;
      if (isBackspace) return theme.colorScheme.error;
      return theme.colorScheme.onSurface;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (isBackspace) {
                onBackspace();
              } else if (value != null) {
                onInput(value);
              }
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOperator 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.03),
                ),
                color: getBgColor(),
              ),
              child: icon != null 
                ? Icon(icon, size: 20, color: getTextColor())
                : Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: getTextColor(),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
