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

require 'test_helper'

class ApiCallRetryTest < Minitest::Test
  def test_no_retry_without_codes
    call_count = 0
    api_meth_stub = proc do
      call_count += 1
      raise GRPC::BadStatus.new(FAKE_STATUS_CODE_1, 'unknown')
    end

    api_call = Google::Gax::ApiCall.new(api_meth_stub)

    assert_raises Google::Gax::GaxError do
      api_call.call Object.new
    end
    assert_equal(1, call_count)
  end

  def test_aborts_retries
    api_meth_stub = proc do
      raise GRPC::BadStatus.new(FAKE_STATUS_CODE_1, 'unknown')
    end
    api_call = Google::Gax::ApiCall.new(api_meth_stub)

    exc = assert_raises Google::Gax::GaxError do
      api_call.call Object.new
      raise 'This will never be reached'
    end
    assert_kind_of(GRPC::BadStatus, exc.cause)
  end

  def test_times_out
    to_attempt = 5
    call_count = 0
    deadline_arg = nil

    api_meth_stub = proc do |deadline: nil, **_kwargs|
      deadline_arg = deadline
      call_count += 1
      raise GRPC::BadStatus.new(FAKE_STATUS_CODE_1, 'unknown')
    end

    api_call = Google::Gax::ApiCall.new(api_meth_stub)
    options = Google::Gax::CallOptions.new(
      retry_policy: { retry_codes: [14, 101] }
    )

    time_now = Time.now
    time_proc = lambda do
      delay = 60
      time_dup = time_now
      time_now += delay
      time_dup
    end

    sleep_mock = Minitest::Mock.new
    sleep_mock.expect :sleep, nil, [1]
    sleep_mock.expect :sleep, nil, [1 * 1.3]
    sleep_mock.expect :sleep, nil, [1 * 1.3 * 1.3]
    sleep_mock.expect :sleep, nil, [1 * 1.3 * 1.3 * 1.3]
    sleep_proc = ->(count) { sleep_mock.sleep count }

    Kernel.stub :sleep, sleep_proc do
      Time.stub :now, time_proc do
        exc = assert_raises Google::Gax::GaxError do
          api_call.call Object.new, options: options
          raise 'This will never be reached'
        end
        assert_kind_of(GRPC::BadStatus, exc.cause)

        assert_equal(time_now - 60, deadline_arg)
        assert_equal(to_attempt, call_count)
      end
    end

    sleep_mock.verify
  end

  def test_aborts_on_unexpected_exception
    call_count = 0

    api_meth_stub = proc do
      call_count += 1
      raise NonCodeError.new('')
    end

    api_call = Google::Gax::ApiCall.new(api_meth_stub)

    assert_raises NonCodeError do
      api_call.call(Object.new)
      raise 'This will never be reached'
    end
    assert_equal(1, call_count)
  end

  def test_no_retry_when_no_responses
    inner_stub = proc { nil }

    api_meth_stub = proc do |request, **kwargs|
      OperationStub.new { inner_stub.call(request, **kwargs) }
    end

    api_call = Google::Gax::ApiCall.new(api_meth_stub)

    assert_nil(api_call.call(Object.new))
  end
end
