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
    # @param settings [CallSettings] provides the settings for this call
    # @param params_extractor [Proc] extracts routing header params from the
    #   request
    # @param exception_transformer [Proc] if an API exception occurs this
    #   transformer is given the original exception for custom processing
    #   instead of raising the error directly
    # @return [Proc] a bound method on a request stub used to make an rpc call
    def create_api_call(func, settings, params_extractor: nil,
                        exception_transformer: nil)
      api_caller = proc do |api_call, request, _settings, block|
        api_call.call(request, block)
      end

      proc do |request, options = nil, &block|
        this_settings = settings.merge(options)
        if params_extractor
          params = params_extractor.call(request)
          this_settings = with_routing_header(this_settings, params)
        end
        api_call = add_timeout_arg(func, this_settings.timeout,
                                   this_settings.metadata)
        begin
          api_caller.call(api_call, request, this_settings, block)
        rescue *settings.errors => e
          error_class = Google::Gax.from_error(e)
          error = error_class.new('RPC failed')
          raise error if exception_transformer.nil?
          exception_transformer.call error
        rescue StandardError => error
          raise error if exception_transformer.nil?
          exception_transformer.call error
        end
      end
    end

    # Create a new CallSettings with the routing metadata from the request
    # header params merged with the given settings.
    #
    # @param settings [CallSettings] the settings for an API call.
    # @param params [Hash] the request header params.
    # @return [CallSettings] a new merged settings.
    def with_routing_header(settings, params)
      routing_header = params.map { |k, v| "#{k}=#{v}" }.join('&')
      options = CallOptions.new(
        metadata: { 'x-goog-request-params' => routing_header }
      )
      settings.merge(options)
    end

    # Updates +a_func+ so that it gets called with the timeout as its final arg.
    #
    # This converts a proc, a_func, into another proc with an additional
    # positional arg.
    #
    # @param a_func [Proc] a proc to be updated
    # @param timeout [Numeric] to be added to the original proc as it
    #   final positional arg.
    # @param metadata [Hash] request metadata headers
    # @return [Proc] the original proc updated to the timeout arg
    def add_timeout_arg(a_func, timeout, metadata)
      proc do |request, block|
        op = a_func.call(request,
                         deadline: Time.now + timeout,
                         metadata: metadata,
                         return_op: true)
        res = op.execute
        block.call op if block
        res
      end
    end

    module_function :create_api_call,
                    :with_routing_header,
                    :add_timeout_arg
    private_class_method :with_routing_header, :add_timeout_arg
  end
end
