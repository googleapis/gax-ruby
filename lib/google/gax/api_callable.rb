require 'google/gax'
require 'google/gax/errors'

module Google
  module Gax
    def create_api_call(func, settings)
      if settings.retry_options && settings.retry_options.retry_codes
          api_call = _retryable(func, settings.retry_options)
      else
        api_call = _add_timeout_arg(func, settings.timeout)
      end

      if settings.page_descriptor
        if settings.bundler && settings.bundle_descriptor
          raise 'ApiCallable has incompatible settings: ' \
              'bundling and page streaming'
          return _page_streamable(
              api_call,
              settings.page_descriptor.request_page_token_field,
              settings.page_descriptor.response_page_token_field,
              settings.page_descriptor.resource_field)
        end
      end
      if settings.bundler && settings.bundle_descriptor
        return _bundleable(api_call, settings.bundle_descriptor,
                           settings.bundler)
      end

      # return _catch_errors(api_call, config.API_ERRORS)
      _catch_errors(api_call, nil)
    end

    def _catch_errors(a_func, errors)
      proc do |*args|
        begin
          a_func.call(*args)
        rescue StandardError => err  # errors
          fail GaxError.new('RPC failed', cause:err)
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
      resource_field,
      timeout)
      with_timeout = _add_timeout_arg(a_func, timeout)
      proc do |*args|
        request = args[0]
        Enumerator.new do |y|
          loop do
            response = with_timeout.call(request)
            response.send(resource_field).each do |obj|
              y << obj
            end
            next_page_token = response.send(response_page_token_field)
            break unless next_page_token
            request.send(request_page_token_field + '=', next_page_token)
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
