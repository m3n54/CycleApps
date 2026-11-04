import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/cycle_profile.dart';
import '../../../state/providers.dart';
import '../../../theme/cycle_theme.dart';

class CoupleProfileEditDialog extends ConsumerStatefulWidget {
  const CoupleProfileEditDialog({
    super.key,
    required this.profile,
  });

  final CycleProfile profile;

  static Future<void> show(BuildContext context, CycleProfile profile) {
    return showDialog<void>(
      context: context,
      builder: (_) => CoupleProfileEditDialog(profile: profile),
    );
  }

  @override
  ConsumerState<CoupleProfileEditDialog> createState() =>
      _CoupleProfileEditDialogState();
}

class _CoupleProfileEditDialogState
    extends ConsumerState<CoupleProfileEditDialog> {
  late final TextEditingController _cewekNameController;
  late final TextEditingController _cowokNameController;
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cewekNameController = TextEditingController(text: widget.profile.name);
    _cowokNameController =
        TextEditingController(text: widget.profile.partnerName);
    _selectedDate = widget.profile.anniversaryDate;
  }

  @override
  void dispose() {
    _cewekNameController.dispose();
    _cowokNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cewekName = _cewekNameController.text.trim();
    final cowokName = _cowokNameController.text.trim();

    if (cewekName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pasangan cewek tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).updateCoupleMetadata(
            profileId: widget.profile.id,
            name: cewekName,
            partnerName: cowokName,
            anniversaryDate: _selectedDate,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil pasangan berhasil diperbarui! 💕'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final isOwner = widget.profile.isOwner(user?.uid);

    final formattedDate = _selectedDate != null
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
        : 'Pilih Tanggal Jadian';

    final partnerFieldLabel =
        isOwner ? 'Nama Panggilan Pasangan' : 'Nama Panggilan Kamu';
    final ownerFieldLabel =
        isOwner ? 'Nama Kamu (Pemilik Siklus)' : 'Nama Pasangan (Pemilik Siklus)';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Text('💕', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text(
            'Profil Pasangan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cewek / Owner Name
            Row(
              children: [
                const Icon(Icons.female_rounded, color: CycleColors.primary, size: 16),
                const SizedBox(width: 4),
                Text(
                  ownerFieldLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('profileNameInput'),
              controller: _cewekNameController,
              decoration: InputDecoration(
                hintText: 'Misal: Nata',
                prefixIcon: const Icon(Icons.face_3_rounded, color: CycleColors.primary, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),

            // Cowok / Partner Name
            Row(
              children: [
                const Icon(Icons.male_rounded, color: CycleColors.secondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  partnerFieldLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('partnerNameInput'),
              controller: _cowokNameController,
              decoration: InputDecoration(
                hintText: isOwner ? 'Misal: Menza / Ayang' : 'Misal: Menza',
                prefixIcon: const Icon(Icons.face_6_rounded, color: CycleColors.secondary, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),

            // Anniversary Date
            const Text(
              'Tanggal Jadian / Hari Bersama',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            InkWell(
              key: const Key('pickAnniversaryDateBtn'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? today,
                  firstDate: DateTime(1970),
                  lastDate: today,
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: CycleColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('saveCoupleMetadataBtn'),
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: CycleColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
