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

class ApiCallTest < Minitest::Test
  def test_call
    deadline_arg = nil

    api_meth_stub = proc do |deadline: nil, **_kwargs|
      deadline_arg = deadline
      OperationStub.new { 42 }
    end

    api_call = Google::Gax::ApiCall.new(api_meth_stub)

    assert_equal(42, api_call.call(Object.new))
    assert_kind_of(Time, deadline_arg)

    new_deadline = Time.now + 20
    options = Google::Gax::CallOptions.new(timeout: 20)

    assert_equal(42, api_call.call(Object.new, options: options))
    assert_in_delta(new_deadline, deadline_arg, 0.9)
  end

  def test_call_with_block
    adder = 0

    api_meth_stub = proc do |request, _deadline: nil, **_kwargs|
      assert_equal(3, request)
      OperationStub.new { 2 + request + adder }
    end

    api_call = Google::Gax::ApiCall.new(api_meth_stub)

    assert_equal(5, api_call.call(3))
    assert_equal(5, api_call.call(3, options: nil) { adder = 5 })
    assert_equal(10, api_call.call(3))
  end

  def test_with_routing_header
    metadata_arg = nil
    inner_stub = proc do |_, metadata: nil, **_deadline|
      metadata_arg = metadata
      42
    end

    api_meth_stub = proc do |request, **kwargs|
      OperationStub.new { inner_stub.call request, **kwargs }
    end

    params_extractor = proc do |request|
      { 'name' => request[:name], 'book.read' => request[:book][:read] }
    end

    api_call = Google::Gax::ApiCall.new(
      api_meth_stub, params_extractor: params_extractor
    )

    assert_equal(42, api_call.call(name: 'foo', book: { read: true }))
    assert_equal(
      { 'x-goog-request-params' => 'name=foo&book.read=true' },
      metadata_arg
    )
  end
end
