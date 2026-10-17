import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/couple_interaction.dart';
import '../../../state/providers.dart';
import '../../../theme/cycle_theme.dart';

class AddCustomStickerDialog extends ConsumerStatefulWidget {
  const AddCustomStickerDialog({
    super.key,
    required this.profileId,
    this.initialIsReply = false,
  });

  final String profileId;
  final bool initialIsReply;

  @override
  ConsumerState<AddCustomStickerDialog> createState() => _AddCustomStickerDialogState();
}

class _AddCustomStickerDialogState extends ConsumerState<AddCustomStickerDialog> {
  static const List<String> _popularEmojis = [
    '🧸', '🧋', '🍫', '💆‍♂️',
    '👂', '💖', '🥰', '🥺',
    '🌸', '☕', '🍜', '🛌',
    '💌', '✨', '💐', '🍓',
    '🫂', '🍧', '🍕', '🍯',
  ];

  late String _selectedEmoji;
  late bool _isReply;
  late final TextEditingController _textController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = _popularEmojis.first;
    _isReply = widget.initialIsReply;
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Pesan stiker tidak boleh kosong');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final sticker = CustomCoupleSticker(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        emoji: _selectedEmoji,
        text: text,
        isReply: _isReply,
      );

      await ref.read(profileRepositoryProvider).addCustomSticker(
            profileId: widget.profileId,
            sticker: sticker,
          );

      if (mounted) {
        Navigator.of(context).pop(sticker);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Gagal menyimpan stiker: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? CycleColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CycleColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('✨', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Buat Stiker Cinta Baru',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selected emoji preview
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: CycleColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CycleColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Emoji picker grid
              const Text(
                'Pilih Ikon Emoji:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _popularEmojis.map((emoji) {
                  final isSelected = emoji == _selectedEmoji;
                  return InkWell(
                    key: Key('emoji_picker_$emoji'),
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CycleColors.primary.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? CycleColors.primary
                              : Colors.grey.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Text Field (max 35 chars)
              TextField(
                key: const Key('customStickerTextInput'),
                controller: _textController,
                maxLength: 35,
                decoration: InputDecoration(
                  labelText: 'Kata-kata Perhatian / Balasan',
                  hintText: 'Contoh: Peluk jauh dari akuu 🤗',
                  errorText: _errorMessage,
                  counterText: '${_textController.text.length}/35',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {
                  if (_errorMessage != null) _errorMessage = null;
                }),
              ),
              const SizedBox(height: 8),

              // Category toggle: Kirim Perhatian vs Balasan Cepat
              const Text(
                'Tipe Stiker:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      key: const Key('stickerTypeCare'),
                      label: const Text('Kirim Perhatian'),
                      selected: !_isReply,
                      onSelected: (val) {
                        if (val) setState(() => _isReply = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      key: const Key('stickerTypeReply'),
                      label: const Text('Balasan Cepat'),
                      selected: _isReply,
                      onSelected: (val) {
                        if (val) setState(() => _isReply = true);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('saveCustomStickerBtn'),
                    onPressed: _isSaving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: CycleColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Simpan Stiker'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
