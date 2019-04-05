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

module Google
  module Gax
    # rubocop:disable Metrics/ParameterLists

    # Encapsulates the call settings for an ApiCallable
    # @!attribute [r] timeout
    #   @return [Numeric]
    # @!attribute [r] page_descriptor
    #   @return [PageDescriptor]
    # @!attribute [r] page_token
    #   @return [Object]
    # @!attribute [r] bundle_descriptor
    #   @return [BundleDescriptor]
    # @!attribute [r] metadata
    #   @return [Hash]
    class CallSettings
      attr_reader :timeout, :page_descriptor, :page_token,
                  :metadata, :errors

      # @param timeout [Numeric] The client-side timeout for API calls.
      # @param page_descriptor [PageDescriptor] indicates the structure of page
      #   streaming to be performed. If set to nil, page streaming is not
      #   performed.
      # @param page_token [Object] determines the page token used in the
      #   page streaming request. If there is no page_descriptor, this has no
      #   meaning.
      # @param metadata [Hash] the request header params.
      # @param kwargs [Hash]
      #   Deprecated, if set this will be merged with the metadata field.
      # @param errors [Array<Exception>]
      #   Configures the exceptions to wrap with GaxError.
      def initialize(timeout: 30, page_descriptor: nil,
                     page_token: nil,
                     metadata: {}, kwargs: {}, errors: [])
        @timeout = timeout
        @page_descriptor = page_descriptor
        @page_token = page_token
        @metadata = metadata
        @metadata.merge!(kwargs) if kwargs && metadata
        @errors = errors
      end

      # Creates a new CallSetting instance which is based on this but merged
      # settings from options.
      # @param options [CallOptions, nil] The overriding call settings.
      # @return a new merged call settings.
      def merge(options)
        unless options
          return CallSettings.new(timeout: @timeout,
                                  page_descriptor: @page_descriptor,
                                  page_token: @page_token,
                                  metadata: @metadata,
                                  errors: @errors)
        end

        timeout = if options.timeout == :OPTION_INHERIT
                    @timeout
                  else
                    options.timeout
                  end
        page_token = if options.page_token == :OPTION_INHERIT
                       @page_token
                     else
                       options.page_token
                     end

        metadata = (metadata.dup if metadata) || {}
        metadata.update(options.metadata) if options.metadata != :OPTION_INHERIT

        CallSettings.new(timeout: timeout,
                         page_descriptor: @page_descriptor,
                         page_token: page_token,
                         metadata: metadata,
                         errors: @errors)
      end
    end

    private_constant :CallSettings

    # Encapsulates the overridable settings for a particular API call
    # @!attribute [r] timeout
    #   @return [Numeric, :OPTION_INHERIT]
    # @!attribute [r] page_token
    #   @return [Object, :OPTION_INHERIT, :INITIAL_PAGE]
    # @!attribute [r] metadata
    #   @return [Hash, :OPTION_INHERIT]
    # @!attribute [r] kwargs
    #   @return [Hash, :OPTION_INHERIT] deprecated, use metadata instead
    class CallOptions
      attr_reader :timeout, :page_token, :metadata
      alias kwargs metadata

      # @param timeout [Numeric, :OPTION_INHERIT]
      #   The client-side timeout for API calls.
      # @param page_token [Object, :OPTION_INHERIT]
      #   If set and the call is configured for page streaming, page streaming
      #   is starting with this page_token.
      # @param metadata [Hash, :OPTION_INHERIT] the request header params.
      # @param kwargs [Hash, :OPTION_INHERIT]
      #   Deprecated, if set this will be merged with the metadata field.
      def initialize(timeout: :OPTION_INHERIT,
                     page_token: :OPTION_INHERIT,
                     metadata: :OPTION_INHERIT,
                     kwargs: :OPTION_INHERIT)
        @timeout = timeout
        @page_token = page_token
        @metadata = metadata
        @metadata.merge!(kwargs) if kwargs.is_a?(Hash) && metadata.is_a?(Hash)
      end
    end

    # Describes the structure of a page-streaming call.
    class PageDescriptor < Struct.new(:request_page_token_field,
                                      :response_page_token_field,
                                      :resource_field)
    end

    # Parameters to the exponential backoff algorithm for retrying.
    class BackoffSettings < Struct.new(
      :initial_retry_delay_millis,
      :retry_delay_multiplier,
      :max_retry_delay_millis,
      :initial_rpc_timeout_millis,
      :rpc_timeout_multiplier,
      :max_rpc_timeout_millis,
      :total_timeout_millis
    )
      # @!attribute initial_retry_delay_millis
      #   @return [Numeric] the initial delay time, in milliseconds,
      #     between the completion of the first failed request and the
      #     initiation of the first retrying request.
      # @!attribute retry_delay_multiplier
      #   @return [Numeric] the multiplier by which to increase the
      #     delay time between the completion of failed requests, and
      #     the initiation of the subsequent retrying request.
      # @!attribute max_retry_delay_millis
      #   @return [Numeric] the maximum delay time, in milliseconds,
      #     between requests. When this value is reached,
      #     +retry_delay_multiplier+ will no longer be used to
      #     increase delay time.
      # @!attribute initial_rpc_timeout_millis
      #   @return [Numeric] the initial timeout parameter to the request.
      # @!attribute rpc_timeout_multiplier
      #   @return [Numeric] the multiplier by which to increase the
      #     timeout parameter between failed requests.
      # @!attribute max_rpc_timeout_millis
      #   @return [Numeric] the maximum timeout parameter, in
      #     milliseconds, for a request. When this value is reached,
      #     +rpc_timeout_multiplier+ will no longer be used to
      #     increase the timeout.
      # @!attribute total_timeout_millis
      #   @return [Numeric] the total time, in milliseconds, starting
      #     from when the initial request is sent, after which an
      #     error will be returned, regardless of the retrying
      #     attempts made meanwhile.
    end

    # Port of GRPC::GenericService.underscore that works on frozen strings.
    # Note that this function often is used on strings inside Hashes, which
    # are frozen by default, so the GRPC implementation cannot be used directly.
    #
    # TODO(geigerj): Consider whether this logic can be factored out into
    # a shared location that both gRPC and GAX can depend on in order to remove
    # the additional dependency on gRPC this introduces.
    def upper_camel_to_lower_underscore(s)
      s = s.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      s = s.gsub(/([a-z\d])([A-Z])/, '\1_\2')
      s = s.tr('-', '_')
      s = s.downcase
      s
    end

    # Constructs a dictionary mapping method names to CallSettings.
    #
    # The +client_config+ parameter is parsed from a client configuration JSON
    # file of the form:
    #
    #   {
    #     "interfaces": {
    #       "google.fake.v1.ServiceName": {
    #         "retry_codes": {
    #           "idempotent": ["UNAVAILABLE", "DEADLINE_EXCEEDED"],
    #           "non_idempotent": []
    #         },
    #         "retry_params": {
    #           "default": {
    #             "initial_retry_delay_millis": 100,
    #             "retry_delay_multiplier": 1.2,
    #             "max_retry_delay_millis": 1000,
    #             "initial_rpc_timeout_millis": 2000,
    #             "rpc_timeout_multiplier": 1.5,
    #             "max_rpc_timeout_millis": 30000,
    #             "total_timeout_millis": 45000
    #           }
    #         },
    #         "methods": {
    #           "CreateFoo": {
    #             "retry_codes_name": "idempotent",
    #             "retry_params_name": "default"
    #           },
    #           "Publish": {
    #             "retry_codes_name": "non_idempotent",
    #             "retry_params_name": "default"
    #           }
    #         }
    #       }
    #     }
    #   }
    #
    # @param service_name [String] The fully-qualified name of this
    #   service, used as a key into the client config file (in the
    #   example above, this value should be
    #   'google.fake.v1.ServiceName').
    # @param client_config [Hash] A hash parsed from the standard
    #   API client config file.
    # @param config_overrides [Hash] A hash in the same structure of
    #   client_config to override the settings.
    # @param timeout [Numeric] The timeout parameter for all API calls
    #   in this dictionary.
    # @param page_descriptors [Hash{String => PageDescriptor}] A
    #   dictionary of method names to PageDescriptor objects for
    #   methods that are page streaming-enabled.
    # @param metadata [Hash]
    #   Header params to be passed to the API call.
    # @param kwargs [Hash]
    #   Deprecated, same as metadata and if present will be merged with metadata
    # @param errors [Array<Exception>]
    #   Configures the exceptions to wrap with GaxError.
    # @return [CallSettings, nil] A CallSettings, or nil if the
    #   service is not found in the config.
    def construct_settings(service_name, client_config, _config_overrides,
                           timeout,
                           page_descriptors: {}, metadata: {}, kwargs: {},
                           errors: [])
      defaults = {}

      metadata.merge!(kwargs) if kwargs.is_a?(Hash) && metadata.is_a?(Hash)

      service_config = client_config.fetch('interfaces', {})[service_name]
      return nil unless service_config

      service_config['methods'].each_pair do |method_name, _method_config|
        snake_name = upper_camel_to_lower_underscore(method_name)

        defaults[snake_name] = CallSettings.new(
          timeout: timeout,
          page_descriptor: page_descriptors[snake_name],
          metadata: metadata,
          errors: errors
        )
      end

      defaults
    end

    module_function :construct_settings,
                    :upper_camel_to_lower_underscore
    private_class_method :upper_camel_to_lower_underscore
  end
end
