import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../utils/helpers.dart';

class GameResultScreen extends StatelessWidget {
  final Game game;
  const GameResultScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Sắp xếp từ cao xuống thấp (điểm cao = thua nhiều)
    final rankings = game.rankings().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              // Về home, xóa toàn bộ stack
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer,
                  cs.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.flag_rounded, size: 40, color: Colors.orange),
                const SizedBox(height: 8),
                Text(
                  game.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${game.rounds.length} ván • ${game.players.length} người chơi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),

          // ── Rankings ──────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rankings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final item = rankings[i];
                final playerIdx = game.players
                    .indexWhere((p) => p.id == item.player.id);
                final color = playerColor(playerIdx);
                final rank = i + 1;

                return _RankCard(
                  rank: rank,
                  playerName: item.player.name,
                  total: item.total,
                  playerColor: color,
                  colorScheme: cs,
                  roundCount: game.rounds.length,
                );
              },
            ),
          ),

          // ── Bottom button ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Về trang chủ'),
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

// ─── Rank Card ────────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  final int rank;
  final String playerName;
  final int total;
  final Color playerColor;
  final ColorScheme colorScheme;
  final int roundCount;

  const _RankCard({
    required this.rank,
    required this.playerName,
    required this.total,
    required this.playerColor,
    required this.colorScheme,
    required this.roundCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final isFirst = rank == 1;

    return Container(
      decoration: BoxDecoration(
        color: isFirst
            ? Colors.amber.withOpacity(0.12)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: isFirst
            ? Border.all(color: Colors.amber.shade400, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 44,
            child: _rankWidget(rank),
          ),

          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: playerColor.withOpacity(0.15),
            child: Text(
              initials(playerName),
              style: TextStyle(
                color: playerColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name + rounds info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Trung bình: ${roundCount > 0 ? (total / roundCount).toStringAsFixed(1) : 0} / ván',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.outline,
                      ),
                ),
              ],
            ),
          ),

          // Total score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor(total, cs),
                    ),
              ),
              Text(
                'điểm',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankWidget(int rank) {
    switch (rank) {
      case 1:
        return const Text('🥇', style: TextStyle(fontSize: 32),
            textAlign: TextAlign.center);
      case 2:
        return const Text('🥈', style: TextStyle(fontSize: 32),
            textAlign: TextAlign.center);
      case 3:
        return const Text('🥉', style: TextStyle(fontSize: 32),
            textAlign: TextAlign.center);
      default:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
    }
  }
}
