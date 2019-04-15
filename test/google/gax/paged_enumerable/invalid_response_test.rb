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

class PagedEnumerableInvalidResponseTest < Minitest::Test
  def test_MissingRepeatedResponse
    api_call = -> {}
    request = Google::Gax::GoodPagedRequest.new
    response = Google::Gax::MissingRepeatedResponse.new
    options = Google::Gax::CallOptions.new

    error = assert_raises ArgumentError do
      Google::Gax::PagedEnumerable.new(
        api_call, request, response, options
      )
    end
    exp_msg = "#{response.class} must have one repeated field"
    assert_equal exp_msg, error.message
  end

  def test_MissingMessageResponse
    api_call = -> {}
    request = Google::Gax::GoodPagedRequest.new
    response = Google::Gax::MissingMessageResponse.new
    options = Google::Gax::CallOptions.new

    error = assert_raises ArgumentError do
      Google::Gax::PagedEnumerable.new(
        api_call, request, response, options
      )
    end
    exp_msg = "#{response.class} must have one repeated field"
    assert_equal exp_msg, error.message
  end

  def test_MissingNextPageTokenResponse
    api_call = -> {}
    request = Google::Gax::GoodPagedRequest.new
    response = Google::Gax::MissingNextPageTokenResponse.new
    options = Google::Gax::CallOptions.new

    error = assert_raises ArgumentError do
      Google::Gax::PagedEnumerable.new(
        api_call, request, response, options
      )
    end
    exp_msg = "#{response.class} must have a next_page_token field (String)"
    assert_equal exp_msg, error.message
  end

  def test_BadMessageOrderResponse
    skip "Looks like fields are already sorted by number, not proto order"

    api_call = -> {}
    request = Google::Gax::GoodPagedRequest.new
    response = Google::Gax::BadMessageOrderResponse.new
    options = Google::Gax::CallOptions.new

    error = assert_raises ArgumentError do
      Google::Gax::PagedEnumerable.new(
        api_call, request, response, options
      )
    end
    exp_msg = "#{response.class} must have one primary repeated field " \
      "by both position and number"
    assert_equal exp_msg, error.message
  end
end
