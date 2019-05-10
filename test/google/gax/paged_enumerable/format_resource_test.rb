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

describe Google::Gax::PagedEnumerable, :format_resource do
  it "enumerates all resources and formats them" do
    api_responses = [
      Google::Gax::GoodPagedResponse.new(
        users: [
          Google::Gax::User.new(name: "baz"),
          Google::Gax::User.new(name: "bif")
        ]
      )
    ]
    api_call = ->(_req, _opt) { api_responses.shift }
    request = Google::Gax::GoodPagedRequest.new
    response = Google::Gax::GoodPagedResponse.new(
      users:           [
        Google::Gax::User.new(name: "foo"),
        Google::Gax::User.new(name: "bar")
      ],
      next_page_token: "next"
    )
    options = Google::Gax::ApiCall::Options.new
    upcase_resource = ->(user) { user.name.upcase }
    paged_enum = Google::Gax::PagedEnumerable.new(
      api_call, request, response, options, format_resource: upcase_resource
    )

    assert_equal ["FOO", "BAR", "BAZ", "BIF"], paged_enum.each.to_a
  end

  it "enumerates all pages and formats the resources" do
    api_responses = [
      Google::Gax::GoodPagedResponse.new(
        users: [
          Google::Gax::User.new(name: "baz"),
          Google::Gax::User.new(name: "bif")
        ]
      )
    ]
    api_call = ->(_req, _opt) { api_responses.shift }
    request = Google::Gax::GoodPagedRequest.new
    response = Google::Gax::GoodPagedResponse.new(
      users:           [
        Google::Gax::User.new(name: "foo"),
        Google::Gax::User.new(name: "bar")
      ],
      next_page_token: "next"
    )
    options = Google::Gax::ApiCall::Options.new
    upcase_resource = ->(str) { str.upcase }
    paged_enum = Google::Gax::PagedEnumerable.new(
      api_call, request, response, options, format_resource: upcase_resource
    )

    page_proc = ->(page) { page.each.map(&:name) }
    assert_equal [["foo", "bar"], ["baz", "bif"]], paged_enum.each_page.map(&page_proc)
  end
end
