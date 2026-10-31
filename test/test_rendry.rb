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

  def test_renders_a_component
    badge = Class.new(Rendry::Component) do
      def render
        Rendry.render { span(class: "badge") { text "Ready" } }
      end
    end.new

    html = Rendry.render { div { component badge } }

    assert_equal '<div><span class="badge">Ready</span></div>', html
  end
end
