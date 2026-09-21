# jaspr-bff

[`../jaspr-ssr`](../jaspr-ssr) plus a **backend-for-frontend**: an HTTP endpoint
the browser calls. It exists to make the boundary between the two concrete —
see [`../jaspr`](../jaspr) for the comparison.

```
jaspr create --mode server --routing multi-page --flutter none --backend shelf .
```

## Setup

```
dart pub global activate jaspr_cli
export PATH="$HOME/.pub-cache/bin:$PATH"
dart pub get
```

## Running

```
make serve    # jaspr serve
make build    # jaspr build
make run      # build, then run the compiled server binary
```

## Why `--backend shelf` is needed at all

Jaspr's plain entry point takes a component and nothing else:

```dart
void runApp(Component app) { ... }
```

There is nowhere to put a handler. `--backend shelf` swaps it for `serveApp()`,
which returns a [shelf](https://pub.dev/packages/shelf) handler you mount
alongside your own routes:

```dart
final router = Router();

// The BFF half: an endpoint the *browser* calls, after the page has loaded.
router.get('/api/sessions', (Request request) async {
  final sessions = await fetchSessions();
  return Response.ok(jsonEncode({...}), headers: {'content-type': 'application/json'});
});

// The SSR half: identical to ../jaspr-ssr, only mounted rather than run.
router.mount('/', serveApp((request, render) => render(Document(body: App()))));
```

So having an API layer is a structural choice in Jaspr, not a default. Next.js
is the opposite: `app/**/route.ts` works in any project, so a team that does not
want a BFF has to decide not to write one.

## What the sample shows

`lib/pages/sessions.dart` is the same page as in `jaspr-ssr`, with one addition:
a **Refresh** button, rendered only when `kIsWeb`, that calls `/api/sessions`.

Note what the endpoint is *not* needed for: the initial render. SSR already put
that data in the HTML. **A BFF earns its place only when the browser has to ask
for something after the page is loaded** — a refresh, a mutation, a search, an
infinite scroll.

## Verifying both halves

```
make run
```

The page is server-rendered exactly as in `jaspr-ssr`:

```
curl -s http://localhost:8080/sessions | sed -n '/<body/,$p' | sed 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -v '^\s*$'
```

```
 Home About Sessions
 Sessions
 Rendered on the server at 2026-09-21T04:02:12.784024Z — reload and it changes.
 Only with seats left
 Aoi 19:00 2 seats left
 ...
```

And the endpoint answers separately:

```
curl -s http://localhost:8080/api/sessions
```

```json
{"sessions":[{"performer":"Aoi","startsAt":"19:00","seatsLeft":2}, ...]}
```

`logRequests()` middleware shows both arriving:

```
2026-09-21T13:02:12.631510  0:00:00.153535 GET     [200] /sessions
2026-09-21T13:02:12.845582  0:00:00.151386 GET     [200] /api/sessions
```

## Changes made to the generated scaffold

- The scaffold hardcodes `shelf_io.serve(handler, InternetAddress.anyIPv4, 8080)`.
  This sample reads `PORT` instead, which is what a container platform such as
  Cloud Run expects.
- `activeServer` / `activeReloadLock` are kept from the scaffold: with a custom
  backend, `main()` runs again on hot reload and closing the previous server
  becomes your responsibility.
