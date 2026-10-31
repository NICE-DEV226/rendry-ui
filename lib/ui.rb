require_relative "rendry"

module UI
  module_function

  def button(label, href:, variant: "primary")
    Rendry.render do
      a(label, href: href, class: "button button-#{variant}")
    end
  end

  def status(completed)
    label = completed ? "Completed" : "In progress"
    css_class = completed ? "complete" : "pending"
    Rendry.render do
      span(label, class: "status status-#{css_class}")
    end
  end
end
