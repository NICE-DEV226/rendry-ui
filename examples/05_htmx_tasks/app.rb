# frozen_string_literal: true

# Projet 05 — App htmx : interactivite sans JavaScript custom.
#
# Meme base que 04, mais les echanges passent par htmx :
# le serveur renvoie des fragments Rendry, le browser les swap.
# Le helper `hx` construit les attributs hx-*.
#
#   bundle exec ruby app.rb
#   # -> http://localhost:4567 (necessite un acces CDN pour htmx.org)
#
require "sinatra"
require_relative "../../lib/rendry"

HTMX_SRC = "https://unpkg.com/htmx.org@2.0.4"

TASKS = [
  { title: "Decouvrir Rendry", done: true },
  { title: "Ajouter les helpers hx", done: false },
  { title: "Brancher une base", done: false }
]

class TaskList < Rendry::Component
  def initialize(tasks)
    @tasks = tasks
  end

  def render
    Rendry.render do
      ul(class: "task-list") do
        @tasks.each_with_index do |task, index|
          li(class: "task") do
            span(task[:title], class: task[:done] ? "task-done" : "task-title")
            button(task[:done] ? "Reopen" : "Done",
                   type: "submit",
                   class: "rendry-btn rendry-btn-secondary",
                   **hx(post: "/tasks/#{index}/toggle", target: "#tasks", swap: "innerHTML"))
          end
        end
      end
    end
  end
end

def layout(title, &block)
  Rendry.render do
    component Rendry::Components::Layout.new(
      title: title,
      head: -> do
        script(src: HTMX_SRC)
        link(rel: "stylesheet", href: "/rendry.css")
      end
    ) do
      instance_eval(&block)
    end
  end
end

def tasks_fragment
  content_type :html
  TaskList.new(TASKS).render
end

get "/" do
  layout("Rendry + htmx") do
    h1 { text "Tasks (htmx)" }
    div(id: "tasks") do
      component TaskList.new(TASKS)
    end
    component Rendry::Components::Card.new(title: "Nouvelle tache") do
      form(**hx(post: "/tasks", target: "#tasks", swap: "innerHTML")) do
        input(type: "text", name: "title", placeholder: "Titre...", required: true)
        button("Ajouter", type: "submit", class: "rendry-btn rendry-btn-primary")
      end
    end
  end
end

post "/tasks" do
  title = params["title"].to_s.strip
  TASKS << { title: title, done: false } unless title.empty?
  tasks_fragment
end

post "/tasks/:id/toggle" do
  task = TASKS[params[:id].to_i]
  task[:done] = !task[:done] if task
  tasks_fragment
end

get "/rendry.css" do
  content_type "text/css"
  send_file File.expand_path("../rendry.css", __dir__)
end
