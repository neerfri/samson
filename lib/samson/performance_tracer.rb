# frozen_string_literal: true

module Samson
  module PerformanceTracer
    def self.included(clazz)
      clazz.extend ClassMethods
    end

    # Common class methods for Newrelic and Datadog.
    module ClassMethods
      def add_method_tracers(*methods)
        Samson::Hooks.fire(:performance_tracer, self, methods)
      end
    end
  end
end
