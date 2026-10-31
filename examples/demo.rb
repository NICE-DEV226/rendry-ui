# frozen_string_literal: true

require_relative "../lib/rendry"

class TaskCard < Rendry::Component
  def initialize(title:, description:, completed: false)
    @title = title
    @description = description
    @completed = completed
  end

  def render
    title = @title
    description = @description
    status = @completed ? "Done" : "Open"

    Rendry.render do
      article(class: "task-card") do
        span(status, class: "status")
        h2 title
        p description
      end
    end
  end
end

page = Rendry.render do
  main(class: "page") do
    h1 { text "My tasks" }
    p "A tiny interface rendered by Rendry."
    component TaskCard.new(
      title: "Learn the builder",
      description: "Compose HTML with Ruby methods.",
      completed: true
    )
  end
end

puts page
