# Rendry UI

Rendry UI is a lightweight server-rendered UI framework for Ruby. It provides a small DSL for composing HTML with Ruby — explicit markup, safe escaping by default, testable components, and optional hypermedia interactivity with zero mandatory JavaScript.

## Usage

```ruby
require_relative "lib/rendry"

html = Rendry.render do
  main(class: "page") do
    h1 { text "Tasks" }
    p "A simple Ruby interface"
    button "Create task", type: "submit"
  end
end

puts html
```

Values passed to `text` and element content are escaped automatically. Use `raw` only for an HTML fragment fully controlled by your application.

A block's return value is appended as content when it is a `String`, `Numeric`, or `Symbol` — so `div { task.title }` works, and strings are escaped unless they are `SafeHTML`.

Helpers from the surrounding view context (e.g. Sinatra's `session`, `params`, or your own methods) are reachable inside DSL blocks and are written as escaped text:

```ruby
get "/" do
  Rendry.render do
    p { flash }          # calls your `flash` helper
    session[:count]      # calls `session`
  end
end
```

`data:` and `aria:` attributes accept nested hashes and are flattened (`data: { toggle: "x" }` → `data-toggle="x"`). URLs with `javascript:`/`vbscript:`/non-image `data:` schemes in `href`, `src`, `action`, `formaction`, or `xlink:href` are rewritten to `#` — disable with `Rendry.sanitize_urls = false`.

## Components

The lightest form is a `template` block — no `render` method needed:

```ruby
class Badge < Rendry::Component
  def initialize(label)
    @label = label
  end

  template do
    span(@label, class: "badge")
  end
end
```

For full control, implement `#render` returning `Rendry.render { ... }` or a `SafeHTML`. Components also receive the view context (`view_context`) when rendered through `component`, so helpers work inside `template` blocks too.

## Features

### Layout

`Rendry::Components::Layout` renders a full HTML document with `title:`, an optional `head:` block, and `view_transitions: true` for native cross-page transitions (pure CSS, no JS).

### Hypermedia (`hx`)

Build htmx attributes inline — Hash/Array values become JSON:

```ruby
button("Delete", **hx(delete: "/tasks/1", target: "closest .task"))
# => hx-delete="/tasks/1" hx-target="closest .task"
```

Also available as `Rendry.hx` outside render blocks.

### Selective fragments

`fragment("name")` is transparent in normal renders. `Rendry.render(fragments: ["name"])` emits only the matching fragments — even nested inside components — for htmx swap endpoints.

### Fragment cache

`cache(*keys) { ... }` memoizes a DSL block in an in-memory FIFO store (`Rendry.cache_store`).

### Refreshing components

Declare polling once on the component class:

```ruby
class Comments < Rendry::Component
  refreshes every: "10s", url: "/comments", target: "#comments"
end
```

`component Comments.new(list)` is then wrapped in a `display:contents` div carrying the `hx-*` attributes. Override per call with `component X.new, refresh: { url: "/x" }`.

### Kits

Package components into a module:

```ruby
module Storefront
  extend Rendry::Kit
  component PriceTag   # => Storefront[:price_tag]
end

Storefront.render(:price_tag, "19.99")
```

`Rendry::Components` is itself a kit: `Rendry::Components[:button]`.

## Examples

`examples/` contains numbered, standalone mini-projects — see `examples/README.md`:

| # | Project | Demo |
|---|---------|------|
| 01 | `01_static_page/` | DSL basics | 
| 02 | `02_component_gallery/` | Components + built-in kit |
| 03 | `03_layout_site/` | Multi-page site, view transitions |
| 04 | `04_tasks_sinatra/` | Sinatra app, server state |
| 05 | `05_htmx_tasks/` | htmx fragment swaps |
| 06 | `06_fragments_cache/` | fragments + cache + `refreshes` |
| 07 | `07_component_kit/` | `Rendry::Kit` packaging |

```sh
bundle exec rake          # tests
bundle exec rake examples # smoke-run static examples
ruby -Ilib test/test_rendry.rb
```

## Project direction

The core targets four properties:

- explicit, readable HTML;
- safe escaping by default;
- Ruby components that are easy to test;
- no mandatory frontend dependency.

This is not a complete web framework yet. Routing, forms, state management, and layout rendering currently belong to the host application, such as Sinatra.

## Contributing

How about contributing to the project? I would be truly delighted to have contributors and people who are interested in the project.

Rendry is deliberately small — contributions that keep it small are the most welcome:

- **Bug reports and fixes** — the DSL has many edge cases (`method_missing` delegation, fragment filtering, context bridging); reproductions are gold.
- **New built-in components** — `Rendry::Components` is a kit; adding a component is a few lines plus a CSS class in `assets/rendry.css`.
- **Examples** — a new `examples/NN_name/` mini-project showing a real use case is the best documentation.
- **Docs** — README sections, yard comments on public API.

Please keep the zero-runtime-dependency spirit: `cgi`, `json`, and `set` are the only requires. No frontend build step, no required JS.

```sh
git clone https://github.com/NICE-DEV226/rendry-ui.git
cd rendry-ui
bundle install
bundle exec rake          # run the test suite
bundle exec rake examples # smoke-run the examples
```

Open an issue first for anything non-trivial so we can align on direction.
