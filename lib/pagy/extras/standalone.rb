# See the Pagy documentation: https://ddnexus.github.io/pagy/extras/standalone
# frozen_string_literal: true

require 'uri'

class Pagy # :nodoc:
  # Use pagy without any request object, nor Rack environment/gem, nor any defined params method,
  # even in the irb/rails console without any app or config.
  module StandaloneExtra
    # Extracted from Rack::Utils and reformatted for rubocop
    module QueryUtils
      module_function

      def escape(str)
        URI.encode_www_form_component(str)
      end

      def build_nested_query(value, prefix = nil)
        case value
        when Array
          value.map { |v| build_nested_query(v, "#{prefix}[]") }.join('&')
        when Hash
          value.map do |k, v|
            build_nested_query(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
          end.delete_if(&:empty?).join('&')
        when nil
          prefix
        else
          raise ArgumentError, 'value must be a Hash' if prefix.nil?

          "#{prefix}=#{escape(value)}"
        end
      end
    end

    # Return the URL for the page. If there is no pagy.vars[:url]
    # it works exactly as the regular #pagy_url_for, relying on the params method and Rack.
    # If there is a defined pagy.vars[:url] variable it does not need the params method nor Rack.
    def pagy_url_for(pagy, page, absolute: nil)
      vars = pagy.vars
      return super unless (url = vars[:url])

      params                     = vars[:params].clone  # safe when it gets reused
      params[vars[:page_param]]  = page
      params[vars[:items_param]] = vars[:items] if vars[:items_extra]

      query_string = "?#{QueryUtils.build_nested_query(pagy_massage_params(params))}"
      "#{url}#{query_string}#{vars[:fragment]}"
    end
  end
  # In ruby 3+ `UrlHelpers.prepend StandaloneExtra` would be enough instead of using the next 2 lines
  Frontend.prepend StandaloneExtra
  Backend.prepend StandaloneExtra

  # Define a dummy params method if it's not already defined in the including module
  module Backend
    def self.included(controller)
      controller.define_method(:params) { {} } unless controller.method_defined?(:params)
    end
  end
end
