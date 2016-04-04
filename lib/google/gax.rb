# Copyright 2015, Google Inc.
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
require 'google/gax/version'

module Google
  module Gax
    # Encapsulates the call settings for an ApiCallable
    class CallSettings
      attr_reader :timeout, :retry_options, :page_descriptor, :bundler,
                  :bundle_descriptor

      # +timeout+:: The client-side timeout for API calls. This
      #             parameter is ignored for retrying calls.
      # +retry_options+:: The configuration for retrying upon transient
      #                   error. If set to None, this call will not retry.
      # +page_descriptor+:: indicates the structure of page
      #                     streaming to be performed. If set to None,
      #                     page streaming is not performed.
      # +bundler+:: orchestrates bundling. If None, bundling is not performed.
      # +bundle_descriptor+:: indicates the structure of the bundle.
      #                       If None, bundling is not performed.
      def initialize(
          timeout: 30, retry_options: nil, page_descriptor: nil,
          bundler: nil, bundle_descriptor: nil)
        @timeout = timeout
        @retry_options = retry_options
        @page_descriptor = page_descriptor
        @bundler = bundler
        @bundle_descriptor = bundle_descriptor
      end

      def merge(options)
        unless options
          return CallSettings.new(
            timeout: @timeout,
            retry_options: @retry_options,
            page_descriptor: @page_descriptor,
            bundler: @bundler,
            bundle_descriptor: @bundle_descriptor)
        end

        timeout = if options.timeout == :OPTION_INHERIT
                    @timeout
                  else
                    options.timeout
                  end
        retry_options = if options.retry_options == :OPTION_INHERIT
                          @retry_options
                        else
                          options.retry_options
                        end
        if options.is_page_descriptor == :OPTION_INHERIT
          page_descriptor = @page_descriptor
        end

        CallSettings.new(
          timeout: timeout,
          retry_options: retry_options,
          page_descriptor: page_descriptor,
          bundler: @bundler,
          bundle_descriptor: @bundle_descriptor)
      end
    end

    # Encapsulates the overridable settings for a particular API call
    class CallOptions
      attr_reader :timeout, :retry, :is_page_streaming

      # +timeout+:: The client-side timeout for API calls.
      # +retry+:: The configuration for retrying upon transient error.
      #           If set to None, this call will not retry.
      # +is_page_streaming+:: If set and the call is configured for page
      #                       streaming, page streaming is performed.
      def initialize(
        timeout: :OPTION_INHERIT,
        retry_options: :OPTION_INHERIT,
        is_page_streaming: :OPTION_INHERIT)
        @timeout = timeout
        @retry_options = retry_options
        @is_page_streaming = is_page_streaming
      end
    end

    # Describes the structure of a page-streaming call.
    PageDescriptor = Struct.new(
      :request_page_token_field,
      :response_page_token_field,
      :resource_field)

    # Per-call configurable settings for retrying upon transient failure.
    #
    # +retry_codes+:: a list of exceptions upon which a retry should be
    #                 attempted.
    # +backoff_settings+:: a BackoffSettings object configuring the retry
    #                      exponential backoff algorithm.
    RetryOptions = Struct.new(:retry_codes, :backoff_settings)

    # Parameters to the exponential backoff algorithm for retrying.
    #
    # +initial_retry_delay_millis+:: the initial delay time, in milliseconds,
    #                                between the completion of the first failed
    #                                request and the initiation of the first
    #                                retrying request.
    # +retry_delay_multiplier+:: the multiplier by which to increase the delay
    #                            time between the completion of failed
    #                            requests, and the initiation of the subsequent
    #                            retrying request.
    # +max_retry_delay_millis+:: the maximum delay time, in milliseconds,
    #                            between requests. When this value is reached,
    #                            +retry_delay_multiplier+ will no longer be
    #                            used to increase delay time.
    # +initial_rpc_timeout_millis+:: the initial timeout parameter to the
    #                                request.
    # +rpc_timeout_multiplier+:: the multiplier by which to increase the
    #                            timeout parameter between failed requests.
    # +max_rpc_timeout_millis+:: the maximum timeout parameter, in milliseconds,
    #                            for a request. When this value is reached,
    #                            +rpc_timeout_multiplier+ will no longer be
    #                            used to increase the timeout.
    # +total_timeout_millis+:: the total time, in milliseconds, starting from
    #                          when the initial request is sent, after which an
    #                          error will be returned, regardless of the
    #                          retrying attempts made meanwhile.
    BackoffSettings = Struct.new(
      :initial_retry_delay_millis,
      :retry_delay_multiplier,
      :max_retry_delay_millis,
      :initial_rpc_timeout_millis,
      :rpc_timeout_multiplier,
      :max_rpc_timeout_millis,
      :total_timeout_millis)

    # Describes the structure of bundled call.
    #
    # request_discriminator_fields may include '.' as a separator, which is
    # used to indicate object traversal.  This allows fields in nested objects
    # to be
    # used to determine what requests to bundle.
    #
    # +bundled_field+:: the repeated field in the request message that
    #                   will have its elements aggregated by bundling
    # +request_discriminator_fields+:: a list of fields in the
    #                                  target request message class that are
    #                                  used to determine which messages should
    #                                  be bundled together.
    # +subresponse_field+:: an optional field, when present it indicates the
    #                       field in the response message that should be used
    #                       to demultiplex the response into multiple response
    #                       messages.
    BundleDescriptor = Struct.new(
      :bundled_field,
      :request_desicriminator_fields,
      :subresponse_field)

    # Holds values used to configure bundling.
    #
    # The xxx_threshold attributes are used to configure when the bundled
    # request should be made.
    #
    # +element_count_threshold+:: the bundled request will be sent once the
    #                             count of outstanding elements in the repeated
    #                             field reaches this value.
    # +element_count_limit+:: represents a hard limit on the number of elements
    #                         in the repeated field of the bundle; if adding a
    #                         request to a bundle would exceed this value, the
    #                         bundle is sent and the new request is added to a
    #                         fresh bundle. It is invalid for a single request
    #                         to exceed this limit.
    # +request_byte_threshold+:: the bundled request will be sent once the
    #                            count of bytes in the request reaches this
    #                            value. Note that this value is pessimistically
    #                            approximated by summing the bytesizes of the
    #                            elements in the repeated field, and therefore
    #                            may be an under-approximation.
    # +request_byte_limit+:: represents a hard limit on the size of the bundled
    #                        request; if adding a request to a bundle would
    #                        exceed this value, the bundle is sent and the new
    #                        request is added to a fresh bundle. It is invalid
    #                        for a single request to exceed this limit. Note
    #                        that this value is pessimistically approximated by
    #                        summing the bytesizes of the elements in the
    #                        repeated field, with a buffer applied to
    #                        correspond to the resulting under-approximation.
    # +delay_threshold+:: the bundled request will be sent this amount of time
    #                     after the first element in the bundle was added to
    #                     it.
    BundleOptions = Struct.new(
      :message_count_threshold,
      :message_bytesize_threshold,
      :delay_threshold) do
      def intiialize(
        message_count_threshold: 0,
        message_bytesize_threshold: 0,
        delay_threshold: 0)
        super(
          message_count_threshold,
          message_bytesize_threshold,
          delay_threshold)
      end
    end
  end
end
