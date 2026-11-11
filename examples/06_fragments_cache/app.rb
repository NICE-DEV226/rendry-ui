# frozen_string_literal: true

# Projet 06 — Fragments selectifs + cache de fragments.
#
# - fragment("name") : transparent en rendu normal, mais
#   Rendry.render(fragments: ["name"]) ne produit que ce fragment,
#   meme imbrique dans des composants -> endpoint de swap htmx.
# - refreshes (niveau classe) : polling htmx automatique via un
#   wrapper display:contents -> GET /comments toutes les 10s.
# - cache(*keys) : le block n'est evalue qu'une fois par cle
#   (store FIFO en memoire, Rendry.cache_store).
#
#   bundle exec ruby app.rb
#   # -> http://localhost:4567
#
require "sinatra"
require_relative "../../lib/rendry"

COMMENTS = ["Premier commentaire", "Rendry est léger"]

class Comments < Rendry::Component
  refreshes every: "10s", url: "/comments", target: "#comments"

  def initialize(items)
    @items = items
  end

  def render
    Rendry.render do
      fragment("comments") do
        div(id: "comments") do
          h2 { text "Commentaires" }
          ul do
            @items.each { |comment| li { text comment } }
          end
          form(**hx(post: "/comments", target: "#comments", swap: "outerHTML")) do
            input(type: "text", name: "body", placeholder: "Commenter...", required: true)
            button("Envoyer", type: "submit", class: "rendry-btn rendry-btn-primary")
          end
        end
      end
    end
  end
end

class Sidebar < Rendry::Component
  def render
    Rendry.render do
      aside(class: "sidebar") do
        cache("sidebar") do
          h2 { text "Archive" }
          ul do
            %w[2026-11 2026-10 2026-09].each { |month| li { text month } }
          end
          p(class: "muted") { text "Ce bloc est rendu une seule fois (cache)." }
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
        script(src: "https://unpkg.com/htmx.org@2.0.4")
        link(rel: "stylesheet", href: "/rendry.css")
      end
    ) do
      instance_eval(&block)
    end
  end
end

get "/" do
  layout("Rendry — fragments & cache") do
    h1 { text "Fragments selectifs" }
    component Sidebar.new
    component Comments.new(COMMENTS)
  end
end

get "/comments" do
  content_type :html
  Rendry.render(fragments: ["comments"]) do
    component Comments.new(COMMENTS)
  end
end

post "/comments" do
  body = params["body"].to_s.strip
  COMMENTS << body unless body.empty?
  content_type :html
  Rendry.render(fragments: ["comments"]) do
    component Comments.new(COMMENTS)
  end
end

get "/rendry.css" do
  content_type "text/css"
  send_file File.expand_path("../rendry.css", __dir__)
end
