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

require "google/gax/api_call/retry_policy"
require "google/gax/call_options"
require "google/gax/errors"

module Google
  module Gax
    class ApiCall
      ##
      # Converts an RPC call into an API call.
      #
      # In typical usage, `stub_method` will be a proc used to make an RPC
      # request. This will mostly likely be a bound method from a request Stub
      # used to make an RPC call.
      #
      # The result is created by applying a series of function decorators
      # defined in this module to `stub_method`.
      #
      # The result is another proc which has the same signature as the original.
      #
      # @param stub_method [Proc] used to make a bare rpc call
      # @param timeout [Numeric] client-side timeout for API calls
      # @param metadata [Hash] request headers
      # @param retry_policy [Hash] the settings for error retry, will be merged
      #   to the {CallOptions#retry_policy} object if supported.
      # @param params_extractor [Proc] extracts routing header params from the
      #   request
      # @param exception_transformer [Proc] if an API exception occurs this
      #   transformer is given the original exception for custom processing
      #   instead of raising the error directly
      def initialize stub_method, timeout: nil, metadata: nil,
                     retry_policy: nil, params_extractor: nil,
                     exception_transformer: nil
        @stub_method           = stub_method
        @timeout               = timeout
        @metadata              = metadata
        @retry_policy          = retry_policy
        @params_extractor      = params_extractor
        @exception_transformer = exception_transformer
      end

      ##
      # Invoke the API call.
      #
      # @param request [Object] The request object.
      # @param options [CallOption, Hash] The options for making the API call.
      # @param block [Proc] The proc to call when the API call is made.
      #
      def call request, options: nil, &block
        options = init_call_options options

        apply_params_extractor! request, options

        deadline = calculate_deadline options

        begin
          op = @stub_method.call(request, deadline:  deadline,
                                          metadata:  options.metadata,
                                          return_op: true)
          res = op.execute
          yield op if block
          res
        rescue StandardError => error
          if check_retry? deadline
            retry if options.retry_policy.call error
          end

          error = Google::Gax.from_error(error).new "RPC failed" if error.is_a? GRPC::BadStatus

          raise error if @exception_transformer.nil?
          @exception_transformer.call error
        end
      end

      private

      def init_call_options options
        options = CallOptions.new options.to_h if options.respond_to? :to_h
        options.merge(timeout: @timeout, metadata: @metadata,
                      retry_policy: @retry_policy)
        options
      end

      def apply_params_extractor! request, options
        return if @params_extractor.nil?

        routing_header = calculate_routing_header request, @params_extractor
        options.metadata["x-goog-request-params"] = routing_header
      end

      def calculate_routing_header request, params_extractor
        params = params_extractor.call request
        params.map { |k, v| "#{k}=#{v}" }.join("&")
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
