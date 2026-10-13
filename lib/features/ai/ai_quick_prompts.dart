import 'package:flutter/material.dart';

class AiQuickPrompt {
  final String label;
  final String message;

  const AiQuickPrompt(this.label, this.message);
}

/// Mirrors AT-AI/frontend/src/components/widgets/faq-chips.tsx.
const aiQuickPrompts = <AiQuickPrompt>[
  AiQuickPrompt('Plan a ride', 'I need to plan a ride'),
  AiQuickPrompt('Explore Queens', 'Where should I go in Queens?'),
  AiQuickPrompt('Travel time to JFK', 'How long does it take to drive to JFK?'),
  AiQuickPrompt('Brooklyn weather', 'What is the weather like in Brooklyn?'),
  AiQuickPrompt(
    'Times Square dining',
    'What restaurants are near Times Square?',
  ),
  AiQuickPrompt(
    'Visitor tips',
    'What should a visitor know before exploring NYC?',
  ),
];

class AiQuickPromptGrid extends StatelessWidget {
  final ValueChanged<AiQuickPrompt>? onSelected;

  const AiQuickPromptGrid({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 360 ? 3 : 2;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final prompt in aiQuickPrompts)
              SizedBox(
                width: width,
                child: _PromptButton(
                  label: prompt.label,
                  onTap: onSelected == null ? null : () => onSelected!(prompt),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PromptButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PromptButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0E1A47),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1E3A8A), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onTap == null
                      ? const Color(0xFF8294AF)
                      : const Color(0xFFE2E8F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
