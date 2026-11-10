# frozen_string_literal: true

# Projet 01 — Page statique pure.
#
# Le DSL Rendry seul, sans composant custom : tags, texte, attributs,
# echappement automatique, elements void et custom elements.
#
#   ruby app.rb > index.html
#
require_relative "../../lib/rendry"

html = Rendry.render do
  component Rendry::Components::Layout.new(title: "Rendry — Projet 01") do
    header(class: "hero") do
      h1 { text "Rendry UI" }
      p "Un DSL Ruby leger pour ecrire du HTML cote serveur."
    end

    section do
      h2 { text "Ce que ce projet demontre" }
      ul do
        li { text "Tags via method_missing : section, h2, ul, li..." }
        li { text "Echappement automatique du texte et des attributs" }
        li { text "Attributs booleens (required, checked...) et elements void (br, input)" }
        li { text "Custom elements : custom_element(data_value: 42)" }
      end
    end

    footer { small { text "Genere par examples/01_static_page" } }
  end
end

puts html
