import 'package:flutter/material.dart';
import '../game/engine.dart';
import 'board.dart';
import 'theme.dart';

class ConfigPanel extends StatefulWidget {
  const ConfigPanel({super.key, required this.config, required this.onApply});
  final GameConfig config;
  final ValueChanged<GameConfig> onApply;
  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  late GameConfig draft = widget.config;

  @override
  void didUpdateWidget(ConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) draft = widget.config;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          const Icon(Icons.tune_rounded, color: Palette.mint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Make it your game',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const _SectionLabel('01', 'Choose your opponent'),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _ModeTile(
              title: 'Solo',
              subtitle: 'Play the AI',
              icon: Icons.smart_toy_outlined,
              selected: draft.mode == GameMode.solo,
              onTap: () =>
                  setState(() => draft = draft.copyWith(mode: GameMode.solo)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeTile(
              title: 'Two players',
              subtitle: 'Pass & play',
              icon: Icons.people_outline_rounded,
              selected: draft.mode == GameMode.local,
              onTap: () =>
                  setState(() => draft = draft.copyWith(mode: GameMode.local)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const _SectionLabel('02', 'Set the board'),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (_, constraints) => Wrap(
          spacing: 7,
          runSpacing: 8,
          children: List.generate(
            6,
            (i) => SizedBox(
              width: (constraints.maxWidth - 14) / 3,
              child: OptionButton(
                label: '${i + 3} × ${i + 3}',
                selected: draft.size == i + 3,
                onTap: () =>
                    setState(() => draft = draft.copyWith(size: i + 3)),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(
            child: Text(
              'In a row to win',
              style: TextStyle(color: Palette.muted, fontSize: 13),
            ),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            label: 'Decrease win length',
            onTap: draft.target > 3
                ? () => setState(
                    () => draft = draft.copyWith(target: draft.target - 1),
                  )
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${draft.target}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Palette.mint,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            label: 'Increase win length',
            onTap: draft.target < draft.size
                ? () => setState(
                    () => draft = draft.copyWith(target: draft.target + 1),
                  )
                : null,
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (draft.mode == GameMode.solo) ...[
        const _SectionLabel('03', 'Find your challenge'),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final level in Difficulty.values) ...[
              if (level != Difficulty.easy) const SizedBox(width: 6),
              Expanded(
                child: OptionButton(
                  label: switch (level) {
                    Difficulty.easy => 'Easy',
                    Difficulty.medium => 'Medium',
                    Difficulty.hard => 'Hard',
                  },
                  selected: draft.difficulty == level,
                  onTap: () =>
                      setState(() => draft = draft.copyWith(difficulty: level)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(switch (draft.difficulty) {
          Difficulty.easy => 'A relaxed start. The AI makes random moves.',
          Difficulty.medium => 'Stay sharp. The AI spots wins and blocks.',
          Difficulty.hard =>
            draft.size == 3
                ? 'Perfect play. Can you hold it to a draw?'
                : 'Tactical search. More room, more possibilities.',
        }, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your mark',
                style: TextStyle(color: Palette.muted, fontSize: 13),
              ),
            ),
            for (final mark in Mark.values)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 52,
                  child: OptionButton(
                    label: mark.label,
                    selected: draft.human == mark,
                    leading: MarkIcon(mark, size: 19),
                    onTap: () =>
                        setState(() => draft = draft.copyWith(human: mark)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ] else ...[
        const Text(
          'One screen. Two rivals. Take turns and make your move.',
          style: TextStyle(color: Palette.muted, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),
      ],
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('start-game'),
          onPressed: () => widget.onApply(draft),
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: const Text('Start fresh'),
        ),
      ),
      const SizedBox(height: 8),
      const Center(
        child: Text(
          'Starts a new match and clears scores.',
          style: TextStyle(color: Palette.muted, fontSize: 11),
        ),
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.number, this.title);
  final String number;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        number,
        style: const TextStyle(
          color: Palette.mint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: Material(
      color: selected
          ? Palette.mint.withValues(alpha: .11)
          : Palette.raised.withValues(alpha: .5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(
          color: selected
              ? Palette.mint.withValues(alpha: .65)
              : Palette.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child:
                  leading ??
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Palette.mint : Palette.muted,
                    ),
                  ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected
          ? Palette.mint.withValues(alpha: .08)
          : Palette.raised.withValues(alpha: .5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? Palette.mint.withValues(alpha: .6) : Palette.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Palette.mint : Palette.muted,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 44,
    child: IconButton.outlined(
      tooltip: label,
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
