import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/game_store.dart';
import '../models/game_model.dart';
import '../utils/helpers.dart';

class AddRoundScreen extends StatefulWidget {
  final String gameID;
  final List<Player> players;
  final Round? editingRound;

  const AddRoundScreen({
    super.key,
    required this.gameID,
    required this.players,
    this.editingRound,
  });

  @override
  State<AddRoundScreen> createState() => _AddRoundScreenState();
}

class _AddRoundScreenState extends State<AddRoundScreen> {
  late final Map<String, TextEditingController> _ctrls;
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  String? _listeningPlayerID; // ID người đang nghe mic

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final p in widget.players)
        p.id: TextEditingController(
          text: widget.editingRound != null
              ? '${widget.editingRound!.scores[p.id] ?? 0}'
              : '',
        )
    };
    for (final c in _ctrls.values) {
      c.addListener(() => setState(() {}));
    }
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _listeningPlayerID = null),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _listeningPlayerID = null);
        }
      },
    );
    setState(() => _speechAvailable = available);
  }

  @override
  void dispose() {
    _speech.stop();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _currentSum =>
      _ctrls.values.map((c) => int.tryParse(c.text) ?? 0).fold(0, (a, b) => a + b);

  bool get _allFilled =>
      widget.players.every((p) => int.tryParse(_ctrls[p.id]!.text) != null);

  void _adjustScore(String playerID, int delta) {
    final current = int.tryParse(_ctrls[playerID]!.text) ?? 0;
    _ctrls[playerID]!.text = '${current + delta}';
  }

  /// Bắt đầu / dừng nghe giọng nói cho một người chơi
  Future<void> _toggleListen(String playerID) async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Giọng nói không hỗ trợ trên Windows. Dùng Android/iOS để test tính năng này.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Đang nghe người này → dừng
    if (_listeningPlayerID == playerID) {
      await _speech.stop();
      setState(() => _listeningPlayerID = null);
      return;
    }

    // Đang nghe người khác → dừng trước
    if (_speech.isListening) {
      await _speech.stop();
    }

    setState(() => _listeningPlayerID = playerID);

    await _speech.listen(
      localeId: 'vi_VN', // tiếng Việt, fallback sang en nếu không có
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
      onResult: (result) {
        if (result.finalResult) {
          // Lấy số từ kết quả nhận dạng
          final raw = result.recognizedWords
              .replaceAll(RegExp(r'[^0-9\-]'), '')
              .trim();
          if (raw.isNotEmpty) {
            setState(() {
              _ctrls[playerID]!.text = raw;
              _listeningPlayerID = null;
            });
          }
        }
      },
    );
  }

  Future<void> _save() async {
    if (!_allFilled) return;
    if (_currentSum != 0) {
      _showSumError();
      return;
    }

    final scores = {
      for (final p in widget.players)
        p.id: int.parse(_ctrls[p.id]!.text)
    };

    final store = context.read<GameStore>();
    if (widget.editingRound != null) {
      await store.updateRound(widget.gameID, widget.editingRound!.id, scores);
    } else {
      await store.addRound(widget.gameID, scores);
    }

    if (mounted) Navigator.pop(context);
  }

  void _showSumError() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
        title: const Text('Tổng điểm không hợp lệ'),
        content: Text(
          'Tổng điểm của tất cả người chơi phải bằng 0.\n\nHiện tại: $_currentSum',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kiểm tra lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingRound != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa ván' : 'Thêm ván mới'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _allFilled ? _save : null,
            child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          _SumIndicator(sum: _currentSum, allFilled: _allFilled),

          // Gợi ý giọng nói
          if (_speechAvailable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, size: 14,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Nhấn 🎤 để nói số điểm (vd: "50", "-30")',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final player = widget.players[i];
                return _ScoreInputCard(
                  player: player,
                  playerIndex: i,
                  controller: _ctrls[player.id]!,
                  onAdjust: (delta) => _adjustScore(player.id, delta),
                  isListening: _listeningPlayerID == player.id,
                  speechAvailable: _speechAvailable,
                  onMicTap: () => _toggleListen(player.id),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _allFilled ? _save : null,
                icon: const Icon(Icons.check_rounded),
                label: Text(isEditing ? 'Cập nhật ván' : 'Lưu ván'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sum Indicator ────────────────────────────────────────────────────────────

class _SumIndicator extends StatelessWidget {
  final int sum;
  final bool allFilled;
  const _SumIndicator({required this.sum, required this.allFilled});

  @override
  Widget build(BuildContext context) {
    final isValid = sum == 0 && allFilled;
    final color = isValid ? Colors.green : Colors.red;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: color.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Tổng điểm:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              '$sum',
              key: ValueKey(sum),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
          if (isValid) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
          ],
        ],
      ),
    );
  }
}

// ─── Score Input Card ─────────────────────────────────────────────────────────

class _ScoreInputCard extends StatelessWidget {
  final Player player;
  final int playerIndex;
  final TextEditingController controller;
  final void Function(int delta) onAdjust;
  final bool isListening;
  final bool speechAvailable;
  final VoidCallback onMicTap;

  const _ScoreInputCard({
    required this.player,
    required this.playerIndex,
    required this.controller,
    required this.onAdjust,
    required this.isListening,
    required this.speechAvailable,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = playerColor(playerIndex);

    return Card(
      color: isListening ? Colors.red.withOpacity(0.06) : null,
      shape: isListening
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                initials(player.name),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),

            // Name
            Expanded(
              child: Text(player.name,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),

            // -10
            IconButton(
              onPressed: () => onAdjust(-10),
              icon: const Icon(Icons.remove_circle_rounded),
              color: Colors.red.shade400,
              iconSize: 26,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

            // Score field
            SizedBox(
              width: 68,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: false),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
            ),

            // +10
            IconButton(
              onPressed: () => onAdjust(10),
              icon: const Icon(Icons.add_circle_rounded),
              color: Colors.green.shade600,
              iconSize: 26,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

            // Mic button — luôn hiển thị, mờ nếu không hỗ trợ
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onMicTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isListening
                      ? Colors.red
                      : speechAvailable
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: 18,
                  color: isListening
                      ? Colors.white
                      : speechAvailable
                          ? Colors.red.shade600
                          : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
