import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_store.dart';
import '../models/game_model.dart';
import '../utils/helpers.dart';

class GameDetailScreen extends StatelessWidget {
  final String gameID;
  const GameDetailScreen({super.key, required this.gameID});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStore>().gameById(gameID);
    if (game == null) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: Text('Không tìm thấy')));
    }
    return _DetailContent(game: game);
  }
}

class _DetailContent extends StatelessWidget {
  final Game game;
  const _DetailContent({required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GameInfoCard(game: game),
          const SizedBox(height: 16),
          if (game.isFinished || game.displayMode == ScoreDisplayMode.afterEachRound)
            _FinalScoreCard(game: game),
          const SizedBox(height: 16),
          if (game.rounds.isNotEmpty) _RoundsBreakdownCard(game: game),
        ],
      ),
    );
  }
}

// ─── Game Info Card ───────────────────────────────────────────────────────────

class _GameInfoCard extends StatelessWidget {
  final Game game;
  const _GameInfoCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(game.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                _StatusBadge(isFinished: game.isFinished),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _InfoItem(
                    icon: Icons.people_rounded,
                    label: 'Người chơi',
                    value: '${game.players.length}'),
                _InfoItem(
                    icon: Icons.layers_rounded,
                    label: 'Số ván',
                    value: '${game.rounds.length}'),
                _InfoItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Ngày tạo',
                    value: shortDate(game.createdAt)),
              ],
            ),
            if (game.finishedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Kết thúc: ${shortDateTime(game.finishedAt!)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Final Score Card ─────────────────────────────────────────────────────────

class _FinalScoreCard extends StatelessWidget {
  final Game game;
  const _FinalScoreCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final rankings = game.rankings();
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bảng điểm',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(rankings.length, (i) {
              final item = rankings[i];
              final playerIdx =
                  game.players.indexWhere((p) => p.id == item.player.id);
              final color = playerColor(playerIdx);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Rank medal
                        _RankBadge(rank: i + 1),
                        const SizedBox(width: 10),
                        // Player avatar
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(initials(item.player.name),
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.player.name,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        Text(
                          '${item.total}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor(item.total, cs),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (i < rankings.length - 1) const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Rounds Breakdown Card ────────────────────────────────────────────────────

class _RoundsBreakdownCard extends StatelessWidget {
  final Game game;
  const _RoundsBreakdownCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showTotals =
        game.isFinished || game.displayMode == ScoreDisplayMode.afterEachRound;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết từng ván',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Header row
            Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text('Ván',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: cs.outline, fontWeight: FontWeight.bold)),
                ),
                ...game.players.map((p) => Expanded(
                      child: Text(p.name,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: cs.outline,
                                  fontWeight: FontWeight.bold)),
                    )),
              ],
            ),
            const Divider(height: 16),

            // Round rows
            ...List.generate(game.rounds.length, (i) {
              final round = game.rounds[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text('${i + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: cs.outline)),
                        ),
                        ...game.players.map((p) {
                          final score = round.scores[p.id] ?? 0;
                          return Expanded(
                            child: Text(
                              score >= 0 ? '+$score' : '$score',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scoreColor(score, cs),
                                  ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  if (i < game.rounds.length - 1)
                    Divider(height: 1, indent: 36, color: cs.outlineVariant),
                ],
              );
            }),

            // Totals row
            if (showTotals) ...[
              const Divider(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text('∑',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: cs.outline,
                                fontWeight: FontWeight.bold)),
                  ),
                  ...game.players.map((p) {
                    final total = game.totalScore(p.id);
                    return Expanded(
                      child: Text(
                        '$total',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scoreColor(total, cs),
                            ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.amber, Colors.grey, Colors.brown];
    final color = rank <= 3 ? colors[rank - 1] : Colors.transparent;
    final icons = ['🥇', '🥈', '🥉'];

    return SizedBox(
      width: 28,
      child: rank <= 3
          ? Text(icons[rank - 1], style: const TextStyle(fontSize: 20))
          : Text('$rank',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isFinished;
  const _StatusBadge({required this.isFinished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFinished
            ? Colors.green.withOpacity(0.12)
            : Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFinished ? Icons.flag_rounded : Icons.play_circle_rounded,
            size: 14,
            color: isFinished ? Colors.green.shade700 : Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isFinished ? 'Đã kết thúc' : 'Đang chơi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isFinished ? Colors.green.shade700 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.outline),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outlineVariant)),
        ],
      ),
    );
  }
}
