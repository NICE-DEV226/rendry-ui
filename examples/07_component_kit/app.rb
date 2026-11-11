# frozen_string_literal: true

# Projet 07 — Kits de composants.
#
# Un kit est un module qui enregistre ses composants :
#   Storefront[:price_tag]          -> la classe
#   Storefront.render(:price_tag)   -> HTML rendu
#   Storefront.components           -> inventaire
# Le kit built-in est expose pareil : Rendry::Components[:button]
#
#   ruby app.rb > index.html
#
require_relative "../../lib/rendry"

module Storefront
  extend Rendry::Kit

  class PriceTag < Rendry::Component
    def initialize(amount, currency: "$")
      @amount = amount
      @currency = currency
    end

    def render
      Rendry.render do
        span("#{@currency}#{@amount}", class: "price-tag")
      end
    end
  end

  class ProductCard < Rendry::Component
    def initialize(name, price, **attributes)
      @name = name
      @price = price
      @attributes = attributes
    end

    def render
      Rendry.render do
        div(class: "rendry-card product-card") do
          h3(@name)
          component Storefront[:price_tag].new(@price)
          p(class: "muted") { text @attributes[:description].to_s }
        end
      end
    end
  end

  component PriceTag
  component ProductCard
end

products = [
  { name: "Mechanical Keyboard", price: "129.00", description: "Hot-swappable, RGB" },
  { name: "Webcam 4K", price: "89.50", description: "HDR, autofocus" },
  { name: "USB-C Hub", price: "45.00", description: "7 ports, 100W PD" }
]

html = Rendry.render do
  component Rendry::Components::Layout.new(title: "Storefront — Kit demo") do
    h1 { text "Catalogue (kit Storefront)" }

    p("Composants enregistres : #{Storefront.components.keys.join(", ")}")

    div(class: "product-grid") do
      products.each do |product|
        component Storefront[:product_card].new(
          product[:name],
          product[:price],
          description: product[:description]
        )
      end
    end

    h2 { text "Rendu direct depuis le kit" }
    raw Storefront.render(:price_tag, "19.99", currency: "€")
  end
end

puts html
