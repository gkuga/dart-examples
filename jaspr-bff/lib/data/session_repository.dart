/// Stands in for a database or an upstream API.
///
/// This file is imported by a `@client` component, so it has to *compile* for
/// both environments — but [fetchSessions] is only ever *called* from
/// `preloadState()`, which Jaspr runs on the server alone.
///
/// If a real data source needed `dart:io` or a database driver, it would be
/// pulled in with `@Import.onServer(...)` instead, the same mechanism
/// `jaspr-flutter` uses to keep Flutter out of the server build.
library;

class Session {
  const Session({required this.performer, required this.startsAt, required this.seatsLeft});

  final String performer;
  final String startsAt;
  final int seatsLeft;

  Map<String, dynamic> toJson() => {'performer': performer, 'startsAt': startsAt, 'seatsLeft': seatsLeft};

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    performer: json['performer'] as String,
    startsAt: json['startsAt'] as String,
    seatsLeft: json['seatsLeft'] as int,
  );
}

Future<List<Session>> fetchSessions() async {
  // A real query would take about this long.
  await Future<void>.delayed(const Duration(milliseconds: 150));
  return const [
    Session(performer: 'Aoi', startsAt: '19:00', seatsLeft: 2),
    Session(performer: 'Mei', startsAt: '20:00', seatsLeft: 0),
    Session(performer: 'Rin', startsAt: '21:00', seatsLeft: 5),
    Session(performer: 'Yuki', startsAt: '22:00', seatsLeft: 0),
  ];
}
