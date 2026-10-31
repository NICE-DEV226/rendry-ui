# frozen_string_literal: true

require "cgi"

module RubyUI
  class SafeHTML < String
    def html_safe?
      true
    end
  end

  VOID_ELEMENTS = %w[area base br col embed hr img input link meta param source track wbr].freeze
  BOOLEAN_ATTRIBUTES = %i[allowfullscreen async autofocus autoplay checked controls defer disabled formnovalidate hidden inert loop multiple muted nomodule novalidate open playsinline readonly required reversed selected].freeze

  class Builder
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
        children.instance_eval(&block)
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

    def component(component)
      raw(component.render)
      self
    end

    def p(content = nil, **attributes, &block)
      tag("p", content, **attributes, &block)
    end

    def method_missing(name, content = nil, **attributes, &block)
      return super unless name.to_s.match?(/\A[a-z][a-z0-9_]*\z/)

      tag(name.to_s.tr("_", "-"), content, **attributes, &block)
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
    def render
      raise NotImplementedError, "#{self.class} must implement #render"
    end
  end

  module_function

  def render(&block)
    builder = Builder.new
    builder.instance_eval(&block)
    SafeHTML.new(builder.render)
  end
end
