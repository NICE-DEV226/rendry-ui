# frozen_string_literal: true

require_relative "lib/rendry/version"

Gem::Specification.new do |spec|
  spec.name = "rendry"
  spec.version = Rendry::VERSION
  spec.authors = ["NICE-DEV226"]
  spec.email = ["NICE-DEV226@users.noreply.github.com"]

  spec.summary = "Lightweight server-rendered HTML DSL for Ruby"
  spec.description = <<~DESC
    Rendry UI is a small DSL for composing HTML with Ruby: explicit markup,
    safe escaping by default, testable components, optional htmx
    interactivity, selective fragments, fragment caching, and component kits —
    with no mandatory JavaScript.
  DESC
  spec.homepage = "https://github.com/NICE-DEV226/rendry-ui"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/NICE-DEV226/rendry-ui"
  spec.metadata["changelog_uri"] = "https://github.com/NICE-DEV226/rendry-ui/releases"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |file|
      file.start_with?("lib/", "LICENSE", "README")
    end
  end
  spec.require_paths = ["lib"]
end
