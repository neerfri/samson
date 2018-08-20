# frozen_string_literal: true
# require 'ddtrace'
module Samson
  module APM
    def self.included(clazz)
      clazz.extend ClassMethods
    end

    class << self
      def enabled?
        !!ENV['ENABLE_DATADOG_APM']
      end
    end

    module ClassMethods
      def trace_methods(*methods)
        Array(methods).each { |m| trace_method(m) }
      end

      def trace_method(method)
        return unless Samson::APM.enabled?

        @__apm_module ||= begin
          mod = Module.new
          mod.extend(Samson::APM::Helpers)
          prepend(mod)
          mod
        end
        if method_defined?(method) || private_method_defined?(method)
          _add_wrapped_method_to_module(method)
        end

        @__traced_methods ||= []
        @__traced_methods << method
      end

      private

      def _add_wrapped_method_to_module(method)
        klass = self

        @__apm_module.module_eval do
          _wrap_method(method, klass)
        end
      end
    end

    module Helpers
      private

      def _wrap_method(method, klass)
        visibility = _original_visibility(method, klass)
        _define_traced_method(method, "#{klass}##{method}")
        _set_visibility(method, visibility)
      end

      def _original_visibility(method, klass)
        if klass.protected_method_defined?(method)
          :protected
        elsif klass.private_method_defined?(method)
          :private
        else
          :public
        end
      end

      def _define_traced_method(method, trace_name)
        define_method(method) do |*args, &block|
          Datadog.tracer.trace(trace_name) do
            super(*args, &block)
          end
        end
      end

      def _set_visibility(method, visibility)
        case visibility
        when :protected
          protected(method)
        when :private
          private(method)
        else
          public(method)
        end
      end
    end
  end
end
