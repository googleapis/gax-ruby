# Copyright 2016, Google Inc.
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
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'google/gax/api_callable'
require 'google/gax'

class PageStreamingRequest
  attr_accessor :page_token

  def initialize(page_token: 0)
    @page_token = page_token
  end
end

class PageStreamingResponse
  attr_reader :nums
  attr_accessor :next_page_token

  def initialize(nums:[], next_page_token:nil)
    @nums = nums
    @next_page_token = next_page_token
  end
end

describe Google::Gax do
  CallSettings = Google::Gax::CallSettings

  it 'calls api call' do
    settings = CallSettings.new
    func = proc do
      42
    end
    my_callable = Google::Gax.create_api_call(func, settings)
    expect(my_callable.call(nil)).to eq(42)
  end

  it 'returns page-streamable' do
    page_size = 3
    pages_to_stream = 5

    page_descriptor = Google::Gax::PageDescriptor.new(
      :page_token, :next_page_token, :nums)
    settings = CallSettings.new(page_descriptor: page_descriptor)
    func = proc do |request|
      if request.page_token > 0 &&
         request.page_token < page_size * pages_to_stream
        PageStreamingResponse.new(
          nums: (request.page_token...(request.page_token + page_size)),
          next_page_token: request.page_token + page_size)
      elsif request.page_token >= page_size * pages_to_stream
        PageStreamingResponse.new
      else
        PageStreamingResponse.new(nums: 0...page_size,
                                  next_page_token: page_size)
      end
    end
    my_callable = Google::Gax.create_api_call(func, settings)
    expect(my_callable.call(PageStreamingRequest.new).to_a).to eq(
      (0...(page_size * pages_to_stream)).to_a)
  end
end
