# frozen_string_literal: true

# Projet 03 — Mini-site multi-pages avec layout partage.
#
# Un SiteLayout custom factorise nav + footer ; deux pages (index, apropos)
# sont generees dans le dossier du projet.
#
#   ruby app.rb
#   # ecrit index.html et apropos.html a cote de app.rb
#
require_relative "../../lib/rendry"

class SiteLayout < Rendry::Component
  def initialize(title:, current:, &block)
    @title = title
    @current = current
    @block = block
  end

  def render
    nav_class = ->(name) { "nav-link#{" nav-active" if name == @current}" }

    Rendry.render do
      component Rendry::Components::Layout.new(title: @title) do
        nav(class: "site-nav") do
          a("Accueil", href: "index.html", class: nav_class.call("index"))
          a("A propos", href: "apropos.html", class: nav_class.call("apropos"))
        end
        main { Rendry.evaluate(self, &@block) }
        footer(class: "site-footer") { small { text "Propulse par Rendry UI" } }
      end
    end
  end
end

index = Rendry.render do
  component SiteLayout.new(title: "Accueil — Site Rendry", current: "index") do
    h1 { text "Bienvenue" }
    p "Ce site a deux pages partageant le meme layout."
    component Rendry::Components::Button.new("Voir a propos", href: "apropos.html")
  end
end

apropos = Rendry.render do
  component SiteLayout.new(title: "A propos — Site Rendry", current: "apropos") do
    h1 { text "A propos" }
    p "Chaque page est un rendu Rendry::render avec un composant Layout."
    component Rendry::Components::Button.new("Retour", href: "index.html", variant: "secondary")
  end
end

File.write("index.html", index)
File.write("apropos.html", apropos)
puts "index.html et apropos.html generes."
