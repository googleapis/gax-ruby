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
        'SomeHTTPSPageStreamingMethod' => {
          'retry_codes_name' => 'bar_retry',
          'retry_params_name' => 'default'
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

describe Google::Gax do
  it 'creates settings' do
    defaults = Google::Gax.construct_settings(
      SERVICE_NAME, A_CONFIG, {}, 30,
      page_descriptors: PAGE_DESCRIPTORS,
      metadata: { 'key' => 'value' },
      errors: [StandardError]
    )
    settings = defaults['some_https_page_streaming_method']
    expect(settings.timeout).to be(30)
    expect(settings.page_descriptor).to be_a(Google::Gax::PageDescriptor)
    expect(settings.metadata).to match('key' => 'value')
    expect(settings.errors).to match_array([StandardError])
  end

  it 'overrides settings' do
    overrides = {
      'interfaces' => {
        SERVICE_NAME => {
          'methods' => {
            'SomeHTTPSPageStreamingMethod' => nil
          }
        }
      }
    }
    defaults = Google::Gax.construct_settings(
      SERVICE_NAME, A_CONFIG, overrides, 30,
      page_descriptors: PAGE_DESCRIPTORS
    )

    settings = defaults['some_https_page_streaming_method']
    expect(settings.timeout).to be(30)
    expect(settings.page_descriptor).to be_a(Google::Gax::PageDescriptor)
  end
end
