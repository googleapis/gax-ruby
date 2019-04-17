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

require "google/gax/api_call/options"
require "google/gax/errors"

module Google
  module Gax
    class ApiCall
      attr_reader :stub_method

      ##
      # Creates an API object for making a single RPC call.
      #
      # In typical usage, `stub_method` will be a proc used to make an RPC request. This will mostly likely be a bound
      # method from a request Stub used to make an RPC call.
      #
      # The result is created by applying a series of function decorators defined in this module to `stub_method`.
      #
      # The result is another proc which has the same signature as the original.
      #
      # @param stub_method [Proc] Used to make a bare rpc call.
      #
      def initialize stub_method
        @stub_method = stub_method
      end

      ##
      # Invoke the API call.
      #
      # @param request [Object] The request object.
      # @param options [ApiCall::Options, Hash] The options for making the API call. A Hash can be provided to customize
      #   the options object, using keys that match the arguments for {ApiCall::Options.new}. This object should only be
      #   used once.
      # @param format_response [Proc] A Proc object to format the response object. The Proc should accept response as an
      #   argument, and return a formatted response object. Optional.
      #
      #   If `stream_callback` is also provided, the response argument will be an Enumerable of the responses. Returning
      #   a lazy enumerable that adds the desired formatting is recommended.
      # @param operation_callback [Proc] A Proc object to provide a callback of the response and operation objects. The
      #   response will be formatted with `format_response` if that is also provided. Optional.
      # @param stream_callback [Proc] A Proc object to provide a callback for every streamed response received. The Proc
      #   will be called with the response object. Should only be used on Bidi and Server streaming RPC calls. Optional.
      #
      # @return [Object, Thread] The response object. Or, when `stream_callback` is provided, a thread running the
      #   callback for every streamed response is returned.
      #
      def call request, options: nil, format_response: nil, operation_callback: nil, stream_callback: nil
        # Converts hash and nil to an options object
        options = ApiCall::Options.new options.to_h if options.respond_to? :to_h
        stream_proc = compose_stream_proc stream_callback: stream_callback, format_response: format_response
        deadline = calculate_deadline options
        metadata = options.metadata

        begin
          operation = stub_method.call request, deadline: deadline, metadata: metadata, return_op: true, &stream_proc

          if stream_proc
            Thread.new { operation.execute }
          else
            response = operation.execute
            response = format_response.call response if format_response
            operation_callback&.call response, operation
            response
          end
        rescue StandardError => error
          if check_retry? deadline
            retry if options.retry_policy.call error
          end

          error = Google::Gax.from_error(error).new "RPC failed" if error.is_a? GRPC::BadStatus

          raise error
        end
      end

      private

      def compose_stream_proc stream_callback: nil, format_response: nil
        return unless stream_callback
        return stream_callback unless format_response

        proc { |response| stream_callback.call format_response.call response }
      end

      def calculate_deadline options
        Time.now + options.timeout
      end

      def check_retry? deadline
        deadline > Time.now
      end
    end
  end
end
