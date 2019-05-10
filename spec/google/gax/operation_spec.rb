# Copyright 2016, Google LLC
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

require 'time'

require 'google/gax/operation'
require 'google/gax/settings'
require 'google/gax/constants'
require 'google/protobuf/any_pb'
require 'google/protobuf/well_known_types'
require 'google/rpc/status_pb'
require 'google/longrunning/operations_pb'

GrpcOp = Google::Longrunning::Operation
GaxOp = Google::Gax::Operation

MILLIS_PER_SECOND = Google::Gax::MILLIS_PER_SECOND

class MockLroClient
  def initialize(get_method: nil, cancel_method: nil, delete_method: nil)
    @get_method = get_method
    @cancel_method = cancel_method
    @delete_method = delete_method
  end

  def get_operation(grpc_method, options: nil)
    @get_method.call(grpc_method, options)
  end

  def cancel_operation(name)
    @cancel_method.call(name)
  end

  def delete_operation(name)
    @delete_method.call(name)
  end
end

RESULT_ANY = Google::Protobuf::Any.new
RESULT = Google::Rpc::Status.new(code: 1, message: 'Result')
RESULT_ANY.pack(RESULT)

METADATA_ANY = Google::Protobuf::Any.new
METADATA = Google::Rpc::Status.new(code: 2, message: 'Metadata')
METADATA_ANY.pack(METADATA)

TIMESTAMP_ANY = Google::Protobuf::Any.new
TIMESTAMP = Google::Protobuf::Timestamp.new(
  seconds: 123_456_789,
  nanos: 987_654_321
)
TIMESTAMP_ANY.pack(TIMESTAMP)

UNKNOWN_ANY = Google::Protobuf::Any.new(
  type_url: 'type.unknown.tld/this.does.not.Exist',
  value: ''
)

DONE_GET_METHOD = proc do
  GrpcOp.new(done: true, response: RESULT_ANY, metadata: METADATA_ANY)
end
DONE_ON_GET_CLIENT = MockLroClient.new(get_method: DONE_GET_METHOD)

def create_op(operation, client: nil, result_type: Google::Rpc::Status,
              metadata_type: Google::Rpc::Status, call_options: nil)
  GaxOp.new(
    operation,
    client || DONE_ON_GET_CLIENT,
    result_type,
    metadata_type,
    call_options: call_options
  )
end

