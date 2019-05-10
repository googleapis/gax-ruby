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

class RetryPolicySettingsTest < Minitest::Test
  def test_defaults
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new

    assert_equal [], retry_policy.retry_codes
    assert_equal 1, retry_policy.initial_delay
    assert_equal 1.3, retry_policy.multiplier
    assert_equal 15, retry_policy.max_delay
  end

  def test_apply_defaults_overrides_default_values
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new
    retry_policy.apply_defaults(
      retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE],
      initial_delay: 4, multiplier: 5, max_delay: 6
    )

    assert_equal(
      [GRPC::Core::StatusCodes::UNAVAILABLE],
      retry_policy.retry_codes
    )
    assert_equal 4, retry_policy.initial_delay
    assert_equal 5, retry_policy.multiplier
    assert_equal 6, retry_policy.max_delay
  end

  def test_overrides_default_values
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new(
      retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE],
      initial_delay: 4, multiplier: 5, max_delay: 6
    )

    assert_equal(
      [GRPC::Core::StatusCodes::UNAVAILABLE],
      retry_policy.retry_codes
    )
    assert_equal 4, retry_policy.initial_delay
    assert_equal 5, retry_policy.multiplier
    assert_equal 6, retry_policy.max_delay
  end

  def test_apply_defaults_wont_override_custom_values
    retry_policy = Google::Gax::ApiCall::RetryPolicy.new(
      retry_codes: [GRPC::Core::StatusCodes::UNIMPLEMENTED],
      initial_delay: 7, multiplier: 6, max_delay: 5
    )
    retry_policy.apply_defaults(
      retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE],
      initial_delay: 4, multiplier: 5, max_delay: 6
    )

    assert_equal(
      [GRPC::Core::StatusCodes::UNIMPLEMENTED],
      retry_policy.retry_codes
    )
    assert_equal 7, retry_policy.initial_delay
    assert_equal 6, retry_policy.multiplier
    assert_equal 5, retry_policy.max_delay
  end
end
