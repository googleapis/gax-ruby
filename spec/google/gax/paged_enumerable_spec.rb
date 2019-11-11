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

require 'google/gax'
require 'spec/fixtures/fixture_pb'

describe Google::Gax::PagedEnumerable do
  it 'enumerates all resources' do
    api_responses = [
      Google::Protobuf::GoodPagedResponse.new(
        users: [
          Google::Protobuf::User.new(name: 'foo'),
          Google::Protobuf::User.new(name: 'bar')
        ],
        next_page_token: 'next'
      ),
      Google::Protobuf::GoodPagedResponse.new(
        users: [
          Google::Protobuf::User.new(name: 'baz'),
          Google::Protobuf::User.new(name: 'bif')
        ]
      )
    ]
    paged_enum = Google::Gax::PagedEnumerable.new(
      'page_token', 'next_page_token', 'users'
    )
    api_call = lambda do |_req, _blk = nil|
      api_responses.shift
    end
    request = Google::Protobuf::GoodPagedRequest.new
    fake_settings = OpenStruct.new(page_token: nil)
    paged_enum.start(api_call, request, fake_settings, nil)

    exp_names = []
    paged_enum.each do |user|
      exp_names << user.name
    end
    expect(exp_names).to eq(%w[foo bar baz bif])
  end

  it 'enumerates all pages' do
    api_responses = [
      Google::Protobuf::GoodPagedResponse.new(
        users: [
          Google::Protobuf::User.new(name: 'foo'),
          Google::Protobuf::User.new(name: 'bar')
        ],
        next_page_token: 'next'
      ),
      Google::Protobuf::GoodPagedResponse.new(
        users: [
          Google::Protobuf::User.new(name: 'baz'),
          Google::Protobuf::User.new(name: 'bif')
        ]
      )
    ]
    paged_enum = Google::Gax::PagedEnumerable.new(
      'page_token', 'next_page_token', 'users'
    )
    api_call = lambda do |_req, _blk = nil|
      api_responses.shift
    end
    request = Google::Protobuf::GoodPagedRequest.new
    fake_settings = OpenStruct.new(page_token: nil)
    paged_enum.start(api_call, request, fake_settings, nil)

    exp_names = []
    paged_enum.each_page do |page|
      exp_page_names = []
      page.each do |user|
        exp_page_names << user.name
      end
      exp_names << exp_page_names
    end
    expect(exp_names).to eq([%w[foo bar], %w[baz bif]])
  end
end
