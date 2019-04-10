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

require 'time'

require 'google/gax/errors'

module Google
  module Gax
    # Converts an rpc call into an API call governed by the settings.
    #
    # In typical usage, +func+ will be a proc used to make an rpc request.
    # This will mostly likely be a bound method from a request stub used to make
    # an rpc call.
    #
    # The result is created by applying a series of function decorators
    # defined in this module to +func+.  +settings+ is used to determine
    # which function decorators to apply.
    #
    # The result is another proc which for most values of +settings+ has the
    # same signature as the original.
    #
    # @param func [Proc] used to make a bare rpc call
    # @param timeout [Numeric] client-side timeout for API calls
    # @param metadata [Hash]  request headers
    # @param params_extractor [Proc] extracts routing header params from the
    #   request
    # @param exception_transformer [Proc] if an API exception occurs this
    #   transformer is given the original exception for custom processing
    #   instead of raising the error directly
    # @return [Proc] A bound method on a request stub used to make an rpc call.
    #   The argumentd for the bound method are:
    #
    #   * request - Request object
    #   * options - CallOptions object
    #   * block named argument - Proc object for yielding the operation
    def create_api_call(func, timeout: 60, metadata: {},
                        params_extractor: nil, exception_transformer: nil)
      proc do |request, options = nil, block = nil|
        options = CallOptions.new if options.nil?

        options.timeout  = timeout  if options.timeout  == :OPTION_INHERIT
        options.metadata = metadata if options.metadata == :OPTION_INHERIT

        if params_extractor
          params = params_extractor.call(request)
          routing_header = params.map { |k, v| "#{k}=#{v}" }.join('&')
          options.metadata['x-goog-request-params'] = routing_header
        end

        begin
          op = func.call(request, deadline: Time.now + options.timeout,
                                  metadata: options.metadata,
                                  return_op: true)
          res = op.execute
          block.call op if block
          res
        rescue GRPC::BadStatus => grpc_error
          error_class = Google::Gax.from_error(grpc_error)
          error = error_class.new('RPC failed')
          raise error if exception_transformer.nil?
          exception_transformer.call error
        rescue StandardError => error
          raise error if exception_transformer.nil?
          exception_transformer.call error
        end
      end
    end

    module_function :create_api_call
  end
end
