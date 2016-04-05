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

require 'google/gax/settings'
require 'google/gax'

SERVICE_NAME = 'test.interface.v1.api'.freeze

A_CONFIG = {
  'interfaces' => {
    SERVICE_NAME => {
      'retry_codes' => {
        'foo_retry' => %w(code_a code_b),
        'bar_retry' => %w(code_c)
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
        'PageStreamingMethod' => {
          'retry_codes_name' => 'bar_retry',
          'retry_params_name' => 'default'
        }
      }
    }
  }
}.freeze

PAGE_DESCRIPTORS = {
  'page_streaming_method' => Google::Gax::PageDescriptor.new(
    'page_token', 'next_page_token', 'page_streams')
}.freeze

BUNDLE_DESCRIPTORS = {
  'bundling_method' => Google::Gax::BundleDescriptor.new('bundled_field', [])
}.freeze

RETRY_DICT = {
  'code_a' => Exception,
  'code_b' => Exception,
  'code_c' => Exception
}.freeze

describe Google::Gax do
  it 'creates settings' do
    defaults = Google::Gax.construct_settings(
      SERVICE_NAME, A_CONFIG, {}, {}, RETRY_DICT, 30,
      bundle_descriptors: BUNDLE_DESCRIPTORS,
      page_descriptors: PAGE_DESCRIPTORS)
    settings = defaults['bundling_method']
    expect(settings.timeout).to be(30)
    # TODO: uncomment this when bundling is added.
    # expect(settings.bundler).to be_a(Google::Gax::Executor)
    expect(settings.bundle_descriptor).to be_a(Google::Gax::BundleDescriptor)
    expect(settings.page_descriptor).to be_nil
    expect(settings.retry_options).to be_a(Google::Gax::RetryOptions)

    settings = defaults['page_streaming_method']
    expect(settings.timeout).to be(30)
    expect(settings.bundler).to be_nil
    expect(settings.bundle_descriptor).to be_nil
    expect(settings.page_descriptor).to be_a(Google::Gax::PageDescriptor)
    expect(settings.retry_options).to be_a(Google::Gax::RetryOptions)
  end

  it 'overrides settings' do
    bundling_override = { 'bundling_method' => nil }
    retry_override = { 'page_streaming_method' => nil }
    defaults = Google::Gax.construct_settings(
      SERVICE_NAME, A_CONFIG, bundling_override, retry_override,
      RETRY_DICT, 30,
      bundle_descriptors: BUNDLE_DESCRIPTORS,
      page_descriptors: PAGE_DESCRIPTORS)

    settings = defaults['bundling_method']
    expect(settings.timeout).to be(30)
    expect(settings.bundler).to be_nil
    expect(settings.page_descriptor).to be_nil

    settings = defaults['page_streaming_method']
    expect(settings.timeout).to be(30)
    expect(settings.page_descriptor).to be_a(Google::Gax::PageDescriptor)
    expect(settings.retry_options).to be_nil
  end
end
