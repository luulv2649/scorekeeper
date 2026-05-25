import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_store.dart';
import '../models/game_model.dart';
import '../utils/helpers.dart';
import 'game_play_screen.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final List<TextEditingController> _playerCtrls =
      List.generate(4, (_) => TextEditingController());

  ScoreDisplayMode _displayMode = ScoreDisplayMode.afterEachRound;

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _playerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    // Auto-fill tên game nếu trống
    final gameName = _nameCtrl.text.trim().isEmpty
        ? 'Ván chơi ${shortDateTime(DateTime.now())}'
        : _nameCtrl.text.trim();

    // Auto-fill tên người chơi nếu trống
    final playerNames = List.generate(4, (i) {
      final name = _playerCtrls[i].text.trim();
      return name.isEmpty ? 'Người chơi ${i + 1}' : name;
    });

    final store = context.read<GameStore>();
    final game = await store.createGame(
      name: gameName,
      playerNames: playerNames,
      displayMode: _displayMode,
    );

    if (!mounted) return;
    // Replace current screen với GamePlay
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GamePlayScreen(gameID: game.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo ván mới'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Game name ──────────────────────────────────────────────────────
            _SectionHeader(title: 'Tên ván chơi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Vd: Tiến lên tối 25/5',
                prefixIcon: Icon(Icons.edit_rounded),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 24),

            // ── Players ────────────────────────────────────────────────────────
            _SectionHeader(title: 'Người chơi (4 người)'),
            const SizedBox(height: 8),
            ...List.generate(4, (i) => _PlayerField(
                  index: i,
                  controller: _playerCtrls[i],
                )),

            const SizedBox(height: 24),

            // ── Display mode ───────────────────────────────────────────────────
            _SectionHeader(title: 'Chế độ hiển thị điểm'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: ScoreDisplayMode.values.map((mode) {
                  return RadioListTile<ScoreDisplayMode>(
                    value: mode,
                    groupValue: _displayMode,
                    title: Text(mode.label),
                    subtitle: Text(
                      mode == ScoreDisplayMode.afterEachRound
                          ? 'Tổng điểm cập nhật sau mỗi ván'
                          : 'Tổng điểm ẩn cho đến khi kết thúc game',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.outline),
                    ),
                    onChanged: (v) => setState(() => _displayMode = v!),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bắt đầu chơi'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary));
  }
}

class _PlayerField extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  const _PlayerField({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    final color = playerColor(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Người chơi ${index + 1}',
          prefixIcon: CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          border: const OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }
}
