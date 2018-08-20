# frozen_string_literal: true

if Samson::APM.enabled?

  Samson::APM::IGNORED_URLS = Set[
    '/ping',
    '/streams',
  ].freeze

  require 'ddtrace'
  Datadog.configure do |c|
    # Tracer
    c.tracer(
      hostname: Samson.statsd.host,
      tags: {
        env:                   ENV['RAILS_ENV'],
        pod:                   ENV['ZENDESK_POD_ID'],
        'application.version': "",
        'rails.version':       Rails.version,
        'ruby.version':        RUBY_VERSION
      }
    )

    c.use :rails,
      service_name: 'samson',
      controller_service: 'samson-rails-controller',
      cache_service: 'samson-cache',
      database_service: 'samson-mysql',
      distributed_tracing: true

    c.use :faraday, service_name: 'samson-faraday'
    c.use :dalli, service_name: 'samson-dalli'

    require 'aws-sdk-ecr'
    c.use :aws, service_name: 'samson-aws'
  end

  # Span Filters
  # Filter out the health checks, version checks, and diagnostics
  uninteresting_controller_filter = Datadog::Pipeline::SpanFilter.new do |span|
    span.name == 'rack.request' && Samson::APM::IGNORED_URLS.any? { |path| span.get_tag('http.url').include?(path) }
  end

  Datadog::Pipeline.before_flush(uninteresting_controller_filter)
end
