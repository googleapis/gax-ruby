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

# These must be loaded separate from google/gax to avoid circular dependency.
require 'google/gax/constants'
require 'google/gax/settings'
require 'google/protobuf/well_known_types'

module Google
  module Gax
    # A class used to wrap Google::Longrunning::Operation objects. This class
    # provides helper methods to check the status of an Operation
    #
    # @example Checking Operation status
    #   require 'google/gax/operation'
    #   require 'google/longrunning/operations_client'
    #
    #   operations_client = Google::Longrunning::OperationsClient.new
    #   op = Google::Gax::Operation.new(
    #     api.methodThatReturnsOperation(),
    #     operations_client,
    #     Google::Example::ResultType,
    #     Google::Example::MetadataType
    #   )
    #
    #   op.done? # => false
    #   op.reload! # => operation completed
    #
    #   if op.done?
    #     results = op.results
    #     handle_error(results) if op.error?
    #     # Handle results.
    #   end
    #
    # @example Working with callbacks
    #   require 'google/gax/operation'
    #   require 'google/longrunning/operations_client'
    #
    #   operations_client = Google::Longrunning::OperationsClient.new
    #   op = Google::Gax::Operation.new(
    #     api.method_that_returns_operation,
    #     operations_client,
    #     Google::Example::ResultType,
    #     Google::Example::MetadataType
    #   )
    #
    #   # Register a callback to be run when an operation is done.
    #   op.on_done do |operation|
    #     raise operation.results.message if operation.error?
    #     # process(operation.results)
    #     # process(operation.metadata)
    #   end
    #
    #   # Reload the operation running callbacks if operation completed.
    #   op.reload!
    #
    #   # Or block until the operation completes, passing a block to be called
    #   # on completion.
    #   op.wait_until_done do |operation|
    #     raise operation.results.message if operation.error?
    #     # process(operation.results)
    #     # process(operation.rmetadata)
    #   end
    #
    # @attribute [r] grpc_op
    #   @return [Google::Longrunning::Operation] The wrapped grpc
    #     operation object.
    # @attribute [rw] call_options
    #   @return [Google::Gax::CallOptions] The call options used when reloading
    #     the operation.
    class Operation
      attr_reader :grpc_op

      attr_accessor :call_options

      # @param grpc_op [Google::Longrunning::Operation]
      #   The inital longrunning operation.
      # @param client [Google::Longrunning::OperationsClient]
      #   The client that handles the grpc operations.
      # @param result_type [Class] The class type to be unpacked from the
      #   result. If not provided the class type will be looked up. Optional.
      # @param metadata_type [Class] The class type to be unpacked from the
      #   metadata. If not provided the class type will be looked up. Optional.
      # @param call_options [Google::Gax::CallOptions]
      #   The call options that are used when reloading the operation. Optional.
      def initialize(grpc_op, client, result_type = nil, metadata_type = nil,
                     call_options: nil)
        @grpc_op = grpc_op
        @client = client
        @call_options = call_options
        @result_type = result_type
        @metadata_type = metadata_type
        @callbacks = []
      end

      # If the operation is done, returns the response.
      # If the operation response is an error, the error will be returned.
      # Otherwise returns nil.
      #
      # @return [Object, Google::Rpc::Status, nil]
      #   The result of the operation. If it is an error a Google::Rpc::Status
      #   will be returned.
      def results
        return error if error?
        return response if response?
      end

      # Returns the server-assigned name of the operation, which is only unique
      # within the same service that originally returns it. If you use the
      # default HTTP mapping, the name should have the format of
      # operations/some/unique/name.
      #
      # @return [String]
      #   The name of the operation.
      def name
        @grpc_op.name
      end

      # Returns the metadata of an operation. If a type is provided,
      # the metadata will be unpacked using the type provided; returning nil
      # if the metadata is not of the type provided.
      # If the type is not of provided, the metadata will be unpacked using
      # the metadata's type_url if the type_url is found in the
      # Google::Protobuf::DescriptorPool.generated_pool.
      # If the type cannot be found the raw metadata is retuned.
      #
      # @return [Object, nil]
      #   The metadata of the operation. Can be nil.
      def metadata
        return if @grpc_op.metadata.nil?

        return @grpc_op.metadata.unpack(@metadata_type) if @metadata_type

        descriptor = Google::Protobuf::DescriptorPool.generated_pool.lookup(
          @grpc_op.metadata.type_name
        )
        return @grpc_op.metadata.unpack(descriptor.msgclass) if descriptor

        @grpc_op.metadata
      end

      # Checks if the operation is done. This does not send a new api call,
      # but checks the result of the previous api call to see if done.
      #
      # @return [Boolean] Whether the operation is done.
      def done?
        @grpc_op.done
      end

      # Checks if the operation is done and the result is a response.
      # If the operation is not finished then this will return false.
      #
      # @return [Boolean] Whether a response has been returned.
      def response?
        done? ? @grpc_op.result == :response : false
      end

      # If the operation is done, returns the response, otherwise returns nil.
      #
      # @return [Object, nil]
      #   The response of the operation.
      def response
        return unless response?

        return @grpc_op.response.unpack(@result_type) if @result_type

        descriptor = Google::Protobuf::DescriptorPool.generated_pool.lookup(
          @grpc_op.response.type_name
        )
        return @grpc_op.response.unpack(descriptor.msgclass) if descriptor

        @grpc_op.response
      end

      # Checks if the operation is done and the result is an error.
      # If the operation is not finished then this will return false.
      #
      # @return [Boolean] Whether an error has been returned.
      def error?
        done? ? @grpc_op.result == :error : false
      end

      # If the operation response is an error, the error will be returned,
      # otherwise returns nil.
      #
      # @return [Google::Rpc::Status, nil]
      #   The error object.
      def error
        @grpc_op.error if error?
      end

      # Cancels the operation.
      def cancel
        @client.cancel_operation(@grpc_op.name)
      end

      # Deletes the operation.
      def delete
        @client.delete_operation(@grpc_op.name)
      end

      # Reloads the operation object.
      #
      # @return [Google::Gax::Operation]
      #   Since this method changes internal state, it returns itself.
      def reload!
        @grpc_op = @client.get_operation(@grpc_op.name, options: @call_options)
        if done?
          @callbacks.each { |proc| proc.call(self) }
          @callbacks.clear
        end
        self
      end
      alias refresh! reload!

      # Blocking method to wait until the operation has completed or the
      # maximum timeout has been reached. Upon completion, registered callbacks
      # will be called, then - if a block is given - the block will be called.
      #
      # @param backoff_settings [Google::Gax::BackoffSettings]
      #   The backoff settings used to manipulate how this method retries
      #   checking if the operation is done.
      # @yield operation [Google::Gax::Operation] Yields the finished Operation.
      def wait_until_done!(backoff_settings: nil)
        unless backoff_settings
          backoff_settings = BackoffSettings.new(
            10 * MILLIS_PER_SECOND,
            1.3,
            5 * 60 * MILLIS_PER_SECOND,
            0,
            0,
            0,
            60 * 60 * MILLIS_PER_SECOND
          )
        end

        delay = backoff_settings.initial_retry_delay_millis / MILLIS_PER_SECOND
        max_delay = backoff_settings.max_retry_delay_millis / MILLIS_PER_SECOND
        delay_multiplier = backoff_settings.retry_delay_multiplier
        total_timeout =
          backoff_settings.total_timeout_millis / MILLIS_PER_SECOND
        deadline = Time.now + total_timeout
        until done?
          sleep(delay)
          if Time.now >= deadline
            raise RetryError.new('Retry total timeout exceeded with exception')
          end
          delay = [delay * delay_multiplier, max_delay].min
          reload!
        end
        yield(self) if block_given?
      end

      # Registers a callback to be run when a refreshed operation is marked
      # as done. If the operation has completed prior to a call to this function
      # the callback will be called instead of registered.
      #
      # @yield operation [Google::Gax::Operation] Yields the finished Operation.
      def on_done(&block)
        if done?
          yield(self)
        else
          @callbacks.push(block)
        end
      end
    end
  end
end
