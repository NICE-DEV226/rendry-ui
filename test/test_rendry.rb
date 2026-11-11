# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/rendry"

class RendryTest < Minitest::Test
  def test_renders_nested_html
    html = Rendry.render do
      section(class: "card") do
        h1 { text "Tasks & ideas" }
        p "A small Ruby interface"
      end
    end

    assert_equal '<section class="card"><h1>Tasks &amp; ideas</h1><p>A small Ruby interface</p></section>', html
  end

  def test_escapes_text_and_attributes
    html = Rendry.render do
      p(data_test: '"quoted"') { text "<script>alert(1)</script>" }
    end

    assert_equal '<p data-test="&quot;quoted&quot;">&lt;script&gt;alert(1)&lt;/script&gt;</p>', html
  end

  def test_renders_boolean_and_void_attributes
    html = Rendry.render do
      input(type: "checkbox", checked: true, disabled: false)
    end

    assert_equal '<input type="checkbox" checked>', html
  end

  def test_allows_controlled_raw_html
    html = Rendry.render do
      div { raw '<strong>trusted</strong>' }
    end

    assert_equal '<div><strong>trusted</strong></div>', html
  end

  def test_renders_a_custom_component
    badge_class = Class.new(Rendry::Component) do
      def initialize(label)
        @label = label
      end
      def render
        Rendry.render { span(@label, class: "badge") }
      end
    end

    html = Rendry.render { div { component badge_class.new("Ready") } }
    assert_equal '<div><span class="badge">Ready</span></div>', html
  end

  def test_built_in_button_component
    btn = Rendry::Components::Button.new("Click me", href: "/path", variant: "primary")
    html = btn.render
    assert_includes html, 'class="rendry-btn rendry-btn-primary"'
    assert_includes html, 'href="/path"'
    assert_includes html, 'Click me'
  end

  def test_built_in_badge_component
    badge = Rendry::Components::Badge.new("Success", variant: "success")
    html = badge.render
    assert_includes html, 'class="rendry-badge rendry-badge-success"'
    assert_includes html, 'Success'
  end

  def test_built_in_alert_component
    alert = Rendry::Components::Alert.new("Operation complete", variant: "info")
    html = alert.render
    assert_includes html, 'class="rendry-alert rendry-alert-info"'
    assert_includes html, 'role="alert"'
    assert_includes html, 'Operation complete'
  end

  def test_card_accepts_content_block_via_component
    html = Rendry.render do
      component Rendry::Components::Card.new(title: "Tasks") do
        p "body content"
      end
    end

    assert_includes html, '<h3 class="rendry-card-title">Tasks</h3>'
    assert_includes html, '<div class="rendry-card-body"><p>body content</p></div>'
  end

  def test_layout_wraps_content_in_full_document
    html = Rendry.render do
      component Rendry::Components::Layout.new(title: "My App") do
        h1 { text "Hello" }
      end
    end

    assert_includes html, '<html lang="en">'
    assert_includes html, '<title>My App</title>'
    assert_includes html, '<meta charset="utf-8">'
    assert_includes html, '<body><h1>Hello</h1></body>'
  end

  def test_layout_accepts_head_block
    html = Rendry.render do
      component Rendry::Components::Layout.new(
        title: "Styled",
        head: -> { link(rel: "stylesheet", href: "/app.css") }
      ) do
        p "content"
      end
    end

    assert_includes html, '<link rel="stylesheet" href="/app.css">'
    assert_includes html, '<p>content</p>'
  end

  def test_layout_view_transitions_emits_style_rule
    html = Rendry.render do
      component Rendry::Components::Layout.new(title: "VT", view_transitions: true) do
        p "x"
      end
    end

    assert_includes html, "<style>@view-transition { navigation: auto; }</style>"
  end

  def test_layout_without_view_transitions_has_no_style_rule
    html = Rendry.render do
      component Rendry::Components::Layout.new(title: "NoVT") { p "x" }
    end

    refute_includes html, "@view-transition"
  end

  def test_hx_helper_builds_htmx_attributes
    html = Rendry.render do
      button("Delete", **hx(delete: "/tasks/1", target: "closest .task", swap: "outerHTML"))
    end

    assert_includes html, 'hx-delete="/tasks/1"'
    assert_includes html, 'hx-target="closest .task"'
    assert_includes html, 'hx-swap="outerHTML"'
  end

  def test_hx_encodes_hash_values_as_json
    html = Rendry.render do
      button("Save", **hx(post: "/tasks", vals: { id: 42, draft: true }))
    end

    assert_includes html, 'hx-vals="{&quot;id&quot;:42,&quot;draft&quot;:true}"'
  end

  def test_rendry_hx_works_outside_render
    attrs = Rendry.hx(get: "/poll", trigger: "every 5s")
    assert_equal({ :"hx-get" => "/poll", :"hx-trigger" => "every 5s" }, attrs)
  end

  def test_fragment_is_transparent_in_normal_render
    html = Rendry.render do
      div do
        fragment("main") { p "content" }
      end
    end

    assert_equal '<div><p>content</p></div>', html
  end

  def test_selective_render_outputs_only_matching_fragments
    html = Rendry.render(fragments: ["comments"]) do
      h1 { text "Page title" }
      fragment("comments") { p "only this" }
      fragment("sidebar") { p "skip me" }
    end

    assert_equal "<p>only this</p>", html
  end

  def test_selective_render_finds_fragments_nested_in_tags_and_components
    widget = Class.new(Rendry::Component) do
      def render
        Rendry.render do
          div(class: "widget") do
            fragment("inner") { span "deep fragment" }
          end
        end
      end
    end

    html = Rendry.render(fragments: ["inner"]) do
      section do
        component widget.new
      end
    end

    assert_equal "<span>deep fragment</span>", html
  end

  def test_cache_renders_block_once_per_key
    calls = 0
    2.times do
      Rendry.render do
        cache("counter") do
          calls += 1
          text "cached"
        end
      end
    end

    assert_equal 1, calls
    Rendry.cache_store.clear
  end

  def test_component_class_refreshes_wraps_output_with_hx_attributes
    poller = Class.new(Rendry::Component) do
      refreshes every: "5s", url: "/poll", target: "#poller"

      def render
        Rendry.render { span "live" }
      end
    end

    html = Rendry.render { component poller.new }

    assert_includes html, '<div class="rendry-refresh" style="display:contents"'
    assert_includes html, 'hx-get="/poll"'
    assert_includes html, 'hx-trigger="every 5s"'
    assert_includes html, 'hx-target="#poller"'
    assert_includes html, 'hx-swap="outerHTML"'
    assert_includes html, "<span>live</span>"
  end

  def test_component_refresh_kwarg_overrides_class_config
    widget = Class.new(Rendry::Component) do
      def render
        Rendry.render { span "w" }
      end
    end

    html = Rendry.render { component widget.new, refresh: { url: "/w", every: "1s" } }

    assert_includes html, 'hx-get="/w"'
    assert_includes html, 'hx-trigger="every 1s"'
    assert_includes html, 'hx-target="this"'
  end

  def test_kit_registers_and_resolves_components
    kit = Module.new do
      extend Rendry::Kit

      widget = Class.new(Rendry::Component) do
        def render
          Rendry.render { span "kit widget" }
        end
      end
      component widget, as: :widget
    end

    assert_equal :widget, kit.components.keys.first
    assert_instance_of kit[:widget], kit[:widget].new
    assert_includes kit.render(:widget), "kit widget"
    assert_raises(KeyError) { kit[:missing] }
  end

  def test_builtin_components_kit_resolves_by_name
    assert_equal Rendry::Components::Button, Rendry::Components[:button]
    assert_includes Rendry::Components.render(:badge, "Hi", variant: "info"), "Hi"
  end
end
