// The entry point of your server app.
//
// Unlike `../jaspr-ssr`, this one is generated with `--backend shelf`. That is
// what makes an API endpoint possible at all: `runApp()` takes a component and
// nothing else, so there is nowhere to put a handler. `serveApp()` returns a
// shelf handler you can mount next to your own routes.
library;

import 'dart:convert';
import 'dart:io';

import 'package:jaspr/dom.dart';
// Server-specific Jaspr import.
import 'package:jaspr/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// Imports the [App] component.
import 'app.dart';
import 'data/session_repository.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'main.server.options.dart';

void main() async {
  Jaspr.initializeApp(options: defaultServerOptions);

  final router = Router();

  // The BFF half: an endpoint the *browser* calls, after the page has loaded.
  // The SSR half below never needs it — it reads the repository directly.
  router.get('/api/sessions', (Request request) async {
    final sessions = await fetchSessions();
    return Response.ok(
      jsonEncode({'sessions': [for (final s in sessions) s.toJson()]}),
      headers: {'content-type': 'application/json'},
    );
  });

  // The SSR half: identical to `../jaspr-ssr`, only mounted rather than run.
  router.mount('/', serveApp((request, render) {
    return render(Document(
      title: 'jaspr-bff',
      styles: [
        css.import('https://fonts.googleapis.com/css?family=Roboto'),
        css('html, body').styles(
          width: 100.percent,
          minHeight: 100.vh,
          padding: .zero,
          margin: .zero,
          fontFamily: const .list([FontFamily('Roboto'), FontFamilies.sansSerif]),
        ),
        css('h1').styles(margin: .unset, fontSize: 4.rem),
      ],
      body: App(),
    ));
  }));

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router);

  // Object to resolve async locking of reloads.
  final reloadLock = activeReloadLock = Object();
  // The generated scaffold hardcodes 8080. Reading PORT is what a container
  // platform such as Cloud Run expects, and `jaspr serve` sets it too.
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port, shared: true);

  // If the reload lock changed, another reload happened and we should abort.
  if (reloadLock != activeReloadLock) {
    server.close();
    return;
  }

  activeServer?.close();
  activeServer = server;

  print('Serving at http://${server.address.host}:${server.port}');
}

/// Keeps track of the currently running http server.
HttpServer? activeServer;

/// Keeps track of the last created reload lock.
Object? activeReloadLock;
