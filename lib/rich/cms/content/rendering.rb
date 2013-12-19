module Rich
  module Cms
    module Content
      module Rendering

        CALLBACKS = [:before_edit, :after_update]

        def self.included(base)
          base.extend ClassMethods
          base.send :include, InstanceMethods
          base.class_eval do
            @css_class     = nil
            @configuration = nil
          end
        end

        module ClassMethods

          def configuration
            @configuration ||= {}
          end

          def css_class(klass = nil)
            (@css_class = klass.to_s.downcase unless klass.nil?) || @css_class || "rcms_#{self.name.demodulize.underscore}".gsub(/(cms_){2,}/, "cms_")
          end

          def configure(*args, &block)
            @configuration = args.extract_options!.symbolize_keys!
            @css_class     = args.first unless args.first.nil?
            config_mock.instance_eval(&block) if block_given?
          end

          def to_javascript_hash
            cmsable? ? "{#{data_pairs.concat(callback_pairs).collect{|key, value| "#{key}: #{value}"}.join(", ")}}".html_safe : ""
          end

        private

          def config_mock
            @config_mock ||= ConfigMock.new self
          end

          class ConfigMock
            def initialize(klass)
              @klass = klass
            end

            def method_missing(method, *args)
              if %w(tag before_edit after_update).include? method.to_s
                @klass.instance_variable_get(:@configuration)[method] = args.first
              else
                super
              end
            end
          end

          def data_pairs
            pairs         = ActiveSupport::OrderedHash.new
            pairs[:keys ] = ["store_key"]
            pairs[:value] = "store_value"

            pairs.collect do |key, value|
              collected = [value].flatten.collect{|x| "data-#{x}"}
              value     = (value.is_a?(Array) ? collected : collected.first).inspect
              [key, value]
            end
          end

          def callback_pairs
            [].tap do |array|
              configuration.values_at(*CALLBACKS).each_with_index do |value, index|
                next if value.blank?
                key = CALLBACKS[index].to_s.camelize(:lower)
                array << [key, value]
              end
            end
          end

        end

        module InstanceMethods

          def to_tag(options = {})
            attrs = ActiveSupport::OrderedHash.new
            attrs[:mustache_locals] = options.delete(:locals)

            tag = derive_tag(options)

            if tag.nil?
              parse_locals(value, attrs[:mustache_locals])
            else
              (options[:html] || {}).each do |key, value|
                attrs[key.to_sym] = value
              end

              if editable?
                attrs[:class]                     = [self.class.css_class, attrs.try(:fetch, :class, nil)].compact.join " "
                attrs["data-store_key"]           = store_key
                attrs["data-store_value"]         = @store_value
                attrs["data-editable_input_type"] = options[:as] if %w(string text html).include? options[:as].to_s.downcase

                (options[:data] || {}).each do |key, value|
                  attrs["data-#{key}"] = value
                end
              end

              if options.include? :collection
                render_collection options[:collection], tag, attrs
              else
                tag_string tag, attrs
              end
            end.html_safe
          end

          def derive_tag(options)
            tag = options[:tag] || configuration[:tag]

            return if !editable? && tag == :none

            if tag != :none
              tag
            else
              [:text, :html].include?(options[:as]) ? :div : :span
            end
          end

          def derive_text
            editable? && default_value? ? "< #{value} >" : value
          end

          def to_json(params = {})
            if editable?
              (to_rich_cms_response(params) || {}).merge :__css_class__ => self.class.css_class, :__identifier__ => {:store_key => store_key}, :store_value => value
            else
              {}
            end
          end

          def to_rich_cms_response(params)
            # Override this in subclasses
          end

        private

          def render_collection(collection, tag, attrs)
            collection.collect do |entry|

              raise ArgumentError, "Expected at least one cmsable attribute for #{entry.class} (use attr_cmsable in class definitino)" if entry.class.attr_cmsables.empty?

              attributes = attrs.dup.tap do |hash|
                             hash[:mustache_locals] = (hash[:mustache_locals] || {}).stringify_keys.merge Hash[*entry.class.attr_cmsables.collect{|x| [x.to_s, entry.send(x)]}.flatten]
                           end

              tag_string tag, attributes

            end.join ""
          end

          def tag_string(tag, attrs)
            attributes = attrs.dup

            html       = if locals = attributes.delete(:mustache_locals)
                           attributes[:"data-mustache_locals"] = locals.collect{|key, value| "#{key}: \"#{value}\""}.join(", ") if editable?
                           parse_locals(derive_text, locals)
                         else
                           derive_text
                         end

            attributes = attributes.collect{|key, value| "#{key}=\"#{::ERB::Util.html_escape value}\""}.join(" ")

            "<#{[tag, (attributes unless attributes.empty?)].compact.join(" ")}>#{html}</#{tag}>"
          end

          def parse_locals(text, locals)
            Mustache.render derive_text, locals
          end

          def configuration
            self.class.send :configuration
          end
        end
      end
    end
  end
end
