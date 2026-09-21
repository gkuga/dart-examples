# Jaspr samples

[Jaspr](https://jaspr.site/) is a Dart web framework that renders real HTML, the
DOM and CSS — not a canvas. Unlike Flutter Web it produces a semantic document,
so a page is readable without running any JavaScript.

This directory is an index. Each sample below is a separate project, and each
isolates one decision.

| Sample | `jaspr create` flags | What it isolates |
|---|---|---|
| [`../jaspr-ssr`](../jaspr-ssr) | `--mode server --routing multi-page --flutter none --backend none` | Rendering HTML per request, and handing that data to the client |
| [`../jaspr-bff`](../jaspr-bff) | …`--backend shelf` | Adding an HTTP endpoint the browser calls |
| [`../jaspr-flutter`](../jaspr-flutter) | …`--flutter embedded` | Embedding a Flutter widget into an HTML page |

Run any of them with `make serve`, or `make run` for a compiled binary.

---

## Rendering terms, which are easy to blur

The axis is **when the HTML is produced, and where**. That is the whole
distinction.

| Term | HTML produced | Where | Jaspr | Next.js |
|---|---|---|---|---|
| **CSR** — client-side rendering | After the browser runs JS | Browser | `mode: client` | A client-only SPA |
| **SSG** — static site generation | **Once, at build time** | Build machine | `mode: static` | Static rendering (`generateStaticParams`, `getStaticProps`) |
| **SSR** — server-side rendering | **Per request** | A running server | `mode: server` | Dynamic rendering (`getServerSideProps`, dynamic segments) |
| **ISR** — incremental static regeneration | At build, then regenerated after deploy | Both | Not available | `revalidate` |

Jaspr's own CLI is precise about this: `static` is described as "statically
**pre-rendered**", `server` as "**server**-rendered".

**Pre-rendering** is the umbrella over SSG and SSR — "HTML exists before the
browser runs any JavaScript". A crawler cannot tell the two apart, which is why
SEO discussions blur them. If you only need to be crawlable, **SSG is enough**.
You need SSR when the page depends on something only known per request.

Related terms that sit on different axes:

| Term | Meaning | In these samples |
|---|---|---|
| **Hydration** | Attaching client-side state and event handlers to server-produced HTML | What `@client` components do |
| **Islands architecture** | Mostly static HTML with interactive islands | `@client` is effectively this; Astro popularised it |
| **State serialization** | Embedding server-computed state in the HTML for the client to pick up | `SyncStateMixin`, in `jaspr-ssr` |
| **Streaming SSR** | Sending the server-rendered HTML in chunks | Not in these samples |
| **Resumability** | No hydration at all — serialize and continue | Qwik. Not available in Jaspr |

---

## SSR and BFF are different things

They are often conflated because both run on a server and both talk to
backends. They differ in what they produce.

| | SSR | BFF — backend for frontend |
|---|---|---|
| Produces | **HTML** | **An API response** |
| Consumed by | The browser's initial page load, and crawlers | JavaScript running in the browser |
| When it runs | While rendering the page | After the page has loaded, on user action |
| In Jaspr | `preloadState()` in `mode: server` | `router.get('/api/...')`, needs `--backend shelf` |
| In Next.js | Server Components, `getServerSideProps` | Route Handlers (`app/**/route.ts`), API Routes (`pages/api/*`) |

An SSR server *behaves* like a BFF while rendering — it calls backends and
shapes the result for one specific frontend. But it exposes no endpoint. That
is the whole difference, and it is why the two samples are separate projects.

**Useful rule:** the initial render never needs a BFF, because SSR can read the
data source directly and put the result in the HTML. A BFF is for what the
browser asks for *after* that — a refresh, a mutation, a search, pagination.

### The two frameworks differ in what is the default

| | Jaspr | Next.js |
|---|---|---|
| API endpoints exist by default | **No.** `runApp(Component app)` takes a component and nothing else — there is nowhere to put a handler | **Yes.** `app/**/route.ts` works in any project |
| To add them | Regenerate with `--backend shelf`, which swaps `runApp` for `serveApp` + a shelf router | Add a file |
| To avoid them | Nothing to do | A team decision, enforced by review |

So "we do not want a BFF" is a structural property in Jaspr and a matter of
discipline in Next.js. Next.js also offers **Server Actions** (`'use server'`),
which are mutations callable from your own components without declaring an
endpoint — neither an API route nor plain SSR. Jaspr has no equivalent.

---

## Where Flutter fits

Flutter is a UI toolkit targeting iOS, Android, web and desktop from one
codebase. On the web it does not emit HTML elements — it **paints to a
`<canvas>`**, so a button exists as pixels rather than as a `<button>`. A
crawler reads nothing. The Flutter team's own framing: *Flutter Web is for
building web apps, not websites.*

[`../jaspr-flutter`](../jaspr-flutter) shows the combination that avoids the
trade-off: the page stays HTML and Flutter is **one element inside it**. The
initial HTML is unchanged and the engine loads later, on demand.

| | Flutter Web alone | Flutter embedded in Jaspr |
|---|---|---|
| Public pages | No semantic DOM — invisible to crawlers | Plain HTML, server-rendered |
| App-like screens | Full Flutter | Full Flutter, inside a `FlutterEmbedView` |
| Shared with a mobile app | Everything, including UI | Models and logic; UI only inside the embedded view |
| Engine download | On first page load | Deferred until the embedded view is shown |

Note that **Jaspr does not share UI code with Flutter**. Jaspr components build
HTML (`div`, `span`) with CSS; Flutter widgets (`Column`, `Row`) have no
equivalent. What transfers is non-UI Dart — models, logic, packages — and whole
Flutter apps, via embedding.

---

## Dart on the web is not always JavaScript

Two compilers, and the choice is real:

| | Output | Requirement |
|---|---|---|
| `dart2js` | JavaScript | Runs anywhere |
| `dart2wasm` | WebAssembly (WasmGC) | Chrome 119+, Firefox 120+, Safari 18+ |

WasmGC is required because Dart is garbage-collected and hands that job to the
browser, unlike C or Rust targeting linear memory. `jaspr build` takes
`--experimental-wasm`; the samples here are built with `dart2js`.

Dart → JS is a full compilation, not a transpile: it reproduces Dart's execution
model in JavaScript, with its own runtime and whole-program tree shaking. There
is **no JSX equivalent**, and there will not be one — JSX needs a syntax
transform, and the Dart team ended work on macros in January 2025. Structure is
expressed with nested calls instead:

```dart
div(classes: 'counter', [
  button(onClick: () => setState(() => count--), [.text('-')]),
  span([.text('$count')]),
])
```

Collection-`for` and collection-`if` cover what `{items.map(...)}` and
`{cond && ...}` do in JSX.
