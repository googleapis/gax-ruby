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

class PagedEnumerableInvalidRequestTest < Minitest::Test
  def test_MissingPageTokenRequest
    request = Google::Gax::MissingPageTokenRequest.new
    response = Google::Gax::GoodPagedResponse.new
    options = Google::Gax::ApiCall::Options.new

    error = assert_raises ArgumentError do
      Google::Gax::PagedEnumerable.new(
        Object.new, :method_name, request, response, options
      )
    end
    exp_msg = "#{request.class} must have a page_token field (String)"
    assert_equal exp_msg, error.message
  end

  def test_MissingPageSizeRequest
    request = Google::Gax::MissingPageSizeRequest.new
    response = Google::Gax::GoodPagedResponse.new
    options = Google::Gax::ApiCall::Options.new

    error = assert_raises ArgumentError do
      Google::Gax::PagedEnumerable.new(
        Object.new, :method_name, request, response, options
      )
    end
    exp_msg = "#{request.class} must have a page_size field (Integer)"
    assert_equal exp_msg, error.message
  end
end