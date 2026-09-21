import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';
import '../data/session_repository.dart';

/// Shows what `mode: server` actually buys you, which the default scaffold does
/// not demonstrate at all — that project is byte-identical to a `mode: static`
/// one.
///
/// Three things happen here that a statically pre-rendered site cannot do:
///
/// 1. [preloadState] awaits a data source **per request**, on the server.
/// 2. Its result is rendered into the HTML, so a crawler reads the real list.
/// 3. [getState] / [updateState] carry that same data to the client, so
///    hydration does not re-fetch it. The filter below works on the first
///    paint, with no network round trip.
@client
class Sessions extends StatefulComponent {
  const Sessions({super.key});

  @override
  State<Sessions> createState() => SessionsState();
}

class SessionsState extends State<Sessions>
    with PreloadStateMixin<Sessions>, SyncStateMixin<Sessions, Map<String, dynamic>> {
  List<Session> sessions = const [];
  String renderedAt = '';
  bool onlyAvailable = false;

  /// Runs on the server, before the first build. Never runs on the client.
  @override
  Future<void> preloadState() async {
    sessions = await fetchSessions();
    renderedAt = DateTime.now().toUtc().toIso8601String();
  }

  /// Server: what to embed in the HTML for the client to pick up.
  @override
  Map<String, dynamic> getState() => {
    'sessions': [for (final s in sessions) s.toJson()],
    'renderedAt': renderedAt,
  };

  /// Client: called during initState with whatever the server embedded.
  @override
  void updateState(Map<String, dynamic> value) {
    sessions = [
      for (final json in value['sessions'] as List<dynamic>) Session.fromJson(json as Map<String, dynamic>),
    ];
    renderedAt = value['renderedAt'] as String;
  }

  @override
  Component build(BuildContext context) {
    final visible = onlyAvailable ? [for (final s in sessions) if (s.seatsLeft > 0) s] : sessions;

    return section([
      h1([.text('Sessions')]),
      p(classes: 'rendered-at', [
        .text('Rendered on the server at $renderedAt — reload and it changes.'),
      ]),
      button(
        classes: 'filter',
        onClick: () {
          setState(() => onlyAvailable = !onlyAvailable);
        },
        [.text(onlyAvailable ? 'Show all' : 'Only with seats left')],
      ),
      ul(classes: 'sessions', [
        for (final s in visible)
          li(classes: s.seatsLeft > 0 ? 'available' : 'sold-out', [
            span(classes: 'performer', [.text(s.performer)]),
            span(classes: 'starts-at', [.text(s.startsAt)]),
            span(classes: 'seats', [
              .text(s.seatsLeft > 0 ? '${s.seatsLeft} seats left' : 'sold out'),
            ]),
          ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.rendered-at').styles(color: const Color('#666'), fontSize: 0.9.rem),
    css('.filter').styles(
      padding: .symmetric(vertical: 0.5.rem, horizontal: 1.rem),
      border: .unset,
      radius: .all(.circular(6.px)),
      cursor: .pointer,
      color: Colors.white,
      backgroundColor: primaryColor,
    ),
    css('ul.sessions', [
      css('&').styles(width: 24.rem, maxWidth: 90.percent, padding: .zero, listStyle: .none),
      css('li', [
        css('&').styles(
          display: .flex,
          padding: .symmetric(vertical: 0.75.rem),
          border: .only(bottom: .solid(color: const Color('#eee'), width: 1.px)),
          justifyContent: .spaceBetween,
        ),
        css('&.sold-out').styles(color: const Color('#999')),
        css('.performer').styles(fontWeight: .bold),
      ]),
    ]),
  ];
}
