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

require 'google/gax/operation'
require 'google/gax/settings'
require 'google/protobuf/any_pb'
require 'google/protobuf/well_known_types'
require 'google/rpc/status_pb'
require 'google/longrunning/operations_pb'

GrpcOp = Google::Longrunning::Operation
GaxOp = Google::Gax::Operation

class MockLroClient
  def initialize(get_method: nil, cancel_method: nil)
    @get_method = get_method
    @cancel_method = cancel_method
  end

  def get_operation(grpc_method, options: nil)
    @get_method.call(grpc_method, options)
  end

  def cancel_operation(name)
    @cancel_method.call(name)
  end
end

def create_op(operation, client: nil)
  GaxOp.new(operation, client: client ? client : DONE_ON_GET_CLIENT)
end

describe Google::Gax::Operation do
  ANY = Google::Protobuf::Any.new
  TO_PACK = Google::Rpc::Status.new
  ANY.pack(TO_PACK)

  DONE_GET_METHOD = proc do
    GrpcOp.new(done: true, response: ANY)
  end
  DONE_ON_GET_CLIENT = MockLroClient.new(get_method: DONE_GET_METHOD)

  context 'method `results`' do
    it 'should return nil on unfinished operation.' do
      op = create_op(GrpcOp.new(done: false))
      expect(op.results).to be_nil
    end

    it 'should return the error on errored operation.' do
      error = Google::Rpc::Status.new
      op = create_op(GrpcOp.new(done: true, error: error))
      expect(op.results).to eq(error)
    end

    it 'should unpack the response.' do
      op = create_op(GrpcOp.new(done: true, response: ANY))
      expect(op.results(response_type: Google::Rpc::Status)).to eq(TO_PACK)
    end

    it 'should return an Any proto if no type was specified.' do
      op = create_op(GrpcOp.new(done: true, response: ANY))
      expect(op.results).to eq(ANY)
    end
  end

  context 'method `done?`' do
    it 'should return the status of an operation correctly.' do
      expect(create_op(GrpcOp.new(done: false)).done?).to eq(false)
      expect(create_op(GrpcOp.new(done: true)).done?).to eq(true)
    end
  end

  context 'method `error?`' do
    it 'should return false on unfinished operation.' do
      expect(create_op(GrpcOp.new(done: false)).error?).to eq(false)
    end

    it 'should return false on unfinished operation.' do
      error = Google::Rpc::Status.new
      op = create_op(GrpcOp.new(done: true, error: error))
      expect(op.error?).to eq(true)
    end

    it 'should return false on unfinished operation.' do
      op = create_op(GrpcOp.new(done: true, response: ANY))
      expect(op.error?).to eq(false)
    end
  end

  context 'method `cancel`' do
    it 'should call the clients cancel_operation' do
      op_name = 'test_name'
      called = false
      cancel_method = proc do |name|
        expect(name).to eq(op_name)
        called = true
      end
      mock_client = MockLroClient.new(cancel_method: cancel_method)
      create_op(GrpcOp.new(name: op_name), client: mock_client).cancel
      expect(called).to eq(true)
    end
  end

  context 'method `reload!`' do
    it 'should call the get_operation of the client' do
      called = false
      get_method = proc do
        called = true
        GrpcOp.new(done: true, response: ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)
      expect(called).to eq(false)
      op.reload!
      expect(called).to eq(true)
    end

    it 'should pass in a CallSettings object to the client' do
      backoff_settings = Google::Gax::BackoffSettings.new(1, 2, 3, 4, 5, 6, 7)
      called = false
      get_method = proc do |_, options|
        called = true
        expect(options).to be_a(Google::Gax::CallOptions)
        expect(options.retry_options.backoff_settings).to eq(backoff_settings)
        GrpcOp.new(done: true, response: ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(
        GrpcOp.new(done: false, name: 'name'), client: mock_client
      )
      expect(called).to eq(false)
      op.reload!(backoff_settings: backoff_settings)
      expect(called).to eq(true)
    end

    it 'should yield the registered callback after the operation completes' do
      op = create_op(GrpcOp.new(done: false), client: DONE_ON_GET_CLIENT)
      called = false
      op.on_done do |results|
        expect(results).to eq(ANY)
        called = true
      end
      expect(called).to eq(false)
      expect(op.done?).to eq(false)
      op.reload!
      expect(called).to eq(true)
      expect(op.done?).to eq(true)
    end

    it 'should yield the registered callbacks in order they were called.' do
      op = create_op(GrpcOp.new(done: false), client: DONE_ON_GET_CLIENT)
      expected_order = [1, 2, 3]
      called_order = []
      expected_order.each do |i|
        op.on_done do |results|
          expect(results).to eq(ANY)
          called_order.push(i)
        end
      end
      expect(called_order).to eq([])
      expect(op.done?).to eq(false)
      op.reload!
      expect(called_order).to eq(expected_order)
      expect(op.done?).to eq(true)
    end
  end

  context 'method `wait_until_done!`' do
    it 'should retry until the operation is done' do
      to_call = 3
      get_method = proc do
        to_call -= 1
        done = to_call == 0
        GrpcOp.new(done: done, response: ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)
      op.wait_until_done!
      expect(to_call).to eq(0)
    end

    it 'should wait until the operation is done' do
      to_call = 3
      get_method = proc do
        to_call -= 1
        done = to_call == 0
        GrpcOp.new(done: done, response: ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)
      op.wait_until_done!
      expect(to_call).to eq(0)
    end

    it 'times out' do
      backoff_settings = BackoffSettings.new(0, 0, 0, 0, 0, 0, 1)
      get_method = proc { GrpcOp.new(done: false) }
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)
      begin
        op.wait_until_done!(backoff_settings: backoff_settings)
        expect(true).to be false # should not reach to this line.
      rescue Google::Gax::RetryError => exc
        expect(exc).to be_a(Google::Gax::RetryError)
      end
    end

    # TODO: Test exponential backoff.
    it 'retries with exponential backoff' do
    end
  end

  context 'method `on_done`' do
    it 'should yield immediately when the operation is already finished' do
      op = create_op(GrpcOp.new(done: true, response: ANY))
      called = false
      op.on_done do |results|
        expect(results).to eq(ANY)
        called = true
      end
      expect(called).to eq(true)
    end
  end
end
