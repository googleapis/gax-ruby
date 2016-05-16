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
    # @param bundle_descriptor [BundleDescriptor] A BundleDescriptor
    #   object describing the structure of bundling for this
    #   method. If not set, this method will not bundle.
    # @return An Executor that configures bundling, or nil if this
    #   method should not bundle.
    def construct_bundling(method_config, bundle_descriptor)
      if method_config && method_config.key?('bundling') && bundle_descriptor
        options = BundleOptions.new
        method_config['bundling'].each_pair do |key, value|
          options[key.intern] = value
        end
        # TODO: comment-out when bundling is supported.
        # Executor.new(options)
        nil
      end
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
      retry_codes ||= {}
      retry_codes_name = method_config['retry_codes_name']
      codes = retry_codes.fetch(retry_codes_name, []).map do |name|
        retry_names[name]
      end

      if retry_params && method_config.key?('retry_params_name')
        params = retry_params[method_config['retry_params_name']]
        backoff_settings = BackoffSettings.new(
          *params.values_at(*BackoffSettings.members.map(&:to_s))
        )
      end

      RetryOptions.new(codes, backoff_settings)
    end

    def upper_camel_to_lower_underscore(string)
      string.scan(/[[:upper:]][^[:upper:]]*/).map(&:downcase).join('_')
    end

    # Update config_base specifying retry params with overrides.
    #
    # @param config_base [Hash] A hash of retry params.
    # @overrides [Hash] A hash to update config_base.
    def override_retry(config_base, overrides)
      overrides.each_pair do |name, params|
        if config_base.key?(name)
          config_base[name].update(params)
        else
          config_base[name] = params
        end
      end
    end

    # Update config_base specifying method condigs with overrides.
    #
    # @param config_base [Hash] A hash of method config.
    # @param overrides [Hash] A hash to update config_base.
    def override_methods(config_base, overrides)
      overrides.each_pair do |name, params|
        if params
          params.each_pair do |key, param|
            next unless config_base[name].key?(key)
            if key == 'bundling' && param
              config_base[name][key].update(param)
            else
              config_base[name][key] = param || {}
            end
          end
        else
          config_base[name] = nil
        end
      end
    end

    # Merge overriding configs into config_base and return the new config.
    #
    # If overrides is empty, it returns the same config_base. Otherwise,
    # it creates a copy of config_base and some parts are updated by overrides.
    #
    # @param config_base [Hash] A hash for base config.
    # @param overrides [Hash] A hash in the same structure of config_base.
    # @return [Hash]
    def override_config(config_base, overrides)
      return config_base unless overrides
      # Using Marshal to deep-copy the config_base.
      new_config = Marshal.load(Marshal.dump(config_base))
      if overrides.key?('retry_codes')
        new_config['retry_codes'].update(overrides['retry_codes'])
      end
      if overrides.key?('retry_params')
        override_retry(new_config['retry_params'], overrides['retry_params'])
      end
      if overrides.key?('methods')
        override_methods(new_config['methods'], overrides['methods'])
      end
      new_config
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
    # @param service_name [String] The fully-qualified name of this
    #   service, used as a key into the client config file (in the
    #   example above, this value should be
    #   'google.fake.v1.ServiceName').
    # @param client_config [Hash] A hash parsed from the standard
    #   API client config file.
    # @param config_overrides [Hash] A hash in the same structure of
    #   client_config to override the settings.
    # @param retry_names [Hash] A dictionary mapping the strings
    #   referring to response status codes to the Python objects
    #   representing those codes.
    # @param timeout [Numeric] The timeout parameter for all API calls
    #   in this dictionary.
    # @param bundle_descriptors [Hash{String => BundleDescriptor}]
    #   A dictionary of method names to BundleDescriptor objects for
    #   methods that are bundling-enabled.
    # @param page_descriptors [Hash{String => PageDescriptor}] A
    #   dictionary of method names to PageDescriptor objects for
    #   methods that are page streaming-enabled.
    # @return [CallSettings, nil] A CallSettings, or nil if the
    #   service is not found in the config.
    def construct_settings(service_name, client_config, config_overrides,
                           retry_names, timeout, bundle_descriptors: {},
                           page_descriptors: {})
      defaults = {}

      service_config = client_config.fetch('interfaces', {})[service_name]
      return nil unless service_config

      overrides = config_overrides.fetch('interfaces', {})[service_name]
      service_config = override_config(service_config, overrides)

      service_config['methods'].each_pair do |method_name, method_config|
        snake_name = upper_camel_to_lower_underscore(method_name)

        bundle_descriptor = bundle_descriptors[snake_name]

        defaults[snake_name] = CallSettings.new(
          timeout: timeout,
          retry_options: construct_retry(method_config,
                                         service_config['retry_codes'],
                                         service_config['retry_params'],
                                         retry_names),
          page_descriptor: page_descriptors[snake_name],
          bundler: construct_bundling(method_config,
                                      bundle_descriptor),
          bundle_descriptor: bundle_descriptor
        )
      end

      defaults
    end

    module_function :construct_settings, :construct_bundling,
                    :construct_retry, :upper_camel_to_lower_underscore,
                    :override_retry, :override_methods, :override_config
    private_class_method :construct_bundling, :construct_retry,
                         :upper_camel_to_lower_underscore,
                         :override_retry, :override_methods, :override_config
  end
end
