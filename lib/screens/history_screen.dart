import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_store.dart';
import '../models/game_model.dart';
import '../utils/helpers.dart';
import 'game_detail_screen.dart';
import 'game_play_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Game> _filter(List<Game> games) {
    if (_search.isEmpty) return games;
    final q = _search.toLowerCase();
    return games.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.players.any((p) => p.name.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: 'Tất cả (${store.games.length})'),
            Tab(text: 'Đang chơi (${store.activeGames.length})'),
            Tab(text: 'Xong (${store.finishedGames.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              hintText: 'Tìm theo tên game hoặc người chơi...',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _search = v),
              padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _GameList(games: _filter(store.games)),
                _GameList(games: _filter(store.activeGames)),
                _GameList(games: _filter(store.finishedGames)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Game List ────────────────────────────────────────────────────────────────

class _GameList extends StatelessWidget {
  final List<Game> games;
  const _GameList({required this.games});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text('Không có kết quả',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: cs.outline)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _HistoryGameCard(game: games[i]),
    );
  }
}

// ─── History Game Card ────────────────────────────────────────────────────────

class _HistoryGameCard extends StatelessWidget {
  final Game game;
  const _HistoryGameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showScores =
        game.displayMode == ScoreDisplayMode.afterEachRound || game.isFinished;

    return Dismissible(
      key: Key(game.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa game?'),
            content: Text('Xóa "${game.name}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<GameStore>().deleteGame(game.id);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GamePlayScreen(gameID: game.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status
                Row(
                  children: [
                    Expanded(
                      child: Text(game.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    _StatusChip(isFinished: game.isFinished),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${shortDate(game.createdAt)} • ${game.rounds.length} ván',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.outline),
                ),
                const SizedBox(height: 10),

                // Mini scoreboard
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: game.players.map((p) {
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
                              showScores ? '$score' : '?',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: showScores
                                        ? scoreColor(score, cs)
                                        : cs.outline,
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
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isFinished;
  const _StatusChip({required this.isFinished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFinished
            ? Colors.green.withOpacity(0.12)
            : Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFinished ? 'Xong' : 'Đang chơi',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isFinished ? Colors.green.shade700 : Colors.blue.shade700,
        ),
      ),
    );
  }
}
