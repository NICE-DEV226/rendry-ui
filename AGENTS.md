# AGENTS.md

## Git

- NEVER add Devin/AI attribution to commits or push messages
  (no "Generated with", no "Co-Authored-By", no tool trailers).
- Commit messages: concise, focused on the "why".

## Project

- Rendry UI: lightweight server-rendered HTML DSL for Ruby (`lib/rendry.rb`).
- Test: `ruby -Ilib test/test_rendry.rb`
- Examples: `examples/NN_name/app.rb` — numbered standalone mini-projects.
- Stack: Sinatra 4 + Rack 3 + Sequel/SQLite + Puma (see Gemfile).
