import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/couple_care.dart';
import '../../domain/couple_interaction.dart';
import '../../domain/cycle_mascot.dart';
import '../../domain/cycle_phase_info.dart';
import '../../domain/date_key.dart';
import '../../domain/day_entry.dart';
import '../../domain/personal_care_advisor.dart';
import '../../state/providers.dart';
import '../../state/update_controller.dart';
import '../../theme/cycle_theme.dart';
import '../common/widgets/responsive_bounds.dart';
import '../couple/couple_space_screen.dart';
import '../log/day_log_screen.dart';
import 'widgets/body_explainer_card.dart';
import 'widgets/couple_care_card.dart';
import 'widgets/cycle_dial.dart';
import 'widgets/mascot_companion_card.dart';
import 'widgets/phase_card.dart';
import 'widgets/self_care_checklist_card.dart';
import 'widgets/today_summary_card.dart';
import 'widgets/in_app_update_dialog.dart';
import 'widgets/update_banner_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  void _openTodayLog(BuildContext context, DateTime today) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayLogScreen(date: today),
      ),
    );
  }

  void _openCoupleSpace(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CoupleSpaceScreen(),
      ),
    );
  }

  void _toggleSelfCareMission({
    required WidgetRef ref,
    required String? profileId,
    required String? uid,
    required String todayKey,
    required DayEntry? todayEntry,
    required String missionId,
  }) {
    if (profileId == null || uid == null) return;
    final baseEntry = todayEntry ?? DayEntry(date: todayKey);
    final updatedCompleted = {...baseEntry.selfCareCompleted};
    if (updatedCompleted.contains(missionId)) {
      updatedCompleted.remove(missionId);
    } else {
      updatedCompleted.add(missionId);
    }
    final nextEntry = baseEntry.copyWith(selfCareCompleted: updatedCompleted);
    unawaited(
      ref
          .read(dayRepositoryProvider)
          .saveDay(
            profileId: profileId,
            uid: uid,
            entry: nextEntry,
          )
          .catchError((Object e) {
        debugPrint('Gagal menyimpan checklist self-care: $e');
      }),
    );
  }

  void _sendCoupleSignal({
    required WidgetRef ref,
    required String? profileId,
    required CoupleSignal? signal,
  }) {
    if (profileId == null) return;
    unawaited(
      ref
          .read(profileRepositoryProvider)
          .sendSignal(profileId: profileId, signal: signal)
          .catchError((Object e) {
        debugPrint('Gagal mengirim kode pasangan: $e');
      }),
    );
  }

  void _sendPartnerReaction({
    required WidgetRef ref,
    required String? profileId,
    required PartnerReaction? reaction,
  }) {
    if (profileId == null) return;
    unawaited(
      ref
          .read(profileRepositoryProvider)
          .sendReaction(profileId: profileId, reaction: reaction)
          .catchError((Object e) {
        debugPrint('Gagal mengirim balasan pasangan: $e');
      }),
    );
  }

  void _updateMascot({
    required WidgetRef ref,
    required String? profileId,
    required MascotCharacter mascot,
  }) {
    if (profileId == null) return;
    unawaited(
      ref
          .read(profileRepositoryProvider)
          .updateMascot(profileId: profileId, mascot: mascot)
          .catchError((Object e) {
        debugPrint('Gagal mengubah maskot: $e');
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final profileId = ref.watch(activeProfileIdProvider).valueOrNull;
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final entries = ref.watch(dayEntriesProvider).valueOrNull ?? const <DayEntry>[];
    final prediction = ref.watch(predictionProvider);
    final interactions = ref.watch(coupleInteractionsProvider).valueOrNull ?? const <CoupleInteraction>[];

    final todayKey = dateKey(today);
    final yesterdayKey = dateKey(addDays(today, -1));
    DayEntry? todayEntry;
    DayEntry? yesterdayEntry;
    for (final entry in entries) {
      if (entry.date == todayKey) {
        todayEntry = entry;
      } else if (entry.date == yesterdayKey) {
        yesterdayEntry = entry;
      }
    }

    final phase = prediction.currentPhase(today);
    final phaseInfo = CyclePhaseInfo.forPhase(phase);

    final isPartner =
        profile != null && user != null && !profile.isOwner(user.uid);
    final profileName = profile?.name.trim() ?? '';
    final contextualGreeting = PersonalCareAdvisor.contextualGreeting(
      profileName: profileName,
      phase: phase,
      todayEntry: todayEntry,
      yesterdayEntry: yesterdayEntry,
      isPartner: isPartner,
    );
    final bodyExplanation = PersonalCareAdvisor.explainToday(
      phase: phase,
      todayEntry: todayEntry,
    );
    final missions = PersonalCareAdvisor.missionsForPhase(phase);
    final dateSubtitle = _formatDate(today);
    final updateState = ref.watch(appUpdateControllerProvider);

    ref.listen<AppUpdateState>(appUpdateControllerProvider, (previous, next) {
      if (previous?.phase != AppUpdatePhase.updateAvailable &&
          next.phase == AppUpdatePhase.updateAvailable &&
          !next.bannerDismissed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            unawaited(
              InAppUpdateDialog.showIfAvailable(
                context: context,
                updateState: next,
                onDownload: () => unawaited(
                  ref
                      .read(appUpdateControllerProvider.notifier)
                      .downloadAndApplyPatch(),
                ),
                onDismiss: () => ref
                    .read(appUpdateControllerProvider.notifier)
                    .dismissBanner(),
              ),
            );
          }
        });
      }
    });

    // Incoming love interaction banner
    CoupleInteraction? incomingLove;
    for (final interaction in interactions) {
      if (user != null && interaction.senderUid != user.uid) {
        final isUnreplied = !interaction.isRead || interaction.repliedAt == null;
        final isRecent = DateTime.now().difference(interaction.createdAt).inHours.abs() < 24 ||
            today.difference(interaction.createdAt).inHours.abs() < 24;
        if (isUnreplied && isRecent) {
          incomingLove = interaction;
        }
        break;
      }
    }

    final loveSenderDisplayName = incomingLove == null
        ? ''
        : (incomingLove.senderName.trim().isEmpty
            ? 'Pasangan'
            : incomingLove.senderName.trim());

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBounds(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom Header
                Text(
                  dateSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contextualGreeting.headline,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contextualGreeting.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Top banner for incoming love interaction
                if (incomingLove != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CycleColors.primary.withValues(alpha: 0.12),
                          CycleColors.secondary.withValues(alpha: 0.18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CycleColors.primary.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openCoupleSpace(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '💌 $loveSenderDisplayName baru saja mengirim: ${incomingLove.emoji} ${incomingLove.text} (Ketuk untuk membalas)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: CycleColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // OTA Update Banner (Shorebird Code Push)
                UpdateBannerCard(
                  updateState: updateState,
                  onDownload: () => unawaited(
                    ref
                        .read(appUpdateControllerProvider.notifier)
                        .downloadAndApplyPatch(),
                  ),
                  onDismiss: () => ref
                      .read(appUpdateControllerProvider.notifier)
                      .dismissBanner(),
                ),

                // Mascot Companion Card
                MascotCompanionCard(
                  character: profile?.selectedMascot ?? MascotCharacter.mochiKitten,
                  phase: phase,
                  todayEntry: todayEntry,
                  isPartner: isPartner,
                  partnerName: profileName,
                  onSelectMascot: (mascot) => _updateMascot(
                    ref: ref,
                    profileId: profileId ?? profile?.id,
                    mascot: mascot,
                  ),
                ),
                const SizedBox(height: 16),

                // Hero Cycle Dial
                Center(
                  child: CycleDial(
                    prediction: prediction,
                    today: today,
                  ),
                ),
                const SizedBox(height: 16),

                // Differentiated Primary CTA Button
                if (isPartner) ...[
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          CycleColors.primary,
                          CycleColors.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CycleColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      key: const Key('partnerSendLoveBtn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _openCoupleSpace(context),
                      icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                      label: Text(
                        'Kirim Perhatian ke ${profileName.isEmpty ? 'Pasangan' : profileName} 💖',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Prominent Quick Log CTA Button for Owner
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          CycleColors.primary,
                          CycleColors.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CycleColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _openTodayLog(context, today),
                      icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
                      label: const Text(
                        'Catat Hari Ini',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Couple Care Card (Owner Signal Sender or Partner Guide & Reaction)
                CoupleCareCard(
                  isPartner: isPartner,
                  partnerName: profileName,
                  phase: phase,
                  activeSignal: profile?.activeSignal,
                  signalReaction: profile?.signalReaction,
                  onSelectSignal: (signal) => _sendCoupleSignal(
                    ref: ref,
                    profileId: profileId ?? profile?.id,
                    signal: signal,
                  ),
                  onSelectReaction: (reaction) => _sendPartnerReaction(
                    ref: ref,
                    profileId: profileId ?? profile?.id,
                    reaction: reaction,
                  ),
                ),
                const SizedBox(height: 14),

                // Smart Body Explainer Card ("Kenapa Tubuhmu Merasa Begini?")
                if (bodyExplanation != null) ...[
                  BodyExplainerCard(explanation: bodyExplanation),
                  const SizedBox(height: 14),
                ],

                // Daily Self-Care Checklist (3 Phase Micro-Missions)
                if (!isPartner) ...[
                  SelfCareChecklistCard(
                    missions: missions,
                    completedIds: todayEntry?.selfCareCompleted ?? const {},
                    onToggleMission: (missionId) => _toggleSelfCareMission(
                      ref: ref,
                      profileId: profileId ?? profile?.id,
                      uid: user?.uid,
                      todayKey: todayKey,
                      todayEntry: todayEntry,
                      missionId: missionId,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Daily Cycle Phase Status Card
                PhaseCard(phaseInfo: phaseInfo),
                const SizedBox(height: 14),

                // Today's Recorded Summary Card
                TodaySummaryCard(entry: todayEntry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
