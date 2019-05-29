# Copyright 2019, Google Inc.
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

describe 'Google::Gax::CallSettings' do
  describe 'merging metadata' do
    NonPrivateCallSettings = Google::Gax.const_get :CallSettings

    it 'merges nil with :OPTION_INHERIT' do
      call_settings = NonPrivateCallSettings.new metadata: nil
      call_options = Google::Gax::CallOptions.new metadata: :OPTION_INHERIT
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq({})
    end

    it 'merges nil with an empty hash' do
      call_settings = NonPrivateCallSettings.new metadata: nil
      call_options = Google::Gax::CallOptions.new metadata: {}
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq({})
    end

    it 'merges nil hash with a filled hash' do
      call_settings = NonPrivateCallSettings.new metadata: nil
      call_options = Google::Gax::CallOptions.new metadata: { foo: :baz }
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq(foo: :baz)
    end

    it 'merges an empty hash with :OPTION_INHERIT' do
      call_settings = NonPrivateCallSettings.new metadata: {}
      call_options = Google::Gax::CallOptions.new metadata: :OPTION_INHERIT
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq({})
    end

    it 'merges an empty hash with an empty hash' do
      call_settings = NonPrivateCallSettings.new metadata: {}
      call_options = Google::Gax::CallOptions.new metadata: {}
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq({})
    end

    it 'merges an empty hash with a filled hash' do
      call_settings = NonPrivateCallSettings.new metadata: {}
      call_options = Google::Gax::CallOptions.new metadata: { foo: :baz }
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq(foo: :baz)
    end

    it 'merges a filled hash with :OPTION_INHERIT' do
      call_settings = NonPrivateCallSettings.new metadata: { foo: :bar }
      call_options = Google::Gax::CallOptions.new metadata: :OPTION_INHERIT
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq(foo: :bar)
    end

    it 'merges a filled hash with an empty hash' do
      call_settings = NonPrivateCallSettings.new metadata: { foo: :bar }
      call_options = Google::Gax::CallOptions.new metadata: {}
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq(foo: :bar)
    end

    it 'merges a filled hash with a filled hash' do
      call_settings = NonPrivateCallSettings.new metadata: { foo: :bar }
      call_options = Google::Gax::CallOptions.new metadata: { foo: :baz }
      new_settings = call_settings.merge call_options
      expect(new_settings.metadata).to eq(foo: :baz)
    end
  end
end
