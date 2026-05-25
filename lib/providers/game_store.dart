import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class GameStore extends ChangeNotifier {
  static const _key = 'scorekeeper_games';

  List<Game> _games = [];
  List<Game> get games => _games;

  List<Game> get activeGames => _games.where((g) => !g.isFinished).toList();
  List<Game> get finishedGames => _games.where((g) => g.isFinished).toList();

  Game? gameById(String id) {
    try {
      return _games.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Persistence ────────────────────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _games = Game.decodeList(raw);
        notifyListeners();
      } catch (_) {
        _games = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Game.encodeList(_games));
  }

  // ─── Game CRUD ───────────────────────────────────────────────────────────────

  Future<Game> createGame({
    required String name,
    required List<String> playerNames,
    required ScoreDisplayMode displayMode,
  }) async {
    final players = playerNames.map((n) => Player(name: n)).toList();
    final game = Game(name: name, players: players, displayMode: displayMode);
    _games.insert(0, game);
    await _save();
    notifyListeners();
    return game;
  }

  Future<void> deleteGame(String gameID) async {
    _games.removeWhere((g) => g.id == gameID);
    await _save();
    notifyListeners();
  }

  Future<void> finishGame(String gameID) async {
    final idx = _games.indexWhere((g) => g.id == gameID);
    if (idx == -1) return;
    _games[idx] = _games[idx].copyWith(
      isFinished: true,
      finishedAt: DateTime.now(),
    );
    await _save();
    notifyListeners();
  }

  // ─── Round CRUD ──────────────────────────────────────────────────────────────

  Future<void> addRound(String gameID, Map<String, int> scores) async {
    final idx = _games.indexWhere((g) => g.id == gameID);
    if (idx == -1) return;
    final round = Round(scores: scores);
    final updatedRounds = List<Round>.from(_games[idx].rounds)..add(round);
    _games[idx] = _games[idx].copyWith(rounds: updatedRounds);
    await _save();
    notifyListeners();
  }

  Future<void> updateRound(
      String gameID, String roundID, Map<String, int> scores) async {
    final gIdx = _games.indexWhere((g) => g.id == gameID);
    if (gIdx == -1) return;
    final rounds = List<Round>.from(_games[gIdx].rounds);
    final rIdx = rounds.indexWhere((r) => r.id == roundID);
    if (rIdx == -1) return;
    rounds[rIdx] = rounds[rIdx].copyWith(scores: scores);
    _games[gIdx] = _games[gIdx].copyWith(rounds: rounds);
    await _save();
    notifyListeners();
  }

  Future<void> deleteRound(String gameID, String roundID) async {
    final gIdx = _games.indexWhere((g) => g.id == gameID);
    if (gIdx == -1) return;
    final rounds = List<Round>.from(_games[gIdx].rounds)
      ..removeWhere((r) => r.id == roundID);
    _games[gIdx] = _games[gIdx].copyWith(rounds: rounds);
    await _save();
    notifyListeners();
  }
}
