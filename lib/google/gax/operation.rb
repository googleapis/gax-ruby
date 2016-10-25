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

# This must be loaded separate from google/gax to avoid circular dependency.
require 'google/gax/constants'
require 'google/gax/settings'
require 'google/longrunning/operations_api'

module Google
  module Gax
    # A class used to wrap Google::Longrunning::Operation objects.
    #
    # @example General usage example
    #   require 'google/gax/operation'
    #
    #   op = Google::Gax::Operation.new api.methodThatReturnsOperation(name)
    #   op.done?
    #   op.reload!
    #   op.done?
    #   results = op.results
    #   raise results if op.error?
    #
    # @attribute [r] grpc_op
    #   @return [Google::Longrunning::Operation] The wrapped grpc
    #     operation object.
    # @attribute [r] client
    #   @return [Google::Longrunning::OperationsApi] The client that handles the
    #     grpc operations.
    class Operation
      attr_reader :grpc_op, :client

      # @param grpc_op [Google::Longrunning::Operation]
      #   The inital longrunning operation.
      # @param client [Google::Longrunning::OperationsApi]
      #   The client that handles the grpc operations.
      def initialize(grpc_op, client: nil)
        @grpc_op = grpc_op
        @client = client ? client : Google::Longrunning::OperationsApi.new
        @callbacks = []
      end

      # If the operation is done, returns the result, otherwise returns nil.
      # If a Class is provided, an instance of that class will try to be
      # unpacked from the response. If the response is not of the type provided
      # nil will be returned.
      #
      # @param [Class] The class type to be unpacked from the response.
      # @return [nil | Google::Rpc::Status | Object | Google::Protobuf::Any ]
      #   The result of the operation
      def results(responseType: nil)
        return nil unless done?
        return @grpc_op.error if error?
        return @grpc_op.response.unpack(responseType) if responseType
        @grpc_op.response
      end

      # Checks if the operation is done. This does not send a new api call,
      # but checks the result of the previous api call to see if done.
      #
      # @return [Boolean] Whether the operation is done.
      def done?
        @grpc_op.done
      end

      # Checks if the operation is done and the result is an error.
      # If the operation is not finished then this will return false.
      #
      # @return [Boolean] Whether an error has been returned.
      def error?
        done? ? @grpc_op.result == :error : false
      end

      # Reloads the operation object.
      # @return [Google::Gax::Longrunning]
      #   Since this method changes internal state, it returns itself.
      def reload!(backoff_settings: nil)
        options = CallSettings.new(
          retry_options: RetryOptions.new(
            backoff_settings: backoff_settings
          )
        )
        @grpc_op = @client.get_operation @grpc_op.name, options: options
        if done?
          callbacks.each { |proc| proc.call(results) }
          callbacks.clear
        end
        self
      end
      alias refresh! reload!

      # Cancels the operation.
      def cancel
        @client.cancel_operation @grpc_op.name
      end

      # Blocking method to wait until the operation has completed or the
      # maximum timeout has been reached.
      #
      # @param backoff_settings [Google::Gax::BackoffSettings]
      #   The backoff settings used to manipulate how this method retries
      #   checking if the operation is done.
      # @yield [Google::Rpc::Status | Object]
      #   If a block is given, runs the block using the results
      #   of the operation.
      def wait_until_done!(backoff_settings: nil)
        backoff_settings = BackoffSettings.new unless backoff_settings

        delay = backoff_settings.initial_retry_delay_millis || 100
        max_delay = backoff_settings.max_retry_delay_millis || 60_000
        delay_multiplier = backoff_settings.retry_delay_multiplier || 1.3
        total_timeout = backoff_settings.total_timeout_millis || 60_000
        now = Time.now
        deadline = now + total_timeout
        until done?
          sleep(rand(delay) / MILLIS_PER_SECOND)
          if now >= deadline
            raise RetryError, 'Retry total timeout exceeded with exception'
          end
          delay = [delay * delay_multiplier, max_delay].min
          reload! backoff_settings
        end
        yield(results) if block_given?
      end

      # Registers a callback to be run when a refreshed operation is marked
      # as done. If the operation has completed prior to a call to this function
      # the callback will be called instead of registered.
      def on_done
        if done?
          yield(results)
        else
          callbacks.push(proc { |results| yield(results) })
        end
      end
    end
  end
end
