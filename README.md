# Rendry UI

Rendry UI is a lightweight server-rendered UI framework prototype for Ruby. It provides a small DSL for composing HTML with Ruby, without mandatory JavaScript or a prescribed application structure.

## Utilisation

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

## Composants

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

## Run the examples

Each file under `examples/` is a self-contained, runnable step:

```sh
ruby examples/01_basics.rb        # DSL: tags, text, attributes, escaping
ruby examples/02_components.rb    # custom components + built-in kit
ruby examples/03_layout.rb        # full HTML document via Layout
ruby examples/04_full_page.rb     # composed page (save output next to examples/rendry.css)
ruby -Ilib test/test_rendry.rb
```

## Project direction

The core targets four properties:

- explicit, readable HTML;
- safe escaping by default;
- Ruby components that are easy to test;
- no mandatory frontend dependency.

This is not a complete web framework yet. Routing, forms, state management, and layout rendering currently belong to the host application, such as Sinatra.
