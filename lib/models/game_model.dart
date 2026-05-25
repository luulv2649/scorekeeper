import 'dart:convert';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ScoreDisplayMode {
  afterEachRound('Sau mỗi ván'),
  afterAllRounds('Sau khi kết thúc');

  const ScoreDisplayMode(this.label);
  final String label;
}

// ─── Player ───────────────────────────────────────────────────────────────────

class Player {
  final String id;
  String name;

  Player({String? id, required this.name}) : id = id ?? _uuid.v4();

  Player copyWith({String? name}) => Player(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Player.fromJson(Map<String, dynamic> json) =>
      Player(id: json['id'], name: json['name']);
}

// ─── Round ────────────────────────────────────────────────────────────────────

class Round {
  final String id;
  final Map<String, int> scores; // playerID -> score
  final DateTime createdAt;

  Round({
    String? id,
    required this.scores,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  int get total => scores.values.fold(0, (a, b) => a + b);

  Round copyWith({Map<String, int>? scores}) =>
      Round(id: id, scores: scores ?? Map.from(this.scores), createdAt: createdAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'scores': scores.map((k, v) => MapEntry(k, v)),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        id: json['id'],
        scores: Map<String, int>.from(
            (json['scores'] as Map).map((k, v) => MapEntry(k as String, v as int))),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// ─── Game ─────────────────────────────────────────────────────────────────────

class Game {
  final String id;
  String name;
  final List<Player> players;
  final List<Round> rounds;
  final ScoreDisplayMode displayMode;
  final DateTime createdAt;
  bool isFinished;
  DateTime? finishedAt;

  Game({
    String? id,
    required this.name,
    required this.players,
    List<Round>? rounds,
    this.displayMode = ScoreDisplayMode.afterEachRound,
    DateTime? createdAt,
    this.isFinished = false,
    this.finishedAt,
  })  : id = id ?? _uuid.v4(),
        rounds = rounds ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Tổng điểm tích lũy của một người chơi
  int totalScore(String playerID) =>
      rounds.fold(0, (sum, r) => sum + (r.scores[playerID] ?? 0));

  /// Xếp hạng: trả về list sorted theo tổng điểm tăng dần
  List<({Player player, int total})> rankings() {
    final list = players
        .map((p) => (player: p, total: totalScore(p.id)))
        .toList();
    list.sort((a, b) => a.total.compareTo(b.total));
    return list;
  }

  Game copyWith({
    String? name,
    List<Round>? rounds,
    bool? isFinished,
    DateTime? finishedAt,
  }) =>
      Game(
        id: id,
        name: name ?? this.name,
        players: players,
        rounds: rounds ?? List.from(this.rounds),
        displayMode: displayMode,
        createdAt: createdAt,
        isFinished: isFinished ?? this.isFinished,
        finishedAt: finishedAt ?? this.finishedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'players': players.map((p) => p.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'displayMode': displayMode.name,
        'createdAt': createdAt.toIso8601String(),
        'isFinished': isFinished,
        'finishedAt': finishedAt?.toIso8601String(),
      };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id'],
        name: json['name'],
        players: (json['players'] as List).map((e) => Player.fromJson(e)).toList(),
        rounds: (json['rounds'] as List).map((e) => Round.fromJson(e)).toList(),
        displayMode: ScoreDisplayMode.values.firstWhere(
          (m) => m.name == json['displayMode'],
          orElse: () => ScoreDisplayMode.afterEachRound,
        ),
        createdAt: DateTime.parse(json['createdAt']),
        isFinished: json['isFinished'] ?? false,
        finishedAt: json['finishedAt'] != null
            ? DateTime.parse(json['finishedAt'])
            : null,
      );

  static String encodeList(List<Game> games) =>
      jsonEncode(games.map((g) => g.toJson()).toList());

  static List<Game> decodeList(String source) =>
      (jsonDecode(source) as List).map((e) => Game.fromJson(e)).toList();
}
