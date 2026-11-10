# frozen_string_literal: true

# Projet 04 — Mini app Sinatra : CRUD de taches en memoire.
#
# Rendry pour toutes les vues, Layout partage, formulaire POST, etat
# serveur simple (tableau Ruby). La base pour brancher Sequel/SQLite.
#
#   ruby app.rb
#   # -> http://localhost:4567
#
require "sinatra"
require_relative "../../lib/rendry"

TASKS = [
  { title: "Decouvrir Rendry", done: true },
  { title: "Ecrire une vue", done: false },
  { title: "Brancher une base", done: false }
]

class TaskList < Rendry::Component
  def initialize(tasks)
    @tasks = tasks
  end

  def render
    Rendry.render do
      ul(class: "task-list") do
        @tasks.each do |task|
          li(class: "task") do
            span(task[:title], class: task[:done] ? "task-done" : "task-title")
            form(action: "/tasks/#{@tasks.index(task)}/toggle", method: "post", class: "inline") do
              button(task[:done] ? "Reopen" : "Done", type: "submit", class: "rendry-btn rendry-btn-secondary")
            end
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
      head: -> { link(rel: "stylesheet", href: "/rendry.css") }
    ) do
      instance_eval(&block)
    end
  end
end

get "/" do
  layout("Rendry Tasks") do
    h1 { text "Tasks" }
    component Rendry::Components::Alert.new("#{TASKS.count { |t| !t[:done] }} restantes", variant: "info")
    component TaskList.new(TASKS)
    component Rendry::Components::Card.new(title: "Nouvelle tache") do
      form(action: "/tasks", method: "post") do
        input(type: "text", name: "title", placeholder: "Titre...", required: true)
        button("Ajouter", type: "submit", class: "rendry-btn rendry-btn-primary")
      end
    end
  end
end

post "/tasks" do
  title = params["title"].to_s.strip
  TASKS << { title: title, done: false } unless title.empty?
  redirect "/"
end

post "/tasks/:id/toggle" do
  task = TASKS[params[:id].to_i]
  task[:done] = !task[:done] if task
  redirect "/"
end

get "/rendry.css" do
  content_type "text/css"
  send_file File.expand_path("../rendry.css", __dir__)
end
