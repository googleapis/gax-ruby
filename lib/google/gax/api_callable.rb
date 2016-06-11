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
require 'google/gax/grpc'

# rubocop:disable Metrics/ModuleLength

module Google
  module Gax
    MILLIS_PER_SECOND = 1000.0

    # A class to provide the Enumerable interface for page-streaming method.
    # PagedEnumerable assumes that the API call returns a message for a page
    # which holds a list of resources and the token to the next page.
    #
    # PagedEnumerable provides the enumerations over the resource data,
    # and also provides the enumerations over the pages themselves.
    #
    # Example 1: normal iteration over resources.
    #   paged_enumerable.each { |resource| puts resource }
    #
    # Example 2: per-page iteration.
    #   paged_enumerable.each_page { |page| puts page }
    #
    # Example 3: Enumerable over pages.
    #   pages = paged_enumerable.enum_for(:each_page).to_a
    #
    # Example 4: more exact operations over pages.
    #   while some_condition()
    #     page = paged_enumerable.page
    #     do_something(page)
    #     break if paged_enumerable.next_page?
    #     paged_enumerable.next_page
    #   end
    #
    # @attribute [r] page
    #   @return [Page] The current page object.
    # @attribute [r] response
    #   @return [Object] The current response object.
    # @attribute [r] page_token
    #   @return [Object] The page token to be used for the next API call.
    class PagedEnumerable
      # A class to represent a page in a PagedEnumerable. This also implements
      # Enumerable, so it can iterate over the resource elements.
      #
      # @attribute [r] response
      #   @return [Object] the actual response object.
      # @attribute [r] next_page_token
      #   @return [Object] the page token to be used for the next API call.
      class Page
        include Enumerable
        attr_reader :response

        # @param response [Object]
        #   The response object for the page.
        # @param response_page_token_field [String]
        #   The name of the field in response which holds the next page token.
        # @param resource_field [String]
        #   The name of the field in response which holds the resources.
        def initialize(response, response_page_token_field, resource_field)
          @response = response
          @response_page_token_field = response_page_token_field
          @resource_field = resource_field
        end

        # Creates another instance of Page with replacing the new response.
        # @param response [Object] a new response object.
        def dup_with(response)
          self.class.new(response, @response_page_token_field, @resource_field)
        end

        # Iterate over the resources.
        # @yield [Object] Gives the resource objects in the page.
        def each
          @response[@resource_field].each do |obj|
            yield obj
          end
        end

        def next_page_token
          @response[@response_page_token_field]
        end

        # Truthiness of next_page_token.
        def next_page_token?
          !@response.nil? && !next_page_token.nil? && next_page_token != 0 &&
            (!next_page_token.respond_to?(:empty?) || !next_page_token.empty?)
        end
      end

      include Enumerable
      attr_reader :page

      # @param request_page_token_field [String]
      #   The name of the field in request which will have the page token.
      # @param response_page_token_field [String]
      #   The name of the field in the response which holds the next page token.
      # @param resource_field [String]
      #   The name of the field in the response which holds the resources.
      def initialize(request_page_token_field,
                     response_page_token_field, resource_field)
        @request_page_token_field = request_page_token_field
        @page = Page.new(nil, response_page_token_field, resource_field)
      end

      # Initiate the streaming with the requests and keywords.
      # @param a_func [Proc]
      #   A proc to update the response object.
      # @param request [Object]
      #   The initial request object.
      # @param settings [CallSettings]
      #   The call settings to enumerate pages.
      # @param kwargs [Hash]
      #   Other keyword arguments to be passed to a_func.
      # @return [PagedEnumerable]
      #   returning self for further uses.
      def start(api_call, request, settings)
        @func = api_call
        @request = request
        page_token = settings.page_token
        @request[@request_page_token_field] = page_token if page_token
        @page = @page.dup_with(@func.call(@request))
        self
      end

      # True if it's already started.
      def started?
        !@request.nil?
      end

      # Iterate over the resources.
      # @yield [Object] Gives the resource objects in the stream.
      # @raise [RuntimeError] if it's not started yet.
      def each
        each_page do |page|
          page.each do |obj|
            yield obj
          end
        end
      end

      # Iterate over the pages.
      # @yield [Page] Gives the pages in the stream.
      # @raise [GaxError] if it's not started yet.
      def each_page
        raise GaxError, 'not started!' unless started?
        yield @page
        loop do
          break unless next_page?
          yield next_page
        end
      end

      # True if it has the next page.
      def next_page?
        @page.next_page_token?
      end

      # Update the response in the current page.
      # @return [Page] the new page object.
      def next_page
        return unless next_page?
        @request[@request_page_token_field] = @page.next_page_token
        @page = @page.dup_with(@func.call(@request))
      end

      def response
        @page.response
      end

      def page_token
        @page.next_page_token
      end
    end

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
    # @param func [Proc] used to make a bare rpc call
    # @param settings [CallSettings provides the settings for this call
    # @return [Proc] a bound method on a request stub used to make an rpc call
    # @raise [StandardError] if +settings+ has incompatible values,
    #   e.g, if bundling and page_streaming are both configured
    def create_api_call(func, settings)
      api_caller = proc do |api_call, request|
        api_call.call(request)
      end

      if settings.page_descriptor
        if settings.bundler?
          raise 'ApiCallable has incompatible settings: ' \
              'bundling and page streaming'
        end
        page_descriptor = settings.page_descriptor
        api_caller = page_streamable(page_descriptor.request_page_token_field,
                                     page_descriptor.response_page_token_field,
                                     page_descriptor.resource_field)
      elsif settings.bundler?
        api_caller = bundleable(settings.bundle_descriptor)
      end

      proc do |request, options = nil|
        this_settings = settings.merge(options)
        api_call = if settings.retry_codes?
                     retryable(func, this_settings.retry_options,
                               this_settings.kwargs)
                   else
                     add_timeout_arg(func, this_settings.timeout,
                                     this_settings.kwargs)
                   end
        api_call = catch_errors(api_call)
        api_caller.call(api_call, request, this_settings)
      end
    end

    # Updates a_func to wrap exceptions with GaxError
    #
    # @param a_func [Proc]
    # @param errors [Array<Exception>] Configures the exceptions to wrap.
    # @return [Proc] A proc that will wrap certain exceptions with GaxError
    def catch_errors(a_func, errors: Grpc::API_ERRORS)
      proc do |request|
        begin
          a_func.call(request)
        rescue *errors
          raise GaxError, 'RPC failed'
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
    # @param a_func [Proc] an API call that supports bundling.
    # @param desc [BundleDescriptor] describes the bundling that
    #   +a_func+ supports.
    # @param bundler orchestrates bundling.
    # @return [Proc] A proc takes the API call's request and returns
    #   an Event object.
    def bundleable(desc)
      proc do |api_call, request, settings|
        return api_call(request) unless settings.bundler
        the_id = bundling.compute_bundle_id(request,
                                            desc.request_discriminator_fields)
        return bundler.schedule(api_call, the_id, desc, request)
      end
    end

    # Creates a proc that yields an iterable to performs page-streaming.
    #
    # @param a_func [Proc] an API call that is page streaming.
    # @param request_page_token_field [String] The field of the page
    #   token in the request.
    # @param response_page_token_field [String] The field of the next
    #   page token in the response.
    # @param resource_field [String] The field to be streamed.
    # @param page_token [Object] The page_token for the first page to be
    #   streamed, or nil.
    # @return [Proc] A proc that returns an iterable over the specified field.
    def page_streamable(request_page_token_field,
                        response_page_token_field,
                        resource_field)
      enumerable = PagedEnumerable.new(request_page_token_field,
                                       response_page_token_field,
                                       resource_field)
      enumerable.method(:start)
    end

    # rubocop:disable Metrics/MethodLength

    # Creates a proc equivalent to a_func, but that retries on certain
    # exceptions.
    #
    # @param a_func [Proc]
    # @param retry_options [RetryOptions] Configures the exceptions
    #   upon which the proc should retry, and the parameters to the
    #   exponential backoff retry algorithm.
    # @return [Proc] A proc that will retry on exception.
    def retryable(a_func, retry_options, kwargs)
      delay_mult = retry_options.backoff_settings.retry_delay_multiplier
      max_delay = (retry_options.backoff_settings.max_retry_delay_millis /
                   MILLIS_PER_SECOND)
      timeout_mult = retry_options.backoff_settings.rpc_timeout_multiplier
      max_timeout = (retry_options.backoff_settings.max_rpc_timeout_millis /
                     MILLIS_PER_SECOND)
      total_timeout = (retry_options.backoff_settings.total_timeout_millis /
                       MILLIS_PER_SECOND)

      proc do |request|
        delay = retry_options.backoff_settings.initial_retry_delay_millis
        timeout = (retry_options.backoff_settings.initial_rpc_timeout_millis /
                   MILLIS_PER_SECOND)
        result = nil
        now = Time.now
        deadline = now + total_timeout

        loop do
          begin
            result = add_timeout_arg(a_func, timeout, kwargs).call(request)
            break
          rescue => exception
            unless exception.respond_to?(:code) &&
                   retry_options.retry_codes.include?(exception.code)
              raise RetryError, 'Exception occurred in retry method that ' \
                'was not classified as transient'
            end
            sleep(rand(delay) / MILLIS_PER_SECOND)
            now = Time.now
            delay = [delay * delay_mult, max_delay].min
            timeout = [timeout * timeout_mult, max_timeout, deadline - now].min
            if now >= deadline
              raise RetryError, 'Retry total timeout exceeded with exception'
            end
          end
        end
        result
      end
    end

    # Updates +a_func+ so that it gets called with the timeout as its final arg.
    #
    # This converts a proc, a_func, into another proc with an additional
    # positional arg.
    #
    # @param a_func [Proc] a proc to be updated
    # @param timeout [Numeric] to be added to the original proc as it
    #   final positional arg.
    # @return [Proc] the original proc updated to the timeout arg
    def add_timeout_arg(a_func, timeout, kwargs)
      proc do |request|
        kwargs[:timeout] = timeout
        a_func.call(request, **kwargs)
      end
    end

    module_function :create_api_call, :catch_errors, :bundleable,
                    :page_streamable, :retryable, :add_timeout_arg
    private_class_method :catch_errors, :bundleable, :page_streamable,
                         :retryable, :add_timeout_arg
  end
end
