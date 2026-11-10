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
end
