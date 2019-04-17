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

class ApiCallTest < Minitest::Test
  def test_call
    deadline_arg = nil

    api_meth_stub = proc do |deadline: nil, **_kwargs|
      deadline_arg = deadline
      OperationStub.new { 42 }
    end

    api_call = Google::Gax::ApiCall.new api_meth_stub

    assert_equal 42, api_call.call(Object.new)
    assert_kind_of Time, deadline_arg

    new_deadline = Time.now + 20
    options = Google::Gax::ApiCall::Options.new timeout: 20

    assert_equal 42, api_call.call(Object.new, options: options)
    assert_in_delta new_deadline, deadline_arg, 0.9
  end

  def test_call_with_format_response
    api_meth_stub = proc do |request, **_kwargs|
      assert_equal 3, request
      OperationStub.new { 2 + request }
    end

    format_response = ->(response) { response.to_s }
    api_call = Google::Gax::ApiCall.new api_meth_stub

    assert_equal 5, api_call.call(3)
    assert_equal "5", api_call.call(3, format_response: format_response)
    assert_equal 5, api_call.call(3)
  end

  def test_call_with_operation_callback
    adder = 0

    api_meth_stub = proc do |request, **_kwargs|
      assert_equal 3, request
      OperationStub.new { 2 + request + adder }
    end

    increment_addr = ->(*args) { adder = 5 }
    api_call = Google::Gax::ApiCall.new api_meth_stub

    assert_equal 5, api_call.call(3)
    assert_equal 5, api_call.call(3, operation_callback: increment_addr)
    assert_equal 10, api_call.call(3)
  end

  def test_call_with_format_response_and_operation_callback
    adder = 0

    api_meth_stub = proc do |request, **_kwargs|
      assert_equal 3, request
      OperationStub.new { 2 + request + adder }
    end

    format_response = ->(response) { response.to_s }
    increment_addr = ->(*args) { adder = 5 }
    api_call = Google::Gax::ApiCall.new api_meth_stub

    assert_equal 5, api_call.call(3)
    assert_equal "5", api_call.call(3, format_response: format_response, operation_callback: increment_addr)
    assert_equal 10, api_call.call(3)
    assert_equal "10", api_call.call(3, format_response: format_response, operation_callback: increment_addr)
    assert_equal 10, api_call.call(3)
  end

  def test_call_with_stream_callback
    all_responses = []

    api_meth_stub = proc do |requests, **_kwargs, &block|
      assert_kind_of Enumerable, requests
      OperationStub.new { requests.each(&block) }
    end

    collect_response = ->(response) { all_responses << response }
    api_call = Google::Gax::ApiCall.new api_meth_stub

    api_call.call([:foo, :bar, :baz].to_enum, stream_callback: collect_response)
    wait_until { all_responses == [:foo, :bar, :baz] }
    assert_equal [:foo, :bar, :baz], all_responses
    api_call.call([:qux, :quux, :quuz].to_enum, stream_callback: collect_response)
    wait_until { all_responses == [:foo, :bar, :baz, :qux, :quux, :quuz] }
    assert_equal [:foo, :bar, :baz, :qux, :quux, :quuz], all_responses
  end

  def test_call_with_stream_callback_and_format_response
    all_responses = []

    api_meth_stub = proc do |requests, **_kwargs, &block|
      assert_kind_of Enumerable, requests
      OperationStub.new { requests.each(&block) }
    end

    collect_response = ->(response) { all_responses << response }
    format_response = ->(response) { response.to_s }
    api_call = Google::Gax::ApiCall.new api_meth_stub

    api_call.call([:foo, :bar, :baz].to_enum, stream_callback: collect_response)
    wait_until { all_responses == [:foo, :bar, :baz] }
    assert_equal [:foo, :bar, :baz], all_responses
    api_call.call([:qux, :quux, :quuz].to_enum, stream_callback: collect_response, format_response: format_response)
    wait_until { all_responses == [:foo, :bar, :baz, "qux", "quux", "quuz"] }
    assert_equal [:foo, :bar, :baz, "qux", "quux", "quuz"], all_responses
  end

  def test_stream_without_stream_callback_and_format_response
    all_responses = []

    api_meth_stub = proc do |requests, **_kwargs, &block|
      assert_kind_of Enumerable, requests
      OperationStub.new { requests.each(&block) }
    end

    api_call = Google::Gax::ApiCall.new api_meth_stub

    responses = api_call.call [:foo, :bar, :baz].to_enum
    assert_kind_of Enumerable, responses
    all_responses += responses.to_a
    assert_equal [:foo, :bar, :baz], all_responses

    responses = api_call.call [:qux, :quux, :quuz].to_enum
    assert_kind_of Enumerable, responses
    all_responses += responses.to_a
    assert_equal [:foo, :bar, :baz, :qux, :quux, :quuz], all_responses
  end

  def test_stream_without_stream_callback_but_format_response
    all_responses = []

    api_meth_stub = proc do |requests, **_kwargs, &block|
      assert_kind_of Enumerable, requests
      OperationStub.new { requests.each(&block) }
    end

    format_responses = ->(responses) { responses.lazy.map(&:to_s) }
    api_call = Google::Gax::ApiCall.new api_meth_stub

    responses = api_call.call [:foo, :bar, :baz].to_enum
    assert_kind_of Enumerable, responses
    all_responses += responses.to_a
    assert_equal [:foo, :bar, :baz], all_responses

    responses = api_call.call [:qux, :quux, :quuz].to_enum, format_response: format_responses
    assert_kind_of Enumerable, responses
    all_responses += responses.to_a
    assert_equal [:foo, :bar, :baz, "qux", "quux", "quuz"], all_responses
  end

  ##
  # This is an ugly way to block on concurrent criteria, but it works...
  def wait_until iterations = 100
    count = 0
    loop do
      raise "criteria not met" if count >= iterations
      break if yield
      sleep 0.0001
      count += 1
    end
  end
end
