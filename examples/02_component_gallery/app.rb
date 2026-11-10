# frozen_string_literal: true

# Projet 02 — Galerie de composants.
#
# Composant custom (StatCard) + kit built-in (Button, Badge, Alert, Card)
# utilises avec leurs slots et variantes.
#
#   ruby app.rb > index.html
#
require_relative "../../lib/rendry"

class StatCard < Rendry::Component
  def initialize(label, value, trend: nil)
    @label = label
    @value = value
    @trend = trend
  end

  def render
    Rendry.render do
      div(class: "rendry-card stat-card") do
        span(@label.upcase, class: "stat-label")
        strong(@value, class: "stat-value")
        small(@trend, class: "stat-trend") if @trend
      end
    end
  end
end

html = Rendry.render do
  component Rendry::Components::Layout.new(title: "Rendry — Composants") do
    h1 { text "Galerie de composants" }

    h2 { text "Custom : StatCard" }
    div(class: "stats") do
      component StatCard.new("Users", "1 248", trend: "+12%")
      component StatCard.new("Revenue", "$8.2k", trend: "+4%")
      component StatCard.new("Churn", "0.8%")
    end

    h2 { text "Buttons" }
    div do
      component Rendry::Components::Button.new("Primary", variant: "primary")
      component Rendry::Components::Button.new("Secondary", variant: "secondary")
      component Rendry::Components::Button.new("Danger", variant: "danger")
      component Rendry::Components::Button.new("Success", variant: "success")
      component Rendry::Components::Button.new("Lien", href: "/docs", variant: "primary")
      component Rendry::Components::Button.new(variant: "secondary") { text "Block DSL" }
    end

    h2 { text "Badges" }
    div do
      %i[default primary success info warning danger].each do |variant|
        component Rendry::Components::Badge.new(variant.to_s.capitalize, variant: variant)
      end
    end

    h2 { text "Alerts" }
    component Rendry::Components::Alert.new("Info message", variant: "info")
    component Rendry::Components::Alert.new("Success message", variant: "success")
    component Rendry::Components::Alert.new("Warning message", variant: "warning")
    component Rendry::Components::Alert.new("Danger message", variant: "danger")

    h2 { text "Card avec slot" }
    component Rendry::Components::Card.new(title: "Titre de la carte") do
      p "Contenu arbitraire passe via do...end."
      component Rendry::Components::Badge.new("Nested", variant: "primary")
    end
  end
end

puts html
