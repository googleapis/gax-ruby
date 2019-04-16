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

require "google/gax/operation"
require "google/protobuf/any_pb"
require "google/protobuf/well_known_types"
require "google/rpc/status_pb"
require "google/longrunning/operations_pb"

GrpcOp = Google::Longrunning::Operation
GaxOp = Google::Gax::Operation

MILLIS_PER_SECOND = Google::Gax::MILLIS_PER_SECOND

class MockLroClient
  def initialize get_method: nil, cancel_method: nil, delete_method: nil
    @get_method = get_method
    @cancel_method = cancel_method
    @delete_method = delete_method
  end

  def get_operation grpc_method, options: nil
    @get_method.call grpc_method, options
  end

  def cancel_operation name, options: nil
    @cancel_method.call name, options: options
  end

  def delete_operation name, options: nil
    @delete_method.call name, options: options
  end
end

RESULT_ANY = Google::Protobuf::Any.new
RESULT = Google::Rpc::Status.new code: 1, message: "Result"
RESULT_ANY.pack RESULT

METADATA_ANY = Google::Protobuf::Any.new
METADATA = Google::Rpc::Status.new code: 2, message: "Metadata"
METADATA_ANY.pack METADATA

TIMESTAMP_ANY = Google::Protobuf::Any.new
TIMESTAMP = Google::Protobuf::Timestamp.new(
  seconds: 123_456_789,
  nanos:   987_654_321
)
TIMESTAMP_ANY.pack TIMESTAMP

UNKNOWN_ANY = Google::Protobuf::Any.new(
  type_url: "type.unknown.tld/this.does.not.Exist",
  value:    ""
)

DONE_GET_METHOD = proc do
  GrpcOp.new done: true, response: RESULT_ANY, metadata: METADATA_ANY
end
DONE_ON_GET_CLIENT = MockLroClient.new get_method: DONE_GET_METHOD

def create_op operation, client: nil, result_type: Google::Rpc::Status,
              metadata_type: Google::Rpc::Status
  GaxOp.new(
    operation,
    client || DONE_ON_GET_CLIENT,
    result_type,
    metadata_type
  )
end

