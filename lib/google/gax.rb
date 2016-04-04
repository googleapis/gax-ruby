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

module Google
  module Gax
    class CallSettings
      attr_reader :timeout, :retry_options, :page_descriptor, :bundler,
                  :bundle_descriptor

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

        timeout = (options.timeout == :OPTION_INHERIT) ?
          @timeout : options.timeout
        retry_options = (options.retry_options == :OPTION_INHERIT) ?
          @retry : options.retry_options
        page_descriptor = (options.is_page_descriptor == :OPTION_INHERIT) ?
          @page_descriptor : nil

        CallSettings.new(
          timeout: timeout,
          retry_options: retry_options,
          page_descriptor: page_descriptor,
          bundler: @bundler,
          bundle_descriptor: @bundle_descriptor)
      end
    end

    class CallOptions
      attr_reader :timeout, :retry, :is_page_streaming

      def initialize(
        timeout: :OPTION_INHERIT,
        retry_options: :OPTION_INHERIT,
        is_page_streaming: :OPTION_INHERIT)
        @timeout = timeout
        @retry_options = retry_options
        @is_page_streaming = is_page_streaming
      end
    end

    PageDescriptor = Struct.new(
      :request_page_token_field,
      :response_page_token_field,
      :resource_field)

    RetryOptions = Struct.new(:retry_codes, :backoff_settings)

    BackoffSettings = Struct.new(
      :initial_retry_delay_millis,
      :retry_delay_multiplier,
      :max_retry_delay_millis,
      :initial_rpc_timeout_millis,
      :rpc_timeout_multiplier,
      :max_rpc_timeout_millis,
      :total_timeout_millis)

    BundleDescriptor = Struct.new(
      :bundled_field,
      :request_desicriminator_fields,
      :subresponse_field)

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
