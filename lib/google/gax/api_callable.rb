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

require 'google/gax'
require 'google/gax/errors'

module Google
  module Gax
    def create_api_call(func, settings)
      api_call = if settings.retry_options && settings.retry_options.retry_codes
                   _retryable(func, settings.retry_options)
                 else
                   _add_timeout_arg(func, settings.timeout)
                 end

      if settings.page_descriptor
        if settings.bundler && settings.bundle_descriptor
          raise 'ApiCallable has incompatible settings: ' \
              'bundling and page streaming'
        end
        return _page_streamable(
          api_call,
          settings.page_descriptor.request_page_token_field,
          settings.page_descriptor.response_page_token_field,
          settings.page_descriptor.resource_field)
      end
      if settings.bundler && settings.bundle_descriptor
        return _bundleable(api_call, settings.bundle_descriptor,
                           settings.bundler)
      end

      # return _catch_errors(api_call, config.API_ERRORS)
      _catch_errors(api_call)
    end

    def _catch_errors(a_func, errors:StandardError)
      proc do |*args|
        begin
          a_func.call(*args)
        rescue errors => err
          raise GaxError.new('RPC failed', cause: err)
        end
      end
    end

    def _bundleable(a_func, desc, bundler)
      proc do |request|
        the_id = bundling.compute_bundle_id(
          request,
          desc.request_discriminator_fields)
        return bundler.schedule(a_func, the_id, desc, request)
      end
    end

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
