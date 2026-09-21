# jaspr-flutter

The same server-rendered Jaspr site as [`../jaspr-ssr`](../jaspr-ssr), plus
one **Flutter widget embedded into the page** via `jaspr_flutter_embed`.

See [`../jaspr`](../jaspr) for how this sample relates to the others,
and for the rendering terms used below.

```
jaspr create --mode server --routing multi-page --flutter embedded --backend none .
```

## Setup

Dependencies pull in the Flutter SDK, so resolve with `flutter`, not `dart`:

```
dart pub global activate jaspr_cli
export PATH="$HOME/.pub-cache/bin:$PATH"
flutter pub get
```

## Running

```
make serve    # jaspr serve
make build    # jaspr build
make run      # build, then run the compiled server binary
```

## What this sample demonstrates

The page is still HTML. Flutter is **one element inside it**, not the page
itself.

| Path | Role |
|---|---|
| `lib/components/counter.dart` | Plain Jaspr counter — real DOM, server-rendered |
| `lib/components/embedded_counter.dart` | The bridge: `FlutterEmbedView.deferred` |
| `lib/widgets/counter.dart` | An ordinary Flutter widget (`MaterialApp`, `IconButton`) |
| `web/flutter_bootstrap.js` | `{{flutter_js}}` / `{{flutter_build_config}}` placeholders, filled at build time |

### Both counters share one piece of state

`lib/components/counter.dart` renders the HTML counter and then:

```dart
EmbeddedCounter(
  count: count,
  onChange: (value) {
    setState(() => count = value);
  },
),
```

An `int` and a `void Function(int)` cross from the HTML side into the Flutter
widget as ordinary typed Dart values. Nothing is serialised and there is no
second type definition to keep in sync.

### Flutter is excluded from server rendering, by construction

```dart
// The flutter widget is only imported on the web (as the server cannot import flutter)
// and is imported as a deferred library, to not block hydration of the remaining website.
@Import.onWeb('../widgets/counter.dart', show: [#CounterWidget])
import 'embedded_counter.imports.dart' deferred as counter;
```

`@Import.onWeb` keeps Flutter out of the server build; `deferred` keeps the
engine out of the initial page load.

### Verifying both halves

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

The page text is server-rendered exactly as in `jaspr-ssr` — embedding
Flutter costs nothing in crawlability. And the initial HTML references only two
scripts:

```
<script src="flutter_bootstrap.js" async>
<script src="main.client.dart.js" defer>
```

The Flutter engine itself is not in that list. It is fetched later, when the
embedded view loads.

## Cost to be aware of

`jaspr build` writes ~37 MB under `build/jaspr/web/canvaskit/`, but that is the
whole set of renderer variants plus their symbol files, not one page load:

| File | Size | Loaded? |
|---|---|---|
| `canvaskit.wasm` | 6.9 MB | Yes, for the CanvasKit renderer |
| `skwasm.wasm` / `skwasm_heavy.wasm` / `wimp.wasm` | 3.4–4.9 MB | Only for the renderer actually selected |
| `*.js.symbols` | 1.3–1.7 MB each | No — debug symbols |

Still, a Flutter view costs several MB over the wire. That is the argument for
`FlutterEmbedView.deferred()` and for keeping public pages free of it.

## Notes

- The package is named `jaspr_flutter_example`; the directory name would
  otherwise be inferred as the package name.
- `build_web_compilers` is pinned to `^4.8.0` for the Dart SDK in
  `.tool-versions`, same as in `jaspr-ssr`.
