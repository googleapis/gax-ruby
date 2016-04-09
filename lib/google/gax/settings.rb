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
    # Helper for #construct_settings
    #
    # @param method_config A dictionary representing a single
    #   ``methods`` entry of the standard API client config file. (See
    #   #construct_settings for information on this yaml.)
    # @param [BundleOptions, :OPTION_INHERIT, nil] method_retry_override
    #   If set to :OPTION_INHERIT, the retry settings are derived from
    #   method config. Otherwise, this parameter overrides
    #   +method_config+.

    # @param [BundleDescriptor] bundle_descriptor A BundleDescriptor
    #   object describing the structure of bundling for this
    #   method. If not set, this method will not bundle.
    # @return An Executor that configures bundling, or nil if this
    #   method should not bundle.
    def _construct_bundling(method_config, method_bundling_override,
                            bundle_descriptor)
      if method_config.key?('bundling') && bundle_descriptor
        if method_bundling_override == :OPTION_INHERIT
          options = BundleOptions.new
          method_config['bundling'].each_pair do |key, value|
            options[key.intern] = value
          end
          # TODO: comment-out when bundling is supported.
          # Executor.new(options)
        elsif method_bundling_override
          # Executor.new(method_bundling_override)
        end
      end
    end

    # Helper for #construct_settings
    #
    # @param [Hash] method_config A dictionary representing a single
    #   +methods+ entry of the standard API client config file. (See
    #   #construct_settings for information on this yaml.)
    # @param [RetryOptions, :OPTION_INHERIT, nil] method_retry_override
    #   If set to :OPTION_INHERIT, the retry settings are derived from
    #     method config. Otherwise, this parameter overrides
    #     +method_config+.
    # @param [Hash] retry_codes_def A dictionary parsed from the
    #   +retry_codes_def+ entry of the standard API client config
    #   file. (See #construct_settings for information on this yaml.)
    # @param [Hash] retry_params A dictionary parsed from the
    #   +retry_params+ entry of the standard API client config
    #   file. (See #construct_settings for information on this yaml.)
    # @param [Hash] retry_names A dictionary mapping the string names
    #   used in the standard API client config file to API response
    #   status codes.
    # @return [RetryOptions, nil]
    def _construct_retry(method_config, method_retry_override, retry_codes,
                         retry_params, retry_names)
      unless method_retry_override == :OPTION_INHERIT
        return method_retry_override
      end

      retry_codes ||= {}
      retry_codes_name = method_config['retry_codes_name']
      codes = retry_codes.fetch(retry_codes_name, []).map do |name|
        retry_names[name]
      end

      if retry_params && method_config.key?('retry_params_name')
        params = retry_params[method_config['retry_params_name']]
        backoff_settings = BackoffSettings.new(
          *params.values_at(*BackoffSettings.members.map(&:to_s)))
      end

      RetryOptions.new(retry_codes: codes, backoff_settings: backoff_settings)
    end

    def _upper_camel_to_lower_underscore(string)
      string.scan(/[[:upper:]][^[:upper:]]*/).map(&:downcase).join('_')
    end

    # rubocop:disable Metrics/ParameterLists

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
    # @param [String] service_name The fully-qualified name of this
    #   service, used as a key into the client config file (in the
    #   example above, this value should be
    #   'google.fake.v1.ServiceName').
    # @param [Hash] client_config A dictionary parsed from the
    #     standard API client config file.
    # @param [Hash] bundling_override A dictionary of method names to
    #   BundleOptions override those specified in +client_config+.
    # @param [Hash] retry_override A dictionary of method names to
    #   RetryOptions that override those specified in +client_config+.
    # @param [Hash] retry_names A dictionary mapping the strings
    #   referring to response status codes to the Python objects
    #   representing those codes.
    # @param [Numeric] timeout The timeout parameter for all API calls
    #   in this dictionary.
    # @param [Hash{String => BundleDescriptor}] bundle_descriptors
    #   A dictionary of method names to BundleDescriptor objects for
    #   methods that are bundling-enabled.
    # @param [Hash{String => PageDescriptor}] page_descriptors A
    #   dictionary of method names to PageDescriptor objects for
    #   methods that are page streaming-enabled.
    # @return [CallSettings, nil] A CallSettings, or nil if the
    #   service is not found in the config.
    def construct_settings(
        service_name, client_config, bundling_override, retry_override,
        retry_names, timeout, bundle_descriptors: {}, page_descriptors: {})
      defaults = {}

      service_config = client_config.fetch('interfaces', {})[service_name]
      return nil unless service_config

      service_config['methods'].each_pair do |method_name, method_config|
        snake_name = _upper_camel_to_lower_underscore(method_name)

        bundle_descriptor = bundle_descriptors[snake_name]

        defaults[snake_name] = CallSettings.new(
          timeout: timeout,
          retry_options: _construct_retry(
            method_config,
            retry_override.fetch(snake_name, :OPTION_INHERIT),
            service_config['retry_codes'],
            service_config['retry_params'],
            retry_names),
          page_descriptor: page_descriptors[snake_name],
          bundler: _construct_bundling(
            method_config,
            bundling_override.fetch(snake_name, :OPTION_INHERIT),
            bundle_descriptor),
          bundle_descriptor: bundle_descriptor)
      end

      defaults
    end

    module_function :construct_settings, :_construct_bundling,
                    :_construct_retry, :_upper_camel_to_lower_underscore
    private_class_method :_construct_bundling, :_construct_retry,
                         :_upper_camel_to_lower_underscore
  end
end
