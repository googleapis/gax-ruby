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

require 'google/gax/errors'
require 'google/gax/grpc'

module Google
  module Gax
    # rubocop:disable Metrics/AbcSize

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
    # same signature as the original. Only when +settings+ configures bundling
    # does the signature change.
    #
    # Args::
    #   +func+:: is used to make a bare rpc call
    #   +settings+:: provides the settings for this call
    # Returns::
    #   a bound method on a request stub used to make an rpc call
    # Raises::
    #   StandardError:: if +settings+ has incompatible values, e.g, if bundling
    #                   and page_streaming are both configured
    def create_api_call(func, settings)
      api_call = if settings.retry_codes?
                   _retryable(func, settings.retry_options)
                 else
                   _add_timeout_arg(func, settings.timeout)
                 end

      if settings.page_descriptor
        if settings.bundler?
          raise 'ApiCallable has incompatible settings: ' \
              'bundling and page streaming'
        end
        return _page_streamable(
          api_call,
          settings.page_descriptor.request_page_token_field,
          settings.page_descriptor.response_page_token_field,
          settings.page_descriptor.resource_field)
      end
      if settings.bundler?
        return _bundleable(api_call, settings.bundle_descriptor,
                           settings.bundler)
      end

      _catch_errors(api_call)
    end

    # Updates a_func to wrap exceptions with GaxError
    #
    # Args::
    #   a_func:: A proc.
    #   errors:: Configures the exceptions to wrap.
    # Returns::
    #   A proc that will wrap certain exceptions with GaxError
    def _catch_errors(a_func, errors: Grpc::API_ERRORS)
      proc do |*args|
        begin
          a_func.call(*args)
        rescue => err
          if errors.any? { |eclass| err.is_a? eclass }
            raise GaxError.new('RPC failed', cause: err)
          else
            raise err
          end
        end
      end
    end

    # Creates a proc that transforms an API call into a bundling call.
    #
    # It transform a_func from an API call that receives the requests and
    # returns the response into a proc that receives the same request, and
    # returns a +Google::Gax::Bundling::Event+.
    #
    # The returned Event object can be used to obtain the eventual result of the
    # bundled call.
    #
    # Args::
    #   +a_func+:: an API call that supports bundling.
    #   +desc+:: describes the bundling that +a_func+ supports.
    #   +bundler+:: orchestrates bundling.
    #
    # Returns::
    #   A proc takes the API call's request and returns an Event object.
    def _bundleable(a_func, desc, bundler)
      proc do |request|
        the_id = bundling.compute_bundle_id(
          request,
          desc.request_discriminator_fields)
        return bundler.schedule(a_func, the_id, desc, request)
      end
    end

    # Creates a proc that yields an iterable to performs page-streaming.
    #
    # Args::
    #   +a_func+:: an API call that is page streaming.
    #   +request_page_token_field+:: The field of the page token in the request.
    #   +response_page_token_field+::
    #     The field of the next page token in the response.
    #   +resource_field+:: The field to be streamed.
    #
    # Returns::
    #   A proc that returns an iterable over the specified field.
    def _page_streamable(
      a_func,
      request_page_token_field,
      response_page_token_field,
      resource_field)
      proc do |request|
        Enumerator.new do |y|
          loop do
            response = a_func.call(request)
            response.send(resource_field).each do |obj|
              y << obj
            end
            next_page_token = response.send(response_page_token_field)
            break unless next_page_token
            request.send(request_page_token_field.to_s + '=', next_page_token)
          end
        end
      end
    end

    # Creates a proc equivalent to a_func, but that retries on certain
    # exceptions.
    #
    # Args::
    #   +a_func+:: A proc.
    #   +retry_options+::
    #     Configures the exceptions upon which the proc should retry,
    #     and the parameters to the exponential backoff retry algorithm.
    #
    # Returns::
    #   A proc that will retry on exception.
    def _retryable(a_func, retry_options)
      max_attempts = (retry_options.backoff_settings.total_timeout_millis /
        retry_options.backoff_settings.initial_rpc_timeout_millis).to_i
      proc do |*args|
        attempt_count = 0
        loop do
          begin
            a_func.call(*args)
          rescue
            attempt_count += 1
            next if attempt_count < max_attempts
            raise
          end
        end
      end
    end

    # Updates +a_func+ so that it gets called with the timeout as its final arg.
    #
    # This converts a proc, a_func, into another proc with an additional
    # positional arg.
    #
    # Args::
    #   +a_func+:: a proc to be updated
    #   +timeout+:: to be added to the original proc as it final positional arg.
    #
    # Returns::
    #   the original proc updated to the timeout arg
    def _add_timeout_arg(a_func, timeout)
      proc do |*args|
        updated_args = args + [timeout]
        a_func.call(*updated_args)
      end
    end

    module_function :create_api_call, :_catch_errors, :_bundleable,
                    :_page_streamable, :_retryable, :_add_timeout_arg
  end
end
