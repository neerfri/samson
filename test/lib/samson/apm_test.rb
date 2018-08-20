# frozen_string_literal: true

require_relative '../../test_helper'

SingleCov.covered!

describe Samson::APM do
  describe ".enabled?" do
    before(:all) do
      ENV.delete('ENABLE_DATADOG_APM')
    end
    context "in any environment" do
      it "is false by default" do
        with_env ENABLE_DATADOG_APM: nil do
          refute Samson::APM.enabled?
        end
      end

      it "is true when ENABLE_ZENDESK_APM env var is set" do
        with_env ENABLE_DATADOG_APM: "1" do
          assert Samson::APM.enabled?
        end
        with_env ENABLE_DATADOG_APM: nil do
          refute Samson::APM.enabled?
        end
      end
    end
  end

  module DDTracer
    def self.trace(*)
      yield
    end
  end

  module Datadog
    def self.tracer
      DDTracer
    end
  end

  class TestKlass1
    include Samson::APM
    Samson::APM.module_eval { include Datadog }

    def pub_method
      :pub
    end

    trace_method :pub_method
  end

  describe "skips APM trace methods" do
    let(:klass) { TestKlass1.new }
    it "skips tracker when apm is not enabled" do
      Datadog.expects(:tracer).never
      klass.send(:pub_method)
    end
  end

  ENV.store("ENABLE_DATADOG_APM", "1")
  class TestKlass2
    include Samson::APM
    Samson::APM.module_eval { include Datadog }

    def pub_method
      :pub
    end

    protected

    def pro_method
      :pro
    end

    private

    def pri_method
      :pri
    end

    trace_methods :pub_method, :pro_method, :not_method
    trace_method :pri_method
  end

  describe ".trace_method" do
    let(:apm) { TestKlass2.new }
    Datadog.expects(:tracer).returns(Datadog.tracer)

    it "wraps the private method in a trace call" do
      apm.send(:pri_method).must_equal(:pri)
    end

    it "wraps the public method in a trace call" do
      apm.send(:pub_method).must_equal(:pub)
    end

    it "raises with NoMethodError when undefined method call" do
      assert_raise NoMethodError do
        apm.send(:not_method)
      end
    end

    it "preserves method visibility" do
      assert apm.class.public_method_defined?(:pub_method)
      refute apm.class.public_method_defined?(:pri_method)
      assert apm.class.private_method_defined?(:pri_method)
    end
  end
end
