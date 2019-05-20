# Copyright 2019, Google LLC
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google LLC nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "test_helper"

require "google/gax/config"
require "google/gax/config/method"

class ServiceConfig
  extend Google::Gax::Config

  config_attr :host,         "localhost", String
  config_attr :port,         443,         Integer
  config_attr :timeout,      60,          Numeric, nil
  config_attr :metadata,     nil,         Hash, nil
  config_attr :retry_policy, nil,         Hash, Proc, nil

  attr_reader :rpc_method

  def initialize parent_config = nil
    @parent_config = parent_config unless parent_config.nil?
    @rpc_method = Google::Gax::Config::Method.new parent_config&.rpc_method

    yield self if block_given?
  end
end

class MethodConfigTest < Minitest::Test
  def test_rpc_method
    config = ServiceConfig.new

    assert_equal "localhost", config.host
    assert_equal 443,         config.port
    assert_equal 60,          config.timeout
    assert_nil config.metadata
    assert_nil config.retry_policy

    assert_nil config.rpc_method.timeout
    assert_nil config.rpc_method.metadata
    assert_nil config.rpc_method.retry_policy

    config.rpc_method.timeout = 120
    config.rpc_method.metadata = { header: "value" }
    config.rpc_method.retry_policy = { initial_delay: 15 }

    assert_equal 120, config.rpc_method.timeout
    assert_equal({ header: "value" }, config.rpc_method.metadata)
    assert_equal({ initial_delay: 15 }, config.rpc_method.retry_policy)

    config.rpc_method.retry_policy = ->(error) { true }
    assert_kind_of Proc, config.rpc_method.retry_policy

    config.rpc_method.timeout = nil
    config.rpc_method.metadata = nil
    config.rpc_method.retry_policy = nil

    assert_nil config.rpc_method.timeout
    assert_nil config.rpc_method.metadata
    assert_nil config.rpc_method.retry_policy
  end

  def test_rpc_method_validation
    config = ServiceConfig.new

    assert_raises ArgumentError do
      config.rpc_method.timeout = "60"
    end

    assert_raises ArgumentError do
      config.rpc_method.metadata = ["header", "value"]
    end

    assert_raises ArgumentError do
      config.rpc_method.retry_policy = Google::Gax::ApiCall::RetryPolicy.new
    end
  end

  def test_nested
    parent_config = ServiceConfig.new do |parent|
      parent.rpc_method.timeout = 120
      parent.rpc_method.metadata = { header: "value" }
      parent.rpc_method.retry_policy = { initial_delay: 15 }
    end
    config = ServiceConfig.new parent_config

    assert_equal "localhost", config.host
    assert_equal 443,         config.port
    assert_equal 60,          config.timeout

    assert_equal 120, config.rpc_method.timeout
    assert_equal({ header: "value" }, config.rpc_method.metadata)
    assert_equal({ initial_delay: 15 }, config.rpc_method.retry_policy)

    config.rpc_method.timeout = 90
    config.rpc_method.metadata = { x_header: "another value" }
    config.rpc_method.retry_policy = { initial_delay: 30 }

    assert_equal 90, config.rpc_method.timeout
    assert_equal({ x_header: "another value" }, config.rpc_method.metadata)
    assert_equal({ initial_delay: 30 }, config.rpc_method.retry_policy)

    config.rpc_method.retry_policy = ->(error) { true }
    assert_kind_of Proc, config.rpc_method.retry_policy

    config.rpc_method.timeout = nil
    config.rpc_method.metadata = nil
    config.rpc_method.retry_policy = nil

    assert_equal 120, config.rpc_method.timeout
    assert_equal({ header: "value" }, config.rpc_method.metadata)
    assert_equal({ initial_delay: 15 }, config.rpc_method.retry_policy)

    parent_config.rpc_method.timeout = nil
    parent_config.rpc_method.metadata = nil
    parent_config.rpc_method.retry_policy = nil

    assert_nil parent_config.rpc_method.timeout
    assert_nil parent_config.rpc_method.metadata
    assert_nil parent_config.rpc_method.retry_policy
  end

  def test_nested_validation
    parent_config = ServiceConfig.new do |parent|
      parent.rpc_method.timeout = 120
      parent.rpc_method.metadata = { header: "value" }
      parent.rpc_method.retry_policy = { initial_delay: 15 }
    end
    config = ServiceConfig.new parent_config

    assert_raises ArgumentError do
      config.rpc_method.timeout = "60"
    end

    assert_raises ArgumentError do
      config.rpc_method.metadata = ["header", "value"]
    end

    assert_raises ArgumentError do
      config.rpc_method.retry_policy = Google::Gax::ApiCall::RetryPolicy.new
    end
  end
end
