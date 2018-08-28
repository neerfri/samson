# frozen_string_literal: true

module SamsonDatadogTracer
  class Engine < Rails::Engine
  end

  KEY = ENV['DATADOG_APM_TRACER'].presence

  def self.enabled?
    KEY
  end
end

Samson::Hooks.callback :performance_tracer do |klass, methods|
  if SamsonDatadogTracer.enabled?
    klass.class_eval do
      include SamsonDatadogTracer::APM
      trace_methods methods
    end
  end
end
