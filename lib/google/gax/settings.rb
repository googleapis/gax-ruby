# Copyright 2016, Google LLC
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
#     * Neither the name of Google LLC nor the names of its
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
    # @!attribute [r] retry_options
    #   @return [RetryOptions]
    # @!attribute [r] page_descriptor
    #   @return [PageDescriptor]
    # @!attribute [r] page_token
    #   @return [Object]
    # @!attribute [r] bundle_descriptor
    #   @return [BundleDescriptor]
    # @!attribute [r] metadata
    #   @return [Hash]
    class CallSettings
      attr_reader :timeout, :retry_options, :page_descriptor, :page_token,
                  :bundler, :bundle_descriptor, :metadata, :errors

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
      # @param metadata [Hash] the request header params.
      # @param kwargs [Hash]
      #   Deprecated, if set this will be merged with the metadata field.
      # @param errors [Array<Exception>]
      #   Configures the exceptions to wrap with GaxError.
      def initialize(timeout: 30, retry_options: nil, page_descriptor: nil,
                     page_token: nil, bundler: nil, bundle_descriptor: nil,
                     metadata: {}, kwargs: {}, errors: [])
        @timeout = timeout
        @retry_options = retry_options
        @page_descriptor = page_descriptor
        @page_token = page_token
        @bundler = bundler
        @bundle_descriptor = bundle_descriptor
        @metadata = metadata
        @metadata.merge!(kwargs) if kwargs && metadata
        @errors = errors
      end

      # @return true when it has retry codes.
      def retry_codes?
        @retry_options &&
          @retry_options.retry_codes &&
          @retry_options.retry_codes.any?
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
                                  metadata: @metadata,
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

        metadata = @metadata || {}
        metadata = metadata.dup
        metadata.update(options.metadata) if options.metadata != :OPTION_INHERIT

        CallSettings.new(timeout: timeout,
                         retry_options: retry_options,
                         page_descriptor: @page_descriptor,
                         page_token: page_token,
                         bundler: @bundler,
                         bundle_descriptor: @bundle_descriptor,
                         metadata: metadata,
                         errors: @errors)
      end
    end

    private_constant :CallSettings

    # Encapsulates the overridable settings for a particular API call
    # @!attribute [r] timeout
    #   @return [Numeric, :OPTION_INHERIT]
    # @!attribute [r] retry_options
    #   @return [RetryOptions, :OPTION_INHERIT]
    # @!attribute [r] page_token
    #   @return [Object, :OPTION_INHERIT, :INITIAL_PAGE]
    # @!attribute [r] metadata
    #   @return [Hash, :OPTION_INHERIT]
    # @!attribute [r] kwargs
    #   @return [Hash, :OPTION_INHERIT] deprecated, use metadata instead
    class CallOptions
      attr_reader :timeout, :retry_options, :page_token, :metadata
      alias kwargs metadata

      # @param timeout [Numeric, :OPTION_INHERIT]
      #   The client-side timeout for API calls.
      # @param retry_options [RetryOptions, :OPTION_INHERIT]
      #   The configuration for retrying upon transient error.
      #   If set to nil, this call will not retry.
      # @param page_token [Object, :OPTION_INHERIT]
      #   If set and the call is configured for page streaming, page streaming
      #   is starting with this page_token.
      # @param metadata [Hash, :OPTION_INHERIT] the request header params.
      # @param kwargs [Hash, :OPTION_INHERIT]
      #   Deprecated, if set this will be merged with the metadata field.
      def initialize(timeout: :OPTION_INHERIT,
                     retry_options: :OPTION_INHERIT,
                     page_token: :OPTION_INHERIT,
                     metadata: :OPTION_INHERIT,
                     kwargs: :OPTION_INHERIT)
        @timeout = timeout
        @retry_options = retry_options
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

    # Per-call configurable settings for retrying upon transient failure.
    class RetryOptions < Struct.new(:retry_codes, :backoff_settings)
      # @!attribute retry_codes
      #   @return [Array<Grpc::Code>] a list of exceptions upon which
      #     a retry should be attempted.
      # @!attribute backoff_settings
      #   @return [BackoffSettings] configuring the retry exponential
      #     backoff algorithm.
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

    # Describes the structure of bundled call.
    #
    # request_discriminator_fields may include '.' as a separator, which is
    # used to indicate object traversal.  This allows fields in nested objects
    # to be used to determine what requests to bundle.
    class BundleDescriptor < Struct.new(:bundled_field,
                                        :request_discriminator_fields,
                                        :subresponse_field)
      # @!attribute bundled_field
      #   @return [String] the repeated field in the request message
      #     that will have its elements aggregated by bundling.
      # @!attribute request_discriminator_fields
      #   @return [Array<String>] a list of fields in the target
      #     request message class that are used to determine which
      #     messages should be bundled together.
      # @!attribute subresponse_field
      #   @return [String] an optional field, when present it
      #     indicates the field in the response message that should be
      #     used to demultiplex the response into multiple response
      #     messages.
      def initialize(bundled_field, request_discriminator_fields,
                     subresponse_field: nil)
        super(bundled_field, request_discriminator_fields, subresponse_field)
      end
    end

    # Holds values used to configure bundling.
    #
    # The xxx_threshold attributes are used to configure when the bundled
    # request should be made.
    class BundleOptions < Struct.new(:element_count_threshold,
                                     :element_count_limit,
                                     :request_byte_threshold,
                                     :request_byte_limit,
                                     :delay_threshold_millis)
      # @!attribute element_count_threshold
      #   @return [Numeric] the bundled request will be sent once the
      #     count of outstanding elements in the repeated field
      #     reaches this value.
      # @!attribute element_count_limit
      #   @return [Numeric] represents a hard limit on the number of
      #     elements in the repeated field of the bundle; if adding a
      #     request to a bundle would exceed this value, the bundle is
      #     sent and the new request is added to a fresh bundle. It is
      #     invalid for a single request to exceed this limit.
      # @!attribute request_byte_threshold
      #   @return [Numeric] the bundled request will be sent once the
      #     count of bytes in the request reaches this value. Note
      #     that this value is pessimistically approximated by summing
      #     the bytesizes of the elements in the repeated field, and
      #     therefore may be an under-approximation.
      # @!attribute request_byte_limit
      #   @return [Numeric] represents a hard limit on the size of the
      #     bundled request; if adding a request to a bundle would
      #     exceed this value, the bundle is sent and the new request
      #     is added to a fresh bundle. It is invalid for a single
      #     request to exceed this limit. Note that this value is
      #     pessimistically approximated by summing the bytesizes of
      #     the elements in the repeated field, with a buffer applied
      #     to correspond to the resulting under-approximation.
      # @!attribute delay_threshold_millis
      #   @return [Numeric] the bundled request will be sent this
      #     amount of time after the first element in the bundle was
      #     added to it.
      def initialize(element_count_threshold: 0,
                     element_count_limit: 0,
                     request_byte_threshold: 0,
                     request_byte_limit: 0,
                     delay_threshold_millis: 0)
        super(
          element_count_threshold,
          element_count_limit,
          request_byte_threshold,
          request_byte_limit,
          delay_threshold_millis)
      end
    end

    # Helper for #construct_settings
    #
    # @param bundle_config A Hash specifying a bundle parameters, the value for
    #   'bundling' field in a method config (See ``construct_settings()`` for
    #   information on this config.)
    # @param bundle_descriptor [BundleDescriptor] A BundleDescriptor
    #   object describing the structure of bundling for this
    #   method. If not set, this method will not bundle.
    # @return An Executor that configures bundling, or nil if this
    #   method should not bundle.
    def construct_bundling(bundle_config, bundle_descriptor)
      return unless bundle_config && bundle_descriptor
      options = BundleOptions.new
      bundle_config.each_pair do |key, value|
        options[key.intern] = value
      end
      # Bundling is currently not supported.
      # Executor.new(options)
      nil
    end

    # Helper for #construct_settings
    #
    # @param method_config [Hash] A dictionary representing a single
    #   +methods+ entry of the standard API client config file. (See
    #   #construct_settings for information on this yaml.)
    # @param retry_codes [Hash] A dictionary parsed from the
    #   +retry_codes_def+ entry of the standard API client config
    #   file. (See #construct_settings for information on this yaml.)
    # @param retry_params [Hash] A dictionary parsed from the
    #   +retry_params+ entry of the standard API client config
    #   file. (See #construct_settings for information on this yaml.)
    # @param retry_names [Hash] A dictionary mapping the string names
    #   used in the standard API client config file to API response
    #   status codes.
    # @return [RetryOptions, nil]
    def construct_retry(method_config, retry_codes, retry_params, retry_names)
      return nil unless method_config
      codes = nil
      if retry_codes && method_config.key?('retry_codes_name')
        retry_codes_name = method_config['retry_codes_name']
        codes = retry_codes.fetch(retry_codes_name, []).map do |name|
          retry_names[name]
        end
      end

      backoff_settings = nil
      if retry_params && method_config.key?('retry_params_name')
        params = retry_params[method_config['retry_params_name']]
        backoff_settings = BackoffSettings.new(
          *params.values_at(*BackoffSettings.members.map(&:to_s))
        )
      end

      RetryOptions.new(codes, backoff_settings)
    end

    # Helper for #construct_settings.
    #
    # Takes two retry options, and merges them into a single RetryOption
    # instance.
    #
    # @param retry_options [RetryOptions] The base RetryOptions.
    # @param overrides [RetryOptions] The RetryOptions used for overriding
    #   +retry+. Use the values if it is not nil. If entire
    #   +overrides+ is nli, ignore the base retry and return nil.
    # @return [RetryOptions, nil]
    def merge_retry_options(retry_options, overrides)
      return nil if overrides.nil?

      if overrides.retry_codes.nil? && overrides.backoff_settings.nil?
        return retry_options
      end

      codes = retry_options.retry_codes
      codes = overrides.retry_codes unless overrides.retry_codes.nil?
      backoff_settings = retry_options.backoff_settings
      unless overrides.backoff_settings.nil?
        backoff_settings = overrides.backoff_settings
      end

      RetryOptions.new(codes, backoff_settings)
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
    #             "retry_params_name": "default",
    #             "bundling": {
    #               "element_count_threshold": 40,
    #               "element_count_limit": 200,
    #               "request_byte_threshold": 90000,
    #               "request_byte_limit": 100000,
    #               "delay_threshold_millis": 100
    #             }
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
    # @param retry_names [Hash] A hash mapping the string names
    #   used in the standard API client config file to API response
    #   status codes.
    # @param timeout [Numeric] The timeout parameter for all API calls
    #   in this dictionary.
    # @param bundle_descriptors [Hash{String => BundleDescriptor}]
    #   A dictionary of method names to BundleDescriptor objects for
    #   methods that are bundling-enabled.
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
    def construct_settings(service_name, client_config, config_overrides,
                           retry_names, timeout, bundle_descriptors: {},
                           page_descriptors: {}, metadata: {}, kwargs: {},
                           errors: [])
      defaults = {}

      metadata.merge!(kwargs) if kwargs.is_a?(Hash) && metadata.is_a?(Hash)

      service_config = client_config.fetch('interfaces', {})[service_name]
      return nil unless service_config

      overrides = config_overrides.fetch('interfaces', {})[service_name] || {}

      service_config['methods'].each_pair do |method_name, method_config|
        snake_name = upper_camel_to_lower_underscore(method_name)

        overriding_method =
          overrides.fetch('methods', {}).fetch(method_name, {})

        bundling_config = method_config.fetch('bundling', nil)
        if overriding_method && overriding_method.key?('bundling')
          bundling_config = overriding_method['bundling']
        end
        bundle_descriptor = bundle_descriptors[snake_name]

        defaults[snake_name] = CallSettings.new(
          timeout: calc_method_timeout(
            timeout, method_config, overriding_method
          ),
          retry_options: merge_retry_options(
            construct_retry(method_config,
                            service_config['retry_codes'],
                            service_config['retry_params'],
                            retry_names),
            construct_retry(overriding_method,
                            overrides['retry_codes'],
                            overrides['retry_params'],
                            retry_names)
          ),
          page_descriptor: page_descriptors[snake_name],
          bundler: construct_bundling(bundling_config, bundle_descriptor),
          bundle_descriptor: bundle_descriptor,
          metadata: metadata,
          errors: errors
        )
      end

      defaults
    end

    # @private Determine timeout in seconds for the current method.
    def calc_method_timeout(timeout, method_config, overriding_method)
      timeout_override = method_config['timeout_millis']
      if overriding_method && overriding_method.key?('timeout_millis')
        timeout_override = overriding_method['timeout_millis']
      end
      timeout_override ? timeout_override / 1000 : timeout
    end

    module_function :construct_settings, :construct_bundling,
                    :construct_retry, :upper_camel_to_lower_underscore,
                    :merge_retry_options, :calc_method_timeout
    private_class_method :construct_bundling, :construct_retry,
                         :upper_camel_to_lower_underscore,
                         :merge_retry_options, :calc_method_timeout
  end
end
