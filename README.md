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

## Components

```ruby
class Badge < Rendry::Component
  def initialize(label)
    @label = label
  end

  def render
    Rendry.render { span(@label, class: "badge") }
  end
end

Rendry.render { component Badge.new("Ready") }
```

Components keep access to their instance variables inside DSL blocks, and accept a content block via `do...end` or `{ }`.

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
