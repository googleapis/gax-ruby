require 'google/gax'

module Google
  module Gax
    class ApiCallable
      def initialize(func, settings)
        @func = func
        @settings = settings
      end

      def call(*args)
        the_func = @func

        if @settings.retry_options
          the_func = _retryable(the_func, @settings.retry_options)
        end
        if @settings.page_descriptor
          if @settings.bundler && @settings.bundle_descriptor
            raise 'ApiCallable has incompatible settings: bundling and page ' \
                  'streaming'
          end
          the_func = _page_streamable(
            the_func,
            @settings.page_descriptor.request_page_token_field,
            @settings.page_descriptor.response_page_token_field,
            @settings.page_descriptor.resource_field,
            @settings.timeout)
        else
          the_func = _add_timeout_arg(the_func, @settings.timeout)
          if @settings.bundler && @settings.bundle_descriptor
            the_func = _bundleable(the_func, @settings.bundle_descriptor,
                                   @settings.bundler)
          end
        end

        the_func.call(*args)
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
        return Enumerator.new do |y|
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
            return a_func.call(*args)
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
        return a_func.call(*updated_args)
      end
    end
  end
end
