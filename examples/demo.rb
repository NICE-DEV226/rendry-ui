# frozen_string_literal: true

require_relative "../lib/ruby_ui"

class TaskCard < RubyUI::Component
  def initialize(title:, description:, completed: false)
    @title = title
    @description = description
    @completed = completed
  end

  def render
    title = @title
    description = @description
    status = @completed ? "Done" : "Open"

    RubyUI.render do
      article(class: "task-card") do
        span(status, class: "status")
        h2 title
        p description
      end
    end
  end
end

page = RubyUI.render do
  main(class: "page") do
    h1 { text "My tasks" }
    p "A tiny interface rendered by RubyUI."
    component TaskCard.new(
      title: "Learn the builder",
      description: "Compose HTML with Ruby methods.",
      completed: true
    )
  end
end

puts page
