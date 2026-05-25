import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_store.dart';
import '../models/game_model.dart';
import '../utils/helpers.dart';
import 'add_round_screen.dart';

class GamePlayScreen extends StatelessWidget {
  final String gameID;
  const GamePlayScreen({super.key, required this.gameID});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStore>().gameById(gameID);
    if (game == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy game')),
      );
    }
    return _GamePlayContent(game: game);
  }
}

class _GamePlayContent extends StatelessWidget {
  final Game game;
  const _GamePlayContent({required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _handleMenu(context, v),
            itemBuilder: (_) => [
              if (!game.isFinished)
                const PopupMenuItem(
                  value: 'finish',
                  child: ListTile(
                    leading: Icon(Icons.flag_rounded),
                    title: Text('Kết thúc game'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_rounded, color: Colors.red),
                  title: Text('Xóa game', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Score header ─────────────────────────────────────────────────
          _ScoreHeader(game: game),

          // ── Rounds list ──────────────────────────────────────────────────
          Expanded(
            child: game.rounds.isEmpty
                ? _EmptyRounds(isFinished: game.isFinished)
                : _RoundsList(game: game),
          ),

          // ── Bottom bar ───────────────────────────────────────────────────
          if (!game.isFinished) _BottomBar(game: game),
          if (game.isFinished) _FinishedBanner(game: game),
        ],
      ),
    );
  }

  void _handleMenu(BuildContext context, String value) {
    final store = context.read<GameStore>();
    if (value == 'finish') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Kết thúc game?'),
          content: const Text(
              'Game sẽ được đánh dấu hoàn thành và chuyển vào lịch sử.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                store.finishGame(game.id);
                Navigator.pop(context);
              },
              child: const Text('Kết thúc'),
            ),
          ],
        ),
      );
    } else if (value == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Xóa game?'),
          content: const Text('Toàn bộ dữ liệu game sẽ bị xóa vĩnh viễn.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                store.deleteGame(game.id);
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to home
              },
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
    }
  }
}

// ─── Score Header ─────────────────────────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  final Game game;
  const _ScoreHeader({required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showScores =
        game.displayMode == ScoreDisplayMode.afterEachRound || game.isFinished;

    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: List.generate(game.players.length, (i) {
              final player = game.players[i];
              final total = game.totalScore(player.id);
              final color = playerColor(i);
              return Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(initials(player.name),
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(player.name,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cs.outline),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        showScores ? '$total' : '?',
                        key: ValueKey(showScores ? total : '?'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: showScores
                                  ? scoreColor(total, cs)
                                  : cs.outline,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Mode + round count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                game.displayMode == ScoreDisplayMode.afterEachRound
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 14,
                color: cs.outline,
              ),
              const SizedBox(width: 4),
              Text(
                '${game.displayMode.label} • ${game.rounds.length} ván',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Rounds List ──────────────────────────────────────────────────────────────

class _RoundsList extends StatelessWidget {
  final Game game;
  const _RoundsList({required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rounds = game.rounds.reversed.toList();

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rounds.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (ctx, i) {
        final round = rounds[i];
        final roundNumber = game.rounds.length - i;
        return _RoundRow(
          roundNumber: roundNumber,
          round: round,
          players: game.players,
          isFinished: game.isFinished,
          onEdit: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => AddRoundScreen(
                gameID: game.id,
                players: game.players,
                editingRound: round,
              ),
            ),
          ),
          onDelete: () => _confirmDelete(ctx, game.id, round.id),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String gameID, String roundID) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa ván này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<GameStore>().deleteRound(gameID, roundID);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ─── Round Row ────────────────────────────────────────────────────────────────

class _RoundRow extends StatelessWidget {
  final int roundNumber;
  final Round round;
  final List<Player> players;
  final bool isFinished;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoundRow({
    required this.roundNumber,
    required this.round,
    required this.players,
    required this.isFinished,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Round number
          SizedBox(
            width: 36,
            child: Text(
              'V$roundNumber',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
          ),

          // Scores
          ...players.map((p) {
            final score = round.scores[p.id] ?? 0;
            return Expanded(
              child: Text(
                score >= 0 ? '+$score' : '$score',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scoreColor(score, cs),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            );
          }),

          // Actions
          if (!isFinished)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              icon: Icon(Icons.more_vert, size: 18, color: cs.outline),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_rounded),
                        title: Text('Sửa'),
                        contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_rounded, color: Colors.red),
                        title: Text('Xóa',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero)),
              ],
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ─── Empty Rounds ─────────────────────────────────────────────────────────────

class _EmptyRounds extends StatelessWidget {
  final bool isFinished;
  const _EmptyRounds({required this.isFinished});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 72, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            isFinished ? 'Game kết thúc không có ván nào' : 'Chưa có ván nào',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: cs.outline),
          ),
          if (!isFinished) ...[
            const SizedBox(height: 6),
            Text(
              'Nhấn "Thêm ván" để bắt đầu',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outlineVariant),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final Game game;
  const _BottomBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddRoundScreen(gameID: game.id, players: game.players),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm ván'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ),
    );
  }
}

// ─── Finished Banner ──────────────────────────────────────────────────────────

class _FinishedBanner extends StatelessWidget {
  final Game game;
  const _FinishedBanner({required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.flag_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Game đã kết thúc',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.outline)),
            const Spacer(),
            if (game.finishedAt != null)
              Text(shortDate(game.finishedAt!),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.outlineVariant)),
          ],
        ),
      ),
    );
  }
}