describe Google::Gax::Operation do
  describe "method `results`" do
    it "should return nil on unfinished operation." do
      op = create_op GrpcOp.new(done: false)
      _(op.results).must_be_nil
    end

    it "should return the error on errored operation." do
      error = Google::Rpc::Status.new
      op = create_op GrpcOp.new(done: true, error: error)
      _(op.results).must_equal error
    end

    it "should unpack the response" do
      op = create_op GrpcOp.new(done: true, response: RESULT_ANY)
      _(op.results).must_equal RESULT
    end
  end

  describe "method `name`" do
    it "should return the operation name" do
      op = create_op GrpcOp.new(done: true, name: "1234567890")
      _(op.name).must_equal "1234567890"
    end
  end

  describe "method `metadata`" do
    it "should unpack the metadata" do
      op = create_op GrpcOp.new(done: true, metadata: METADATA_ANY)
      _(op.metadata).must_equal METADATA
    end

    it "should unpack the metadata when metadata_type is set to type class." do
      op = create_op(GrpcOp.new(done: true, metadata: TIMESTAMP_ANY),
                     metadata_type: Google::Protobuf::Timestamp)
      _(op.metadata).must_equal TIMESTAMP
    end

    it "should unpack the metadata when metadata_type is looked up." do
      op = create_op(GrpcOp.new(done: true, metadata: TIMESTAMP_ANY),
                     metadata_type: nil)
      _(op.metadata).must_equal TIMESTAMP
    end

    it "should lookup and unpack the metadata when metadata_type is not " \
       "provided" do
      op = GaxOp.new( # create Operation without result_type or metadata_type
        GrpcOp.new(done: true, metadata: TIMESTAMP_ANY),
        DONE_ON_GET_CLIENT
      )
      _(op.metadata).must_equal TIMESTAMP
    end

    it "should return original metadata when metadata_type is not found when " \
       "looked up." do
      op = create_op(GrpcOp.new(done: true, metadata: UNKNOWN_ANY),
                     metadata_type: nil)
      _(op.metadata).must_equal UNKNOWN_ANY
    end
  end

  describe "method `done?`" do
    it "should return the status of an operation correctly." do
      _(create_op(GrpcOp.new(done: false)).done?).must_equal false
      _(create_op(GrpcOp.new(done: true)).done?).must_equal true
    end
  end

  describe "method `error?`" do
    it "should return false on unfinished operation." do
      _(create_op(GrpcOp.new(done: false)).error?).must_equal false
    end

    it "should return true on error." do
      error = Google::Rpc::Status.new
      op = create_op GrpcOp.new(done: true, error: error)
      _(op.error?).must_equal true
    end

    it "should return false on finished operation." do
      op = create_op GrpcOp.new(done: true, response: RESULT_ANY)
      _(op.error?).must_equal false
    end
  end

  describe "method `error`" do
    it "should return nil on unfinished operation." do
      op = create_op GrpcOp.new(done: false)
      _(op.error).must_be_nil
    end

    it "should return error on error operation." do
      error = Google::Rpc::Status.new
      op = create_op GrpcOp.new(done: true, error: error)
      _(op.error).must_equal error
    end

    it "should return nil on finished operation." do
      op = create_op GrpcOp.new(done: true, response: RESULT_ANY)
      _(op.error).must_be_nil
    end
  end

  describe "method `response?`" do
    it "should return false on unfinished operation." do
      _(create_op(GrpcOp.new(done: false)).response?).must_equal false
    end

    it "should return false on error operation." do
      error = Google::Rpc::Status.new
      op = create_op GrpcOp.new(done: true, error: error)
      _(op.response?).must_equal false
    end

    it "should return true on finished operation." do
      op = create_op GrpcOp.new(done: true, response: RESULT_ANY)
      _(op.response?).must_equal true
    end
  end

  describe "method `response`" do
    it "should return nil on unfinished operation." do
      op = create_op GrpcOp.new(done: false)
      _(op.response).must_be_nil
    end

    it "should return nil on error operation." do
      error = Google::Rpc::Status.new
      op = create_op GrpcOp.new(done: true, error: error)
      _(op.response).must_be_nil
    end

    it "should result on finished operation." do
      op = create_op GrpcOp.new(done: true, response: RESULT_ANY)
      _(op.response).must_equal RESULT
    end

    it "should unpack the result when result_type is set to type class." do
      op = create_op(GrpcOp.new(done: true, response: TIMESTAMP_ANY),
                     result_type: Google::Protobuf::Timestamp)
      _(op.response).must_equal TIMESTAMP
    end

    it "should unpack the result when result_type is looked up." do
      op = create_op(GrpcOp.new(done: true, response: TIMESTAMP_ANY),
                     result_type: nil)
      _(op.response).must_equal TIMESTAMP
    end

    it "should lookup and unpack the result when result_type is not " \
       "provided." do
      op = GaxOp.new( # create Operation without result_type or metadata_type
        GrpcOp.new(done: true, response: TIMESTAMP_ANY),
        DONE_ON_GET_CLIENT
      )
      _(op.response).must_equal TIMESTAMP
    end

    it "should return original response when result_type is not found when " \
       "looked up." do
      op = create_op(GrpcOp.new(done: true, response: UNKNOWN_ANY),
                     result_type: nil)
      _(op.response).must_equal UNKNOWN_ANY
    end
  end

  describe "method `cancel`" do
    it "should call the clients cancel_operation" do
      op_name = "test_name"
      called = false
      cancel_method = proc do |name|
        _(name).must_equal op_name
        called = true
      end
      mock_client = MockLroClient.new cancel_method: cancel_method
      create_op(GrpcOp.new(name: op_name), client: mock_client).cancel
      _(called).must_equal true
    end
  end

  describe "method `delete`" do
    it "should call the clients delete_operation" do
      op_name = "test_name"
      called = false
      delete_method = proc do |name, options: options|
        _(name).must_equal op_name
        _(options).must_be_kind_of Google::Gax::ApiCall::Options
        called = true
      end
      mock_client = MockLroClient.new delete_method: delete_method
      create_op(GrpcOp.new(name: op_name), client: mock_client).delete
      _(called).must_equal true
    end
  end

  describe "method `reload!`" do
    it "should call the get_operation of the client" do
      called = false
      get_method = proc do
        called = true
        GrpcOp.new done: true, response: RESULT_ANY
      end
      mock_client = MockLroClient.new get_method: get_method
      op = create_op GrpcOp.new(done: false), client: mock_client
      _(called).must_equal false
      op.reload!
      _(called).must_equal true
    end

    it "should use options attribute when reloading" do
      options = Google::Gax::ApiCall::Options.new
      called = false
      get_method = proc do |name, options|
        called = true
        _(name).must_equal "name"
        _(options).must_be_kind_of Google::Gax::ApiCall::Options
        _(options).must_equal options
        GrpcOp.new done: true, response: RESULT_ANY
      end
      mock_client = MockLroClient.new get_method: get_method

      op = create_op(
        GrpcOp.new(done: false, name: "name"),
        client:       mock_client
      )
      _(called).must_equal false
      op.reload! options: options
      _(called).must_equal true
    end

    it "should yield the registered callback after the operation completes" do
      op = create_op GrpcOp.new(done: false), client: DONE_ON_GET_CLIENT
      called = false
      op.on_done do |operation|
        _(operation.results).must_equal RESULT
        _(operation.metadata).must_equal METADATA
        called = true
      end
      _(called).must_equal false
      _(op.done?).must_equal false
      op.reload!
      _(called).must_equal true
      _(op.done?).must_equal true
    end

    it "should yield the registered callbacks in order they were called." do
      op = create_op GrpcOp.new(done: false), client: DONE_ON_GET_CLIENT
      expected_order = [1, 2, 3]
      called_order = []
      expected_order.each do |i|
        op.on_done do |operation|
          _(operation.results).must_equal RESULT
          _(operation.metadata).must_equal METADATA
          called_order.push i
        end
      end
      _(called_order).must_equal []
      _(op.done?).must_equal false
      op.reload!
      _(called_order).must_equal expected_order
      _(op.done?).must_equal true
    end
  end

  describe "method `wait_until_done!`" do
    it "should retry until the operation is done" do
      to_call = 3
      get_method = proc do
        to_call -= 1
        done = to_call == 0
        GrpcOp.new done: done, response: RESULT_ANY
      end

      mock_client = MockLroClient.new get_method: get_method
      op = create_op GrpcOp.new(done: false), client: mock_client

      mock = Minitest::Mock.new
      mock.expect :sleep, nil, [10.0]
      mock.expect :sleep, nil, [13.0]
      mock.expect :sleep, nil, [16.900000000000002]
      op.define_singleton_method :sleep do |count|
        # call the mock to satisfy the expectation
        mock.sleep count
      end

      time_now = Time.now
      Time.stub :now, time_now do
        op.wait_until_done!
      end

      mock.verify

      _(to_call).must_equal 0
    end

    it "should wait until the operation is done" do
      to_call = 3
      get_method = proc do
        to_call -= 1
        done = to_call == 0
        GrpcOp.new done: done, response: RESULT_ANY
      end

      mock_client = MockLroClient.new get_method: get_method
      op = create_op GrpcOp.new(done: false), client: mock_client

      mock = Minitest::Mock.new
      mock.expect :sleep, nil, [10.0]
      mock.expect :sleep, nil, [13.0]
      mock.expect :sleep, nil, [16.900000000000002]
      op.define_singleton_method :sleep do |count|
        # call the mock to satisfy the expectation
        mock.sleep count
      end

      time_now = Time.now
      Time.stub :now, time_now do
        op.wait_until_done!
      end

      mock.verify

      _(to_call).must_equal 0
    end

    it "times out" do
      backoff_settings = Google::Gax::BackoffSettings.new(
        1, 1, 10, 0, 0, 0, 100
      )
      get_method = proc { GrpcOp.new done: false }
      mock_client = MockLroClient.new get_method: get_method
      op = create_op GrpcOp.new(done: false), client: mock_client

      mock = Minitest::Mock.new
      mock.expect :sleep, nil, [0.001]
      op.define_singleton_method :sleep do |count|
        # call the mock to satisfy the expectation
        mock.sleep count
      end

      time_now = Time.now
      incrementing_time = lambda do
        time_now += 1
      end
      Time.stub :now, incrementing_time do
        expect do
          op.wait_until_done! backoff_settings: backoff_settings
        end.must_raise Google::Gax::RetryError
      end

      mock.verify
    end

    it "retries with exponential backoff" do
      call_count = 0
      get_method = proc do
        call_count += 1
        GrpcOp.new done: false, response: RESULT_ANY
      end
      mock_client = MockLroClient.new get_method: get_method
      op = create_op GrpcOp.new(done: false), client: mock_client

      initial_delay = 10 * MILLIS_PER_SECOND
      delay_multiplier = 1.5
      max_delay = 5 * 60 * MILLIS_PER_SECOND
      total_timeout = 60 * 60 * MILLIS_PER_SECOND
      backoff = Google::Gax::BackoffSettings.new(
        initial_delay,
        delay_multiplier,
        max_delay,
        0,
        0,
        0,
        total_timeout
      )

      incrementing_times = [10.0, 15.0, 22.5, 33.75, 50.625, 75.9375,
                            113.90625, 170.859375, 256.2890625]

      mock = Minitest::Mock.new
      incrementing_times.each do |t|
        mock.expect :sleep, nil, [t]
      end
      10.times { mock.expect :sleep, nil, [300.0] }
      op.define_singleton_method :sleep do |count|
        # call the mock to satisfy the expectation
        mock.sleep count
      end

      time_now = Time.now
      start_time = time_now
      incrementing_time = lambda do
        delay = incrementing_times.shift || 300
        time_dup = time_now
        time_now += delay
        time_dup
      end
      Time.stub :now, incrementing_time do
        expect do
          op.wait_until_done! backoff_settings: backoff
        end.must_raise Google::Gax::RetryError
      end

      mock.verify

      _(time_now - start_time).must_be :>=, (total_timeout / MILLIS_PER_SECOND)

      calls_lower_bound = total_timeout / max_delay
      calls_upper_bound = total_timeout / initial_delay
      _(call_count).must_be :>, calls_lower_bound
      _(call_count).must_be :<, calls_upper_bound
    end
  end

  describe "method `on_done`" do
    it "should yield immediately when the operation is already finished" do
      op = create_op(
        GrpcOp.new(done: true, response: RESULT_ANY, metadata: METADATA_ANY)
      )
      called = false
      op.on_done do |operation|
        _(operation.results).must_equal RESULT
        _(operation.metadata).must_equal METADATA
        called = true
      end
      _(called).must_equal true
    end
  end
end
