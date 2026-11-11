# frozen_string_literal: true

require "cgi"
require "json"
require_relative "rendry/version"

module Rendry
  class SafeHTML < String
    def html_safe?
      true
    end
  end

  VOID_ELEMENTS = %w[area base br col embed hr img input link meta param source track wbr].freeze
  BOOLEAN_ATTRIBUTES = %i[allowfullscreen async autofocus autoplay checked controls defer disabled formnovalidate hidden inert loop multiple muted nomodule novalidate open playsinline readonly required reversed selected].freeze

  class Builder
    attr_reader :output

    def initialize
      @output = +""
    end

    def render
      @output
    end

    def text(value)
      @output << CGI.escapeHTML(value.to_s)
      self
    end

    def raw(value)
      @output << value.to_s
      self
    end

    def tag(name, content = nil, **attributes, &block)
      if content.is_a?(Hash) && attributes.empty?
        attributes = content
        content = nil
      end

      if block
        children = Builder.new
        Rendry.evaluate(children, &block)
        content = SafeHTML.new(children.render)
      end

      output = +"<#{name}#{format_attributes(attributes)}>"
      unless VOID_ELEMENTS.include?(name.to_s)
        output << (content.is_a?(SafeHTML) ? content : CGI.escapeHTML(content.to_s))
        output << "</#{name}>"
      end
      @output << output
      self
    end

    def hx(**attributes)
      Rendry.hx(**attributes)
    end

    def component(component_instance, &block)
      if block && component_instance.respond_to?(:block=) && !component_instance.instance_variable_get(:@block)
        component_instance.block = block
      end
      rendered = component_instance.render
      @output << (rendered.is_a?(SafeHTML) ? rendered : SafeHTML.new(CGI.escapeHTML(rendered.to_s)))
      self
    end

    def p(content = nil, **attributes, &block)
      tag("p", content, **attributes, &block)
    end

    def method_missing(name, content = nil, **attributes, &block)
      if name.to_s.match?(/\A[a-z][a-z0-9_]*\z/)
        tag(name.to_s.tr("_", "-"), content, **attributes, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.to_s.match?(/\A[a-z][a-z0-9_]*\z/) || super
    end

    private

    def format_attributes(attributes)
      attributes.each_with_object(+"") do |(key, value), result|
        next if value.nil? || value == false

        attribute = key.to_s.tr("_", "-")
        if BOOLEAN_ATTRIBUTES.include?(key.to_sym)
          result << " #{attribute}"
        else
          result << %( #{attribute}="#{CGI.escapeHTML(value.to_s)}")
        end
      end
    end
  end

  class Component
    attr_writer :block

    def render
      raise NotImplementedError, "#{self.class} must implement #render"
    end
  end

  # Built-in Standard UI Components Kit
  module Components
    class Layout < Component
      def initialize(title: "Rendry", head: nil, **attributes, &block)
        @title = title
        @head = head
        @attributes = attributes
        @block = block
      end

      def render
        Rendry.render do
          html(lang: "en", **@attributes) do
            head do
              meta(charset: "utf-8")
              meta(name: "viewport", content: "width=device-width, initial-scale=1")
              title(@title)
              Rendry.evaluate(self, &@head) if @head
            end
            body do
              Rendry.evaluate(self, &@block) if @block
            end
          end
        end
      end
    end

    class Button < Component
      def initialize(label = nil, href: nil, variant: "primary", type: "button", **attributes, &block)
        @label = label
        @href = href
        @variant = variant
        @type = type
        @attributes = attributes
        @block = block
      end

      def render
        css = "rendry-btn rendry-btn-#{@variant} #{@attributes[:class]}".strip
        attrs = @attributes.except(:class)
        if @href
          Rendry.render do
            a(href: @href, class: css, **attrs) do
              @label ? text(@label) : (@block && Rendry.evaluate(self, &@block))
            end
          end
        else
          Rendry.render do
            button(type: @type, class: css, **attrs) do
              @label ? text(@label) : (@block && Rendry.evaluate(self, &@block))
            end
          end
        end
      end
    end

    class Badge < Component
      def initialize(label, variant: "default", **attributes)
        @label = label
        @variant = variant
        @attributes = attributes
      end

      def render
        css = "rendry-badge rendry-badge-#{@variant} #{@attributes[:class]}".strip
        Rendry.render do
          span(@label, class: css, **@attributes.except(:class))
        end
      end
    end

    class Card < Component
      def initialize(title: nil, **attributes, &block)
        @title = title
        @attributes = attributes
        @block = block
      end

      def render
        css = "rendry-card #{@attributes[:class]}".strip
        Rendry.render do
          div(class: css, **@attributes.except(:class)) do
            h3(@title, class: "rendry-card-title") if @title
            div(class: "rendry-card-body") do
              if @block
                Rendry.evaluate(self, &@block)
              end
            end
          end
        end
      end
    end

    class Alert < Component
      def initialize(message = nil, variant: "info", **attributes, &block)
        @message = message
        @variant = variant
        @attributes = attributes
        @block = block
      end

      def render
        css = "rendry-alert rendry-alert-#{@variant} #{@attributes[:class]}".strip
        Rendry.render do
          div(class: css, role: "alert", **@attributes.except(:class)) do
            text(@message) if @message
            if @block
              Rendry.evaluate(self, &@block)
            end
          end
        end
      end
    end
  end

  module_function

  def hx(**attributes)
    attributes.each_with_object({}) do |(key, value), result|
      value = JSON.generate(value) if value.is_a?(Hash) || value.is_a?(Array)
      result[:"hx-#{key.to_s.tr('_', '-')}"] = value
    end
  end

  def render(&block)
    builder = Builder.new
    evaluate(builder, &block)
    SafeHTML.new(builder.render)
  end

  def evaluate(builder, &block)
    owner = block.binding.receiver
    owner.instance_variables.each do |ivar|
      next if ivar == :@output

      builder.instance_variable_set(ivar, owner.instance_variable_get(ivar))
    end
    if block.lambda? && block.arity.zero?
      builder.instance_exec(&block)
    else
      builder.instance_eval(&block)
    end
  end
end