describe Google::Gax::Operation do
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

    it 'should unpack the response' do
      op = create_op(GrpcOp.new(done: true, response: RESULT_ANY))
      expect(op.results).to eq(RESULT)
    end
  end

  context 'method `name`' do
    it 'should return the operation name' do
      op = create_op(GrpcOp.new(done: true, name: '1234567890'))
      expect(op.name).to eq('1234567890')
    end
  end

  context 'method `metadata`' do
    it 'should unpack the metadata' do
      op = create_op(GrpcOp.new(done: true, metadata: METADATA_ANY))
      expect(op.metadata).to eq(METADATA)
    end

    it 'should unpack the metadata when metadata_type is set to type class.' do
      op = create_op(GrpcOp.new(done: true, metadata: TIMESTAMP_ANY),
                     metadata_type: Google::Protobuf::Timestamp)
      expect(op.metadata).to eq(TIMESTAMP)
    end

    it 'should unpack the metadata when metadata_type is looked up.' do
      op = create_op(GrpcOp.new(done: true, metadata: TIMESTAMP_ANY),
                     metadata_type: nil)
      expect(op.metadata).to eq(TIMESTAMP)
    end

    it 'should lookup and unpack the metadata when metadata_type is not ' \
       'provided' do
      op = GaxOp.new( # create Operation without result_type or metadata_type
        GrpcOp.new(done: true, metadata: TIMESTAMP_ANY),
        DONE_ON_GET_CLIENT
      )
      expect(op.metadata).to eq(TIMESTAMP)
    end

    it 'should return original metadata when metadata_type is not found when ' \
       'looked up.' do
      op = create_op(GrpcOp.new(done: true, metadata: UNKNOWN_ANY),
                     metadata_type: nil)
      expect(op.metadata).to eq(UNKNOWN_ANY)
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

    it 'should return true on error.' do
      error = Google::Rpc::Status.new
      op = create_op(GrpcOp.new(done: true, error: error))
      expect(op.error?).to eq(true)
    end

    it 'should return false on finished operation.' do
      op = create_op(GrpcOp.new(done: true, response: RESULT_ANY))
      expect(op.error?).to eq(false)
    end
  end

  context 'method `error`' do
    it 'should return nil on unfinished operation.' do
      op = create_op(GrpcOp.new(done: false))
      expect(op.error).to eq(nil)
    end

    it 'should return error on error operation.' do
      error = Google::Rpc::Status.new
      op = create_op(GrpcOp.new(done: true, error: error))
      expect(op.error).to eq(error)
    end

    it 'should return nil on finished operation.' do
      op = create_op(GrpcOp.new(done: true, response: RESULT_ANY))
      expect(op.error).to eq(nil)
    end
  end

  context 'method `response?`' do
    it 'should return false on unfinished operation.' do
      expect(create_op(GrpcOp.new(done: false)).response?).to eq(false)
    end

    it 'should return false on error operation.' do
      error = Google::Rpc::Status.new
      op = create_op(GrpcOp.new(done: true, error: error))
      expect(op.response?).to eq(false)
    end

    it 'should return true on finished operation.' do
      op = create_op(GrpcOp.new(done: true, response: RESULT_ANY))
      expect(op.response?).to eq(true)
    end
  end

  context 'method `response`' do
    it 'should return nil on unfinished operation.' do
      op = create_op(GrpcOp.new(done: false))
      expect(op.response).to eq(nil)
    end

    it 'should return nil on error operation.' do
      error = Google::Rpc::Status.new
      op = create_op(GrpcOp.new(done: true, error: error))
      expect(op.response).to eq(nil)
    end

    it 'should result on finished operation.' do
      op = create_op(GrpcOp.new(done: true, response: RESULT_ANY))
      expect(op.response).to eq(RESULT)
    end

    it 'should unpack the result when result_type is set to type class.' do
      op = create_op(GrpcOp.new(done: true, response: TIMESTAMP_ANY),
                     result_type: Google::Protobuf::Timestamp)
      expect(op.response).to eq(TIMESTAMP)
    end

    it 'should unpack the result when result_type is looked up.' do
      op = create_op(GrpcOp.new(done: true, response: TIMESTAMP_ANY),
                     result_type: nil)
      expect(op.response).to eq(TIMESTAMP)
    end

    it 'should lookup and unpack the result when result_type is not ' \
       'provided.' do
      op = GaxOp.new( # create Operation without result_type or metadata_type
        GrpcOp.new(done: true, response: TIMESTAMP_ANY),
        DONE_ON_GET_CLIENT
      )
      expect(op.response).to eq(TIMESTAMP)
    end

    it 'should return original response when result_type is not found when ' \
       'looked up.' do
      op = create_op(GrpcOp.new(done: true, response: UNKNOWN_ANY),
                     result_type: nil)
      expect(op.response).to eq(UNKNOWN_ANY)
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

  context 'method `delete`' do
    it 'should call the clients delete_operation' do
      op_name = 'test_name'
      called = false
      delete_method = proc do |name|
        expect(name).to eq(op_name)
        called = true
      end
      mock_client = MockLroClient.new(delete_method: delete_method)
      create_op(GrpcOp.new(name: op_name), client: mock_client).delete
      expect(called).to eq(true)
    end
  end

  context 'method `reload!`' do
    it 'should call the get_operation of the client' do
      called = false
      get_method = proc do
        called = true
        GrpcOp.new(done: true, response: RESULT_ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)
      expect(called).to eq(false)
      op.reload!
      expect(called).to eq(true)
    end

    it 'should use call_options attribute when reloading' do
      backoff_settings = Google::Gax::BackoffSettings.new(1, 2, 3, 4, 5, 6, 7)
      call_options = Google::Gax::CallOptions.new(
        retry_options: Google::Gax::RetryOptions.new(nil, backoff_settings)
      )
      called = false
      get_method = proc do |_, options|
        called = true
        expect(options).to be_a(Google::Gax::CallOptions)
        expect(options).to eq(call_options)
        GrpcOp.new(done: true, response: RESULT_ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)

      op = create_op(
        GrpcOp.new(done: false, name: 'name'),
        client: mock_client,
        call_options: call_options
      )
      expect(called).to eq(false)
      op.reload!
      expect(called).to eq(true)
    end

    it 'should yield the registered callback after the operation completes' do
      op = create_op(GrpcOp.new(done: false), client: DONE_ON_GET_CLIENT)
      called = false
      op.on_done do |operation|
        expect(operation.results).to eq(RESULT)
        expect(operation.metadata).to eq(METADATA)
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
        op.on_done do |operation|
          expect(operation.results).to eq(RESULT)
          expect(operation.metadata).to eq(METADATA)
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
        GrpcOp.new(done: done, response: RESULT_ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)
      time_now = Time.now
      allow(Time).to receive(:now) { time_now }
      expect(op).to(
        receive(:sleep).exactly(3).times { |secs| time_now += secs }
      )
      op.wait_until_done!
      expect(to_call).to eq(0)
    end

    it 'should wait until the operation is done' do
      to_call = 3
      get_method = proc do
        to_call -= 1
        done = to_call == 0
        GrpcOp.new(done: done, response: RESULT_ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)

      time_now = Time.now
      allow(Time).to receive(:now) { time_now }
      expect(op).to(
        receive(:sleep).exactly(3).times { |secs| time_now += secs }
      )

      op.wait_until_done!
      expect(to_call).to eq(0)
    end

    it 'times out' do
      backoff_settings = BackoffSettings.new(1, 1, 10, 0, 0, 0, 100)
      get_method = proc { GrpcOp.new(done: false) }
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)

      time_now = Time.now
      allow(Time).to receive(:now) { time_now }
      allow(op).to receive(:sleep) { |secs| time_now += secs }

      begin
        op.wait_until_done!(backoff_settings: backoff_settings)
      rescue Google::Gax::RetryError => exc
        expect(exc).to be_a(Google::Gax::RetryError)
      end
    end

    it 'retries with exponential backoff' do
      call_count = 0
      get_method = proc do
        call_count += 1
        GrpcOp.new(done: false, response: RESULT_ANY)
      end
      mock_client = MockLroClient.new(get_method: get_method)
      op = create_op(GrpcOp.new(done: false), client: mock_client)

      time_now = Time.now
      start_time = time_now
      allow(Time).to receive(:now) { time_now }
      allow(op).to receive(:sleep) { |secs| time_now += secs }

      initial_delay = 10 * MILLIS_PER_SECOND
      delay_multiplier = 1.5
      max_delay = 5 * 60 * MILLIS_PER_SECOND
      total_timeout = 60 * 60 * MILLIS_PER_SECOND
      backoff = BackoffSettings.new(
        initial_delay,
        delay_multiplier,
        max_delay,
        0,
        0,
        0,
        total_timeout
      )
      begin
        op.wait_until_done!(backoff_settings: backoff)
      rescue Google::Gax::RetryError => exc
        expect(exc).to be_a(Google::Gax::RetryError)
      end
      expect(time_now - start_time).to be >= (total_timeout / MILLIS_PER_SECOND)

      calls_lower_bound = total_timeout / max_delay
      calls_upper_bound = total_timeout / initial_delay
      expect(call_count).to be > calls_lower_bound
      expect(call_count).to be < calls_upper_bound
    end
  end

  context 'method `on_done`' do
    it 'should yield immediately when the operation is already finished' do
      op = create_op(
        GrpcOp.new(done: true, response: RESULT_ANY, metadata: METADATA_ANY)
      )
      called = false
      op.on_done do |operation|
        expect(operation.results).to eq(RESULT)
        expect(operation.metadata).to eq(METADATA)
        called = true
      end
      expect(called).to eq(true)
    end
  end
end
