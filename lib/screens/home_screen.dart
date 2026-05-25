import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_store.dart';
import '../models/game_model.dart';
import '../utils/helpers.dart';
import 'new_game_screen.dart';
import 'game_play_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();
    final active = store.activeGames;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────────
          SliverAppBar.large(
            title: const Text('Cần Câu Cơm'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Lịch sử',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ],
          ),

          // ── Hero banner ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.style_rounded,
                          size: 48, color: cs.onPrimaryContainer),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ghi điểm bài',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('4 người chơi • Tổng điểm = 0',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: cs.onPrimaryContainer
                                            .withOpacity(0.8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Active games header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    active.isEmpty ? 'Chưa có ván nào' : 'Đang chơi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (active.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Badge(label: Text('${active.length}')),
                  ]
                ],
              ),
            ),
          ),

          // ── Active games list ────────────────────────────────────────────────
          if (active.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_card_rounded,
                        size: 72, color: cs.outlineVariant),
                    const SizedBox(height: 12),
                    Text('Nhấn nút + để tạo ván mới',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: cs.outline)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: active.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _ActiveGameCard(game: active[i]),
              ),
            ),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewGameScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tạo ván mới'),
      ),
    );
  }
}

// ─── Active Game Card ─────────────────────────────────────────────────────────

class _ActiveGameCard extends StatelessWidget {
  final Game game;
  const _ActiveGameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GamePlayScreen(gameID: game.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(game.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Text('${game.rounds.length} ván',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.outline)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: cs.outline, size: 18),
                ],
              ),
              const SizedBox(height: 12),

              // Mini scoreboard
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: game.players.map((p) {
                    final idx = game.players.indexOf(p);
                    final score = game.totalScore(p.id);
                    return Expanded(
                      child: Column(
                        children: [
                          Text(p.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: cs.outline),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            '$score',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor(score, cs),
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
