# Copyright 2019, Google Inc.
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
#     * Neither the name of Google Inc. nor the names of its
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

class ApiCallRetryTest < Minitest::Test
  def default_sleep_counts
    [
      1, 1.3, 1.6900000000000002, 2.1970000000000005, 2.856100000000001,
      3.7129300000000014, 4.826809000000002, 6.274851700000003,
      8.157307210000004,  10.604499373000007, 13.785849184900009
    ]
  end

  def test_retries_with_exponential_backoff
    inner_attempts = 0
    deadline_arg = nil

    inner_responses = Array.new 4 do
      GRPC::Unavailable.new "unavailable"
    end
    inner_responses += [1729]
    inner_stub = proc do |deadline: nil, **_kwargs|
      deadline_arg = deadline
      inner_attempts += 1
      inner_response = inner_responses.shift

      raise inner_response if inner_response.is_a? Exception

      inner_response
    end

    api_meth_stub = proc do |request, **kwargs|
      OperationStub.new { inner_stub.call(request, **kwargs) }
    end

    api_call = Google::Gax::ApiCall.new api_meth_stub
    options = Google::Gax::ApiCall::Options.new(
      retry_policy: { retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE] }
    )

    sleep_mock = Minitest::Mock.new
    default_sleep_counts[0, 4].each do |sleep_count|
      sleep_mock.expect :sleep, nil, [sleep_count]
    end
    sleep_proc = ->(count) { sleep_mock.sleep count }

    time_now = Time.now
    Time.stub :now, time_now do
      Kernel.stub :sleep, sleep_proc do
        assert_equal 1729, api_call.call(Object.new, options: options)
        assert_equal 5, inner_attempts
        assert_equal time_now + 300, deadline_arg
      end
    end

    sleep_mock.verify
  end

  def test_retries_with_custom_policy
    inner_responses = Array.new 4 do
      GRPC::Unavailable.new "unavailable"
    end
    inner_responses += [1729]
    inner_stub = proc do |**_kwargs|
      inner_response = inner_responses.shift

      raise inner_response if inner_response.is_a? Exception

      inner_response
    end

    api_meth_stub = proc do |request, **kwargs|
      OperationStub.new { inner_stub.call(request, **kwargs) }
    end

    api_call = Google::Gax::ApiCall.new api_meth_stub
    custom_policy_count = 0
    custom_policy_sleep = [15, 12, 24, 21]
    custom_policy = lambda do |_error|
      custom_policy_count += 1
      delay = custom_policy_sleep.shift
      if delay
        Kernel.sleep delay
        true
      else
        false
      end
    end
    options = Google::Gax::ApiCall::Options.new retry_policy: custom_policy

    sleep_mock = Minitest::Mock.new
    custom_policy_sleep.each do |sleep_count|
      sleep_mock.expect :sleep, nil, [sleep_count]
    end
    sleep_proc = ->(count) { sleep_mock.sleep count }

    Kernel.stub :sleep, sleep_proc do
      assert_equal 1729, api_call.call(Object.new, options: options)

      assert_equal 4, custom_policy_count
    end

    sleep_mock.verify
  end
end
