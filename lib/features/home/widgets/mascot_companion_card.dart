import 'package:flutter/material.dart';

import '../../../domain/cycle_mascot.dart';
import '../../../domain/cycle_phase.dart';
import '../../../domain/day_entry.dart';
import '../../../theme/cycle_theme.dart';

class MascotCompanionCard extends StatefulWidget {
  const MascotCompanionCard({
    super.key,
    required this.character,
    required this.phase,
    required this.todayEntry,
    required this.isPartner,
    required this.partnerName,
    required this.onSelectMascot,
  });

  final MascotCharacter character;
  final CyclePhase phase;
  final DayEntry? todayEntry;
  final bool isPartner;
  final String partnerName;
  final ValueChanged<MascotCharacter> onSelectMascot;

  @override
  State<MascotCompanionCard> createState() => _MascotCompanionCardState();
}

class _MascotCompanionCardState extends State<MascotCompanionCard>
    with SingleTickerProviderStateMixin {
  int _quoteIndex = 0;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (!bindingName.contains('Test')) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _cycleQuote() {
    setState(() {
      _quoteIndex++;
    });
  }

  Future<void> _openMascotPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<MascotCharacter>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Maskot Pendamping ✨',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Karakter pilihanmu akan tampil di Beranda kalian berdua dan berekspresi sesuai fase siklus.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final item in MascotCharacter.values)
                    ListTile(
                      key: Key('mascot_option_${item.name}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: CycleColors.primary.withValues(alpha: 0.12),
                        child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                      title: Text(
                        item.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        item.tagline,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: item == widget.character
                          ? const Icon(Icons.check_circle_rounded, color: CycleColors.primary)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onTap: () => Navigator.of(sheetCtx).pop(item),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (chosen != null && chosen != widget.character) {
      widget.onSelectMascot(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final moodState = CycleMascotAdvisor.resolveMoodState(
      phase: widget.phase,
      todayEntry: widget.todayEntry,
    );
    final messages = CycleMascotAdvisor.bubbleMessages(
      character: widget.character,
      state: moodState,
      isPartner: widget.isPartner,
      partnerName: widget.partnerName,
    );
    final activeQuote = messages[_quoteIndex % messages.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  CycleColors.surfaceDark,
                  CycleColors.primary.withValues(alpha: 0.14),
                ]
              : [
                  Colors.white,
                  CycleColors.secondary.withValues(alpha: 0.16),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CycleColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CycleColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${moodState.badgeEmoji} ${widget.character.displayName} • ${moodState.statusLabel}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: CycleColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                key: const Key('changeMascotButton'),
                onPressed: () => _openMascotPicker(context),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: CycleColors.primary),
                label: const Text(
                  'Ganti',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: CycleColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            key: const Key('mascotTapArea'),
            borderRadius: BorderRadius.circular(16),
            onTap: _cycleQuote,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final dy = (_floatController.value - 0.5) * 6.0;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: CustomPaint(
                        painter: _MascotVectorPainter(
                          character: widget.character,
                          moodState: moodState,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: CycleColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeQuote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ketuk maskot untuk sapaan lainnya 💬',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotVectorPainter extends CustomPainter {
  const _MascotVectorPainter({
    required this.character,
    required this.moodState,
  });

  final MascotCharacter character;
  final MascotMoodState moodState;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = size.width * 0.34;

    final bodyColor = switch (character) {
      MascotCharacter.mochiKitten => const Color(0xFFFFF1F5),
      MascotCharacter.fluffyBunny => const Color(0xFFFDF2F8),
      MascotCharacter.babyDino => const Color(0xFFECFDF5),
      MascotCharacter.chibiGirl => const Color(0xFFFFF7ED),
    };

    final accentColor = switch (character) {
      MascotCharacter.mochiKitten => CycleColors.primary,
      MascotCharacter.fluffyBunny => CycleColors.secondary,
      MascotCharacter.babyDino => const Color(0xFF10B981),
      MascotCharacter.chibiGirl => const Color(0xFFF43F5E),
    };

    final earPaint = Paint()..color = accentColor.withValues(alpha: 0.35);
    final bodyPaint = Paint()..color = bodyColor;
    final outlinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Ears / Horns / Hair buns based on character
    if (character == MascotCharacter.fluffyBunny) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - 11, center.dy - radius - 8),
          width: 10,
          height: 22,
        ),
        earPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + 11, center.dy - radius - 8),
          width: 10,
          height: 22,
        ),
        earPaint,
      );
    } else if (character == MascotCharacter.mochiKitten) {
      final leftEar = Path()
        ..moveTo(center.dx - 18, center.dy - 10)
        ..lineTo(center.dx - 22, center.dy - radius - 8)
        ..lineTo(center.dx - 4, center.dy - 18)
        ..close();
      final rightEar = Path()
        ..moveTo(center.dx + 18, center.dy - 10)
        ..lineTo(center.dx + 22, center.dy - radius - 8)
        ..lineTo(center.dx + 4, center.dy - 18)
        ..close();
      canvas.drawPath(leftEar, earPaint);
      canvas.drawPath(rightEar, earPaint);
    } else if (character == MascotCharacter.babyDino) {
      canvas.drawCircle(Offset(center.dx, center.dy - radius - 5), 5, earPaint);
      canvas.drawCircle(Offset(center.dx - 12, center.dy - radius - 1), 4, earPaint);
      canvas.drawCircle(Offset(center.dx + 12, center.dy - radius - 1), 4, earPaint);
    } else {
      canvas.drawCircle(Offset(center.dx - 18, center.dy - 14), 8, earPaint);
      canvas.drawCircle(Offset(center.dx + 18, center.dy - 14), 8, earPaint);
    }

    // Face circle
    canvas.drawCircle(center, radius, bodyPaint);
    canvas.drawCircle(center, radius, outlinePaint);

    // Rosy cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.45);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 12, center.dy + 3), width: 9, height: 5),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 12, center.dy + 3), width: 9, height: 5),
      cheekPaint,
    );

    // Eyes & Mouth based on MascotMoodState
    final featurePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final eyeFillPaint = Paint()..color = const Color(0xFF334155);

    if (moodState == MascotMoodState.comfyRest) {
      // Closed comfy eyes
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx - 9, center.dy - 3), width: 8, height: 5),
        0,
        3.14,
        false,
        featurePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx + 9, center.dy - 3), width: 8, height: 5),
        0,
        3.14,
        false,
        featurePaint,
      );
    } else {
      canvas.drawCircle(Offset(center.dx - 9, center.dy - 3), 2.8, eyeFillPaint);
      canvas.drawCircle(Offset(center.dx + 9, center.dy - 3), 2.8, eyeFillPaint);
    }

    // Mouth
    if (moodState == MascotMoodState.cravingPouty) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 7), width: 7, height: 4),
        3.14,
        3.14,
        false,
        featurePaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: 8, height: 6),
        0,
        3.14,
        false,
        featurePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotVectorPainter oldDelegate) {
    return oldDelegate.character != character || oldDelegate.moodState != moodState;
  }
}
