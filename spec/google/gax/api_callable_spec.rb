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

class CustomException < StandardError
  attr_reader :code

  def initialize(msg, code)
    super(msg)
    @code = code
  end
end

FAKE_STATUS_CODE_1 = 1
FAKE_STATUS_CODE_2 = 2

# Google::Gax::CallSettings is private, only accessible in the module context.
# For testing purpose, this makes a toplevel ::CallSettings point to the same
# class.
module Google
  module Gax
    ::CallSettings = CallSettings
  end
end

describe Google::Gax do
  describe 'create_api_call' do
    it 'calls api call' do
      settings = CallSettings.new
      deadline_arg = nil

      op = double('op')
      allow(op).to receive(:execute) { 42 }

      func = proc do |deadline: nil, **_kwargs|
        deadline_arg = deadline
        op
      end

      my_callable = Google::Gax.create_api_call(func, settings)
      expect(my_callable.call(nil)).to eq(42)
      expect(deadline_arg).to be_a(Time)

      new_deadline = Time.now + 20
      options = Google::Gax::CallOptions.new(timeout: 20)
      expect(my_callable.call(nil, options)).to eq(42)
      expect(deadline_arg).to be_within(0.9).of(new_deadline)
    end
  end

  describe 'create_api_call with block options' do
    it 'calls with block' do
      adder = 0
      settings = CallSettings.new

      op = double('op', request: 3)
      allow(op).to receive(:execute) { 2 + op.request + adder }

      func = proc do |request, _deadline: nil, **_kwargs|
        expect(request).to eq(3)
        op
      end

      my_callable = Google::Gax.create_api_call(func, settings)
      expect(my_callable.call(3)).to eq(5)
      expect(my_callable.call(3) { adder = 5 }).to eq(5)
      expect(my_callable.call(3)).to eq(10)
    end
  end

  describe 'custom exceptions' do
    it 'traps an exception' do
      settings = CallSettings.new

      transformer = proc do |ex|
        expect(ex).to be_a(Google::Gax::RetryError)
        raise CustomException.new('', FAKE_STATUS_CODE_2)
      end

      func = proc do
        raise Google::Gax::RetryError.new('')
      end
      my_callable = Google::Gax.create_api_call(
        func, settings, exception_transformer: transformer
      )
      expect { my_callable.call }.to raise_error(CustomException)
    end

    it 'traps a wrapped exception' do
      settings = CallSettings.new(errors: [CustomException])

      transformer = proc do |ex|
        expect(ex).to be_a(Google::Gax::GaxError)
        raise Exception.new('')
      end

      func = proc do
        raise CustomException.new('', :FAKE_STATUS_CODE_1)
      end
      my_callable = Google::Gax.create_api_call(
        func, settings, exception_transformer: transformer
      )
      expect { my_callable.call }.to raise_error(Exception)
    end
  end

  describe 'failures without retry' do
    it 'simply fails' do
      settings = CallSettings.new(errors: [CustomException])
      deadline_arg = nil
      call_count = 0
      func = proc do |deadline: nil, **_kwargs|
        deadline_arg = deadline
        call_count += 1
        raise CustomException.new('', FAKE_STATUS_CODE_1)
      end
      my_callable = Google::Gax.create_api_call(func, settings)
      begin
        my_callable.call
        expect(true).to be false # should not reach to this line.
      rescue Google::Gax::GaxError => exc
        expect(exc.cause).to be_a(CustomException)
      end
      expect(deadline_arg).to be_a(Time)
      expect(call_count).to eq(1)
    end

    it 'does not wrap unknown errors' do
      settings = CallSettings.new
      deadline_arg = nil
      call_count = 0
      func = proc do |deadline: nil, **_kwargs|
        deadline_arg = deadline
        call_count += 1
        raise CustomException.new('', FAKE_STATUS_CODE_1)
      end
      my_callable = Google::Gax.create_api_call(func, settings)
      expect { my_callable.call }.to raise_error(CustomException)
      expect(deadline_arg).to be_a(Time)
      expect(call_count).to eq(1)
    end
  end

  describe 'with_routing_header' do
    it 'merges request header params with the existing settings' do
      settings = CallSettings.new
      metadata_arg = nil
      func = proc do |_, metadata: nil, **_deadline|
        metadata_arg = metadata
        42
      end
      func2 = proc do |request, **kwargs|
        op = double('op')
        allow(op).to receive(:execute) { func.call(request, **kwargs) }
        op
      end
      params_extractor = proc do |request|
        { 'name' => request[:name], 'book.read' => request[:book][:read] }
      end
      my_callable = Google::Gax.create_api_call(
        func2, settings, params_extractor: params_extractor
      )
      expect(my_callable.call(name: 'foo', book: { read: true })).to eq(42)
      expect(metadata_arg).to eq(
        'x-goog-request-params' => 'name=foo&book.read=true'
      )
    end
  end
end
