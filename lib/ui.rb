require_relative "ruby_ui"

module UI
  module_function

  def button(label, href:, variant: "primary")
    RubyUI.render do
      a(label, href: href, class: "button button-#{variant}")
    end
  end

  def status(completed)
    label = completed ? "Completed" : "In progress"
    css_class = completed ? "complete" : "pending"
    RubyUI.render do
      span(label, class: "status status-#{css_class}")
    end
  end
end
