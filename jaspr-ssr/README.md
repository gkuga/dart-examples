# jaspr-ssr

[Jaspr](https://jaspr.site/) is a Dart web framework that renders real HTML/CSS
and the DOM, not a canvas. Unlike Flutter Web it produces a semantic document,
so a page is readable without running any JavaScript.

See [`../jaspr`](../jaspr) for how this sample relates to the others,
and for the rendering terms used below.

This sample is scaffolded in **server rendering mode** with multi-page routing:

```
jaspr create --mode server --routing multi-page --flutter none --backend none .
```

See [`../jaspr-flutter`](../jaspr-flutter) for the same site with a Flutter
widget embedded into the page.

## Setup

The Jaspr CLI is a globally activated Dart package:

```
dart pub global activate jaspr_cli
export PATH="$HOME/.pub-cache/bin:$PATH"
dart pub get
```

## Running

```
make serve    # jaspr serve — dev server with hot reload on http://localhost:8080
make build    # jaspr build — outputs to build/jaspr/
make run      # build, then run the compiled server binary
```

`jaspr build` produces a self-contained AOT executable (`build/jaspr/app`) plus
the client assets, so the server side is a native binary with no Dart runtime to
install.

## What `mode: server` actually buys you

Worth knowing: **the default scaffold does not use server mode at all.** Generate
the same project with `--mode static` and the Dart code is byte-identical — the
only difference is one line in `pubspec.yaml`. The `/sessions` page was added
here to show what a server is actually for.

`lib/pages/sessions.dart` does three things a pre-rendered site cannot:

| | How |
|---|---|
| Fetch data per request, on the server | `PreloadStateMixin.preloadState()` — runs before the first build, never on the client |
| Put the result in the HTML | Normal rendering. A crawler reads the real list, not an empty shell |
| Hand that data to the client | `SyncStateMixin.getState()` / `updateState()` — hydration does not re-fetch |

### Verifying all three

```
make run
curl -s http://localhost:8080/sessions | sed -n '/<body/,$p' | sed 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -v '^\s*$'
```

```
 Home About Sessions
 Sessions
 Rendered on the server at 2026-09-21T03:35:19.179030Z — reload and it changes.
 Only with seats left
 Aoi 19:00 2 seats left
 Mei 20:00 sold out
 Rin 21:00 5 seats left
 Yuki 22:00 sold out
```

The list is in the response body with no JavaScript executed. Request it twice
and the timestamp differs — that is the per-request render a static build cannot
produce.

The state handed to the client is embedded as an HTML comment:

```
curl -s http://localhost:8080/sessions | grep -o '<!--[$][^-]\{0,120\}'
```

```
<!--${"sessions":[{"performer":"Aoi","startsAt":"19:00","seatsLeft":2},...
```

`updateState()` reads that on the client, so the filter button works on first
paint without a network round trip.

### Where a real data source would go

`lib/data/session_repository.dart` is imported by a `@client` component, so it
must *compile* for both environments — but `fetchSessions()` is only ever
*called* from `preloadState()`. A source needing `dart:io` or a database driver
would be pulled in with `@Import.onServer(...)`, the same mechanism
[`../jaspr-flutter`](../jaspr-flutter) uses to keep Flutter out of the server
build.

## What to look at

| Path | What it shows |
|---|---|
| `lib/main.server.dart` | Server entry point. Runs on the Dart VM — no JavaScript involved |
| `lib/main.client.dart` | Client entry point, compiled by `dart compile js` |
| `lib/app.dart` | Routes, declared with `jaspr_router` |
| `lib/components/counter.dart` | A `@client` component — interactive, hydrated in the browser |
| `lib/components/header.dart` | A server-rendered component. Never ships to the client |
| `lib/constants/theme.dart` | Styles written in Dart, emitted as real CSS |
| `lib/pages/sessions.dart` | Server-side data loading and state sync (see above) |
| `lib/data/session_repository.dart` | Stands in for a database or upstream API |

The split between the last two rows is the point of the framework: a component
is server-only until it is marked `@client`, so only interactive parts cost
JavaScript.

## Verifying that it really is server-rendered

```
make run
curl -s http://localhost:8080/ | sed -n '/<body/,$p' | sed 's/<[^>]*>/ /g' | tr -s ' \n' ' \n' | grep -v '^\s*$'
```

```
 Home About
 Welcome
 You successfully create a new Jaspr site.
 - 0 +
```

The page text ("Welcome", the counter value) appears in the response body, with
no JavaScript executed. That is what Flutter Web cannot do — its canvas renderer
leaves no semantic DOM for a crawler to read.

## Notes

- The package is named `jaspr_example`, not `jaspr`, because a package may not
  list itself as a dependency.
- `build_web_compilers` is pinned to `^4.8.0`; `4.8.10` requires a newer Dart SDK
  than the one pinned in `.tool-versions`.
