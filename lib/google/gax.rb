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

require 'google/gax/api_callable'
require 'google/gax/constants'
require 'google/gax/errors'
require 'google/gax/path_template'
require 'google/gax/settings'
require 'google/gax/version'

module Google
  # Gax defines Google API extensions
  module Gax
    # rubocop:disable Metrics/ParameterLists

    # Encapsulates the call settings for an ApiCallable
    # @!attribute [r] timeout
    #   @return [Numeric]
    # @!attribute [r] retry_options
    #   @return [RetryOptions]
    # @!attribute [r] page_descriptor
    #   @return [PageDescriptor]
    # @!attribute [r] page_token
    #   @return [Object]
    # @!attribute [r] bundle_descriptor
    #   @return [BundleDescriptor]
    # @!attribute [r] kwargs
    #   @return [Hash]
    class CallSettings
      attr_reader :timeout, :retry_options, :page_descriptor, :page_token,
                  :bundler, :bundle_descriptor, :kwargs, :errors

      # @param timeout [Numeric] The client-side timeout for API calls. This
      #   parameter is ignored for retrying calls.
      # @param retry_options [RetryOptions] The configuration for retrying upon
      #   transient error. If set to nil, this call will not retry.
      # @param page_descriptor [PageDescriptor] indicates the structure of page
      #   streaming to be performed. If set to nil, page streaming is not
      #   performed.
      # @param page_token [Object] determines the page token used in the
      #   page streaming request. If there is no page_descriptor, this has no
      #   meaning.
      # @param bundler orchestrates bundling. If nil, bundling is not
      #   performed.
      # @param bundle_descriptor [BundleDescriptor] indicates the structure of
      #   the bundle. If nil, bundling is not performed.
      # @param kwargs [Hash]
      #   Additional keyword argments to be passed to the API call.
      # @param errors [Array<Exception>]
      #   Configures the exceptions to wrap with GaxError.
      def initialize(timeout: 30, retry_options: nil, page_descriptor: nil,
                     page_token: nil, bundler: nil, bundle_descriptor: nil,
                     kwargs: {}, errors: [])
        @timeout = timeout
        @retry_options = retry_options
        @page_descriptor = page_descriptor
        @page_token = page_token
        @bundler = bundler
        @bundle_descriptor = bundle_descriptor
        @kwargs = kwargs
        @errors = errors
      end

      # @return true when it has retry codes.
      def retry_codes?
        @retry_options && @retry_options.retry_codes
      end

      # @return true when it has valid bundler configuration.
      def bundler?
        @bundler && @bundle_descriptor
      end

      # Creates a new CallSetting instance which is based on this but merged
      # settings from options.
      # @param options [CallOptions, nil] The overriding call settings.
      # @return a new merged call settings.
      def merge(options)
        unless options
          return CallSettings.new(timeout: @timeout,
                                  retry_options: @retry_options,
                                  page_descriptor: @page_descriptor,
                                  page_token: @page_token,
                                  bundler: @bundler,
                                  bundle_descriptor: @bundle_descriptor,
                                  kwargs: @kwargs,
                                  errors: @errors)
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
        page_token = if options.page_token == :OPTION_INHERIT
                       @page_token
                     else
                       options.page_token
                     end

        kwargs = @kwargs.dup
        kwargs.update(options.kwargs) if options.kwargs != :OPTION_INHERIT

        CallSettings.new(timeout: timeout,
                         retry_options: retry_options,
                         page_descriptor: @page_descriptor,
                         page_token: page_token,
                         bundler: @bundler,
                         bundle_descriptor: @bundle_descriptor,
                         kwargs: kwargs,
                         errors: @errors)
      end
    end

    private_constant :CallSettings
  end
end
