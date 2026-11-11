# frozen_string_literal: true

require "cgi"
require "json"
require "set"
require_relative "rendry/version"

module Rendry
  class SafeHTML < String
    def html_safe?
      true
    end
  end

  VOID_ELEMENTS = Set.new(%w[area base br col embed hr img input link meta param source track wbr]).freeze
  BOOLEAN_ATTRIBUTES = Set.new(%i[allowfullscreen async autofocus autoplay checked controls defer disabled formnovalidate hidden inert loop multiple muted nomodule novalidate open playsinline readonly required reversed selected]).freeze

  class Cache
    def initialize(limit: 128)
      @store = {}
      @limit = limit
      @mutex = Mutex.new
    end

    def fetch(key)
      @mutex.synchronize do
        return @store[key] if @store.key?(key)

        value = yield
        @store[key] = value
        @store.shift while @store.size > @limit
        value
      end
    end

    def clear
      @mutex.synchronize { @store.clear }
    end
  end

  class Builder
    attr_reader :output

    def initialize(enabled: true)
      @output = +""
      @enabled = enabled
    end

    def render
      @output
    end

    def text(value)
      write CGI.escapeHTML(value.to_s)
      self
    end

    def raw(value)
      write value.to_s
      self
    end

    def tag(name, content = nil, **attributes, &block)
      if content.is_a?(Hash) && attributes.empty?
        attributes = content
        content = nil
      end

      if block
        children = Builder.new(enabled: @enabled)
        result = Rendry.evaluate(children, &block)
        children.append_result(result)
        content = SafeHTML.new(children.render)
      end

      output = +"<#{name}#{format_attributes(attributes)}>"
      unless VOID_ELEMENTS.include?(name.to_s)
        output << (content.is_a?(SafeHTML) ? content : CGI.escapeHTML(content.to_s))
        output << "</#{name}>"
      end
      write output
      self
    end

    def fragment(name, &block)
      filter = Rendry.current_fragments
      if filter
        return self unless filter.include?(name.to_s)

        target = Rendry.root_builder || self
        previous = target.instance_variable_get(:@enabled)
        target.instance_variable_set(:@enabled, true)
        begin
          Rendry.evaluate(target, &block)
        ensure
          target.instance_variable_set(:@enabled, previous)
        end
      else
        Rendry.evaluate(self, &block)
      end
      self
    end

    def cache(*keys, **_options, &block)
      location = block.source_location.join(":")
      key = "#{location}:#{keys.inspect}"
      html = Rendry.cache_store.fetch(key) do
        child = Builder.new(enabled: @enabled)
        Rendry.evaluate(child, &block)
        SafeHTML.new(child.render)
      end
      write html
      self
    end

    def hx(**attributes)
      Rendry.hx(**attributes)
    end

    def component(component_instance, refresh: nil, &block)
      if component_instance.respond_to?(:view_context=)
        component_instance.view_context = @context
      end
      if block && component_instance.respond_to?(:block=) && !component_instance.instance_variable_get(:@block)
        component_instance.block = block
      end
      rendered = component_instance.render
      html = rendered.is_a?(SafeHTML) ? rendered : SafeHTML.new(CGI.escapeHTML(rendered.to_s))
      config = refresh || (component_instance.class.refresh_config if component_instance.class.respond_to?(:refresh_config))
      html = refresh_wrapper(html, config) if config
      if @enabled
        write html
      elsif Rendry.current_fragments
        @output << html
      end
      self
    end

    def p(content = nil, **attributes, &block)
      tag("p", content, **attributes, &block)
    end

    def method_missing(name, content = nil, **attributes, &block)
      if name.to_s.match?(/\A[a-z][a-z0-9_]*\z/)
        context = @context
        helper = context && context.respond_to?(name) ? context.method(name) : nil
        has_arguments = !(content.nil? && attributes.empty? && !block)
        if helper && !(helper.arity == 0 && has_arguments)
          if content.nil? && attributes.empty? && !block
            context.public_send(name)
          elsif content.nil?
            context.public_send(name, **attributes, &block)
          else
            context.public_send(name, content, **attributes, &block)
          end
        else
          tag(name.to_s.tr("_", "-"), content, **attributes, &block)
        end
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.to_s.match?(/\A[a-z][a-z0-9_]*\z/) || super
    end

    def append_result(result)
      if result.is_a?(SafeHTML)
        write result
      elsif Rendry.appendable_result?(result)
        write CGI.escapeHTML(result.to_s)
      end
      self
    end

    private

    def write(string)
      @output << string if @enabled
    end

    def refresh_wrapper(html, config)
      attributes = {
        class: "rendry-refresh",
        style: "display:contents",
        hx_get: config[:url],
        hx_trigger: config[:trigger] || (config[:every] && "every #{config[:every]}") || "load",
        hx_target: config[:target] || "this",
        hx_swap: config[:swap] || "outerHTML"
      }.compact
      output = +"<div#{format_attributes(attributes)}>"
      output << html
      output << "</div>"
      SafeHTML.new(output)
    end

    def format_attributes(attributes)
      attributes.each_with_object(+"") do |(key, value), result|
        next if value.nil? || value == false

        if (key == :data || key == :aria) && value.is_a?(Hash)
          value.each do |nested_key, nested_value|
            next if nested_value.nil? || nested_value == false

            result << %( #{key}-#{nested_key.to_s.tr('_', '-')}="#{CGI.escapeHTML(nested_value.to_s)}")
          end
          next
        end

        attribute = key.to_s.tr("_", "-")
        if Rendry.sanitize_urls && URL_ATTRIBUTES.include?(attribute) &&
           value.to_s.match?(UNSAFE_URL_SCHEME)
          value = "#"
        end
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
    attr_accessor :view_context

    class << self
      def refreshes(**config)
        @refresh_config = config
      end

      def refresh_config
        @refresh_config
      end

      def template(&block)
        @template_block = block if block
        @template_block || (superclass.template if superclass.respond_to?(:template))
      end
    end

    def render
      block = self.class.template
      raise NotImplementedError, "#{self.class} must implement #render or declare a template" unless block

      builder = Builder.new
      result = Rendry.evaluate(builder, self, context: view_context, &block)
      builder.append_result(result)
      SafeHTML.new(builder.render)
    end
  end

  module Kit
    def self.extended(base)
      base.instance_variable_set(:@kit_components, {})
    end

    def component(klass, as: nil)
      key = (as || klass.name.to_s.split("::").last).to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
      kit_components[key] = klass
      klass
    end

    def [](name)
      kit_components.fetch(name.to_sym) do
        raise KeyError, "unknown component #{name.inspect} in #{self}"
      end
    end

    def components
      kit_components.dup
    end

    def render(name, *args, **kwargs, &block)
      self[name].new(*args, **kwargs, &block).render
    end

    private

    def kit_components
      @kit_components ||= {}
    end
  end

  # Built-in Standard UI Components Kit
  module Components
    class Layout < Component
      def initialize(title: "Rendry", head: nil, view_transitions: false, **attributes, &block)
        @title = title
        @head = head
        @view_transitions = view_transitions
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
              if @view_transitions
                style { raw "@view-transition { navigation: auto; }" }
              end
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

    extend Kit
    component Layout
    component Button
    component Badge
    component Card
    component Alert
  end

  UNSAFE_URL_SCHEME = /\A\s*(javascript|vbscript|data(?!:image\/))\s*:/i
  URL_ATTRIBUTES = %w[href src action formaction xlink:href].freeze

  module_function

  def sanitize_urls
    @sanitize_urls != false
  end

  def sanitize_urls=(value)
    @sanitize_urls = value
  end

  def appendable_result?(value)
    value.is_a?(String) || value.is_a?(Numeric) || value.is_a?(Symbol)
  end

  def hx(**attributes)
    attributes.each_with_object({}) do |(key, value), result|
      value = JSON.generate(value) if value.is_a?(Hash) || value.is_a?(Array)
      result[:"hx-#{key.to_s.tr('_', '-')}"] = value
    end
  end

  def cache_store
    @cache_store ||= Cache.new
  end

  def current_fragments
    Thread.current[:rendry_current_fragments]
  end

  def root_builder
    Thread.current[:rendry_root_builder]
  end

  def render(fragments: nil, &block)
    filter = fragments || current_fragments
    builder = Builder.new(enabled: filter.nil?)
    if fragments
      previous_fragments = current_fragments
      previous_root = root_builder
      Thread.current[:rendry_current_fragments] = fragments.map(&:to_s)
      Thread.current[:rendry_root_builder] = builder
      begin
        result = evaluate(builder, &block)
      ensure
        Thread.current[:rendry_current_fragments] = previous_fragments
        Thread.current[:rendry_root_builder] = previous_root
      end
    else
      result = evaluate(builder, &block)
    end
    builder.append_result(result)
    SafeHTML.new(builder.render)
  end

  def evaluate(builder, owner = nil, context: nil, &block)
    owner ||= block&.binding&.receiver
    raise ArgumentError, "Rendry.evaluate requires a block" unless block && owner

    inherited = owner.instance_variable_get(:@context) if owner.is_a?(Builder)
    owner.instance_variables.each do |ivar|
      next if ivar == :@output || ivar == :@enabled || ivar == :@context

      builder.instance_variable_set(ivar, owner.instance_variable_get(ivar))
    end
    resolved = context || inherited || (owner unless owner.is_a?(Builder))
    builder.instance_variable_set(:@context, resolved)
    if block.lambda? && block.arity.zero?
      builder.instance_exec(&block)
    else
      builder.instance_eval(&block)
    end
  end
end
