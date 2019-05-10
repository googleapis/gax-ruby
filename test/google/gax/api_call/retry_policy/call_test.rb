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

class RetryPolicyCallTest < Minitest::Test
  def test_wont_retry_when_unconfigured
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new
    grpc_error = GRPC::Unavailable.new

    refute_includes retry_policy.retry_codes, grpc_error.code

    sleep_proc = ->(_count) { raise "must not call sleep" }

    Kernel.stub :sleep, sleep_proc do
      refute retry_policy.call(grpc_error)
    end
  end

  def test_retries_configured_grpc_errors
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new(
      retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE]
    )
    grpc_error = GRPC::Unavailable.new

    assert_includes retry_policy.retry_codes, grpc_error.code

    sleep_mock = Minitest::Mock.new
    sleep_mock.expect :sleep, nil, [1]
    sleep_proc = ->(count) { sleep_mock.sleep count }

    Kernel.stub :sleep, sleep_proc do
      assert retry_policy.call(grpc_error)
    end

    sleep_mock.verify
  end

  def test_wont_retry_unconfigured_grpc_errors
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new(
      retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE]
    )
    grpc_error = GRPC::Unimplemented.new

    refute_includes retry_policy.retry_codes, grpc_error.code

    sleep_proc = ->(_count) { raise "must not call sleep" }

    Kernel.stub :sleep, sleep_proc do
      refute retry_policy.call(grpc_error)
    end
  end

  def test_wont_retry_non_grpc_errors
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new(
      retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE]
    )
    other_error = StandardError.new

    sleep_proc = ->(_count) { raise "must not call sleep" }

    Kernel.stub :sleep, sleep_proc do
      refute retry_policy.call(other_error)
    end
  end

  def test_incremental_backoff
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new(
      retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE]
    )
    grpc_error = GRPC::Unavailable.new

    assert_includes retry_policy.retry_codes, grpc_error.code

    sleep_counts = [
      1, 1.3, 1.6900000000000002, 2.1970000000000005, 2.856100000000001,
      3.7129300000000014, 4.826809000000002, 6.274851700000003,
      8.157307210000004,  10.604499373000007, 13.785849184900009, 15, 15
    ]

    sleep_mock = Minitest::Mock.new
    sleep_counts.each do |sleep_count|
      sleep_mock.expect :sleep, nil, [sleep_count]
    end
    sleep_proc = ->(count) { sleep_mock.sleep count }

    Kernel.stub :sleep, sleep_proc do
      sleep_counts.count.times do
        assert retry_policy.call(grpc_error)
      end
    end

    sleep_mock.verify
  end
end
