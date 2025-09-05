import 'package:hive/hive.dart';
import 'study_result.dart';

part 'study_session.g.dart';

@HiveType(typeId: 4)
class StudySession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String deckId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int totalCards;

  @HiveField(4)
  int correctAnswers;

  @HiveField(5)
  int incorrectAnswers;

  @HiveField(6)
  double averageScore;

  @HiveField(7)
  int studyTimeSeconds;

  @HiveField(8)
  bool usedTimer;

  StudySession({
    required this.id,
    required this.deckId,
    required this.date,
    required this.totalCards,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.averageScore,
    required this.studyTimeSeconds,
    required this.usedTimer,
  });

  StudySession.create({
    required this.deckId,
    required this.totalCards,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.studyTimeSeconds,
    required this.usedTimer,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       date = DateTime.now(),
       averageScore = totalCards > 0 ? (correctAnswers / totalCards) * 100 : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deckId': deckId,
      'date': date.toIso8601String(),
      'totalCards': totalCards,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'averageScore': averageScore,
      'studyTimeSeconds': studyTimeSeconds,
      'usedTimer': usedTimer,
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'],
      deckId: json['deckId'],
      date: DateTime.parse(json['date']),
      totalCards: json['totalCards'],
      correctAnswers: json['correctAnswers'],
      incorrectAnswers: json['incorrectAnswers'],
      averageScore: json['averageScore'].toDouble(),
      studyTimeSeconds: json['studyTimeSeconds'],
      usedTimer: json['usedTimer'],
    );
  }
}
