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

require 'google/gax/settings'
require 'google/gax'

SERVICE_NAME = 'test.interface.v1.api'.freeze

A_CONFIG = {
  'interfaces' => {
    SERVICE_NAME => {
      'retry_codes' => {
        'foo_retry' => %w[code_a code_b],
        'bar_retry' => %w[code_c]
      },
      'retry_params' => {
        'default' => {
          'initial_retry_delay_millis' => 100,
          'retry_delay_multiplier' => 1.2,
          'max_retry_delay_millis' => 1000,
          'initial_rpc_timeout_millis' => 300,
          'rpc_timeout_multiplier' => 1.3,
          'max_rpc_timeout_millis' => 3000,
          'total_timeout_millis' => 30_000
        }
      },
      'methods' => {
        # Note that GAX should normalize this to snake case
        'BundlingMethod' => {
          'retry_codes_name' => 'foo_retry',
          'retry_params_name' => 'default',
          'bundling' => {
            'element_count_threshold' => 6,
            'element_count_limit' => 10
          }
        },
        'SomeHTTPSPageStreamingMethod' => {
          'retry_codes_name' => 'bar_retry',
          'retry_params_name' => 'default'
        },
        'TimeoutMethod' => {
          'timeout_millis' => 10_000
        }
      }
    }
  }
}.freeze

PAGE_DESCRIPTORS = {
  'some_https_page_streaming_method' => Google::Gax::PageDescriptor.new(
    'page_token', 'next_page_token', 'page_streams'
  )
}.freeze

BUNDLE_DESCRIPTORS = {
  'bundling_method' => Google::Gax::BundleDescriptor.new('bundled_field', [])
}.freeze

RETRY_DICT = {
  'code_a' => 1,
  'code_b' => 2,
  'code_c' => 3
}.freeze

describe Google::Gax do
  it 'creates settings' do
    defaults = Google::Gax.construct_settings(
      SERVICE_NAME, A_CONFIG, {}, RETRY_DICT, 30,
      bundle_descriptors: BUNDLE_DESCRIPTORS,
      page_descriptors: PAGE_DESCRIPTORS,
      metadata: { 'key' => 'value' },
      errors: [StandardError]
    )
    settings = defaults['bundling_method']
    expect(settings.timeout).to be(30)
    expect(settings.bundler).to be_nil
    expect(settings.bundle_descriptor).to be_a(Google::Gax::BundleDescriptor)
    expect(settings.page_descriptor).to be_nil
    expect(settings.retry_options).to be_a(Google::Gax::RetryOptions)
    expect(settings.retry_options.retry_codes).to be_a(Array)
    expect(settings.retry_options.backoff_settings).to be_a(
      Google::Gax::BackoffSettings
    )
    expect(settings.metadata).to match('key' => 'value')
    expect(settings.errors).to match_array([StandardError])

    settings = defaults['some_https_page_streaming_method']
    expect(settings.timeout).to be(30)
    expect(settings.bundler).to be_nil
    expect(settings.bundle_descriptor).to be_nil
    expect(settings.page_descriptor).to be_a(Google::Gax::PageDescriptor)
    expect(settings.retry_options).to be_a(Google::Gax::RetryOptions)
    expect(settings.retry_options.retry_codes).to be_a(Array)
    expect(settings.retry_options.backoff_settings).to be_a(
      Google::Gax::BackoffSettings
    )
    expect(settings.metadata).to match('key' => 'value')
    expect(settings.errors).to match_array([StandardError])

    settings = defaults['timeout_method']
    expect(settings.timeout).to be(10)
  end

  it 'overrides settings' do
    overrides = {
      'interfaces' => {
        SERVICE_NAME => {
          'methods' => {
            'SomeHTTPSPageStreamingMethod' => nil,
            'BundlingMethod' => {
              'bundling' => nil
            },
            'TimeoutMethod' => {
              'timeout_millis' => nil
            }
          }
        }
      }
    }
    defaults = Google::Gax.construct_settings(
      SERVICE_NAME, A_CONFIG, overrides, RETRY_DICT, 30,
      bundle_descriptors: BUNDLE_DESCRIPTORS,
      page_descriptors: PAGE_DESCRIPTORS
    )

    settings = defaults['bundling_method']
    expect(settings.timeout).to be(30)
    expect(settings.bundler).to be_nil
    expect(settings.page_descriptor).to be_nil

    settings = defaults['some_https_page_streaming_method']
    expect(settings.timeout).to be(30)
    expect(settings.page_descriptor).to be_a(Google::Gax::PageDescriptor)
    expect(settings.retry_options).to be_nil

    settings = defaults['timeout_method']
    expect(settings.timeout).to be(30)
  end

  it 'overrides settings more precisely' do
    override = {
      'interfaces' => {
        SERVICE_NAME => {
          'retry_codes' => {
            'bar_retry' => [],
            'baz_retry' => ['code_a']
          },
          'retry_params' => {
            'default' => {
              'initial_retry_delay_millis' => 1000,
              'retry_delay_multiplier' => 1.2,
              'max_retry_delay_millis' => 10_000,
              'initial_rpc_timeout_millis' => 3000,
              'rpc_timeout_multiplier' => 1.3,
              'max_rpc_timeout_millis' => 30_000,
              'total_timeout_millis' => 300_000
            }
          },
          'methods' => {
            'BundlingMethod' => {
              'retry_params_name' => 'default',
              'retry_codes_name' => 'baz_retry'
            },
            'TimeoutMethod' => {
              'timeout_millis' => 20_000
            }
          }
        }
      }
    }
    defaults = Google::Gax.construct_settings(
      SERVICE_NAME, A_CONFIG, override, RETRY_DICT, 30,
      bundle_descriptors: BUNDLE_DESCRIPTORS,
      page_descriptors: PAGE_DESCRIPTORS
    )

    settings = defaults['bundling_method']
    backoff = settings.retry_options.backoff_settings
    expect(backoff.initial_retry_delay_millis).to be(1000)
    expect(settings.retry_options.retry_codes).to match_array(
      [RETRY_DICT['code_a']]
    )
    expect(settings.bundler).to be_nil
    expect(settings.bundle_descriptor).to be_a(Google::Gax::BundleDescriptor)

    # some_https_page_streaming_method is unaffected because it's not specified
    # in overrides. 'bar_retry' or 'default' definitions in overrides should
    # not affect the methods which are not in the overrides.
    settings = defaults['some_https_page_streaming_method']
    backoff = settings.retry_options.backoff_settings
    expect(backoff.initial_retry_delay_millis).to be(100)
    expect(backoff.retry_delay_multiplier).to be(1.2)
    expect(backoff.max_retry_delay_millis).to be(1000)
    expect(settings.retry_options.retry_codes).to match_array(
      [RETRY_DICT['code_c']]
    )

    settings = defaults['timeout_method']
    expect(settings.timeout).to be(20)
  end
end
