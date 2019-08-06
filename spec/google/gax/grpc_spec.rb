# Copyright 2017, Google LLC
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

require 'google/gax/grpc'

describe Google::Gax::Grpc do
  describe '#create_stub' do
    it 'yields constructed channel credentials' do
      mock = instance_double(GRPC::Core::ChannelCredentials)
      composed_mock = instance_double(GRPC::Core::ChannelCredentials)
      default_creds = instance_double(Google::Auth::ServiceAccountCredentials)
      channel_args = { 'grpc.service_config_disable_resolution' => 1 }
      updater_proc = proc {}

      allow(Google::Auth)
        .to receive(:get_application_default).and_return(default_creds)
      allow(default_creds).to receive(:updater_proc).and_return(updater_proc)
      allow(mock).to receive(:compose).and_return(composed_mock)
      allow(GRPC::Core::ChannelCredentials).to receive(:new).and_return(mock)

      expect do |blk|
        Google::Gax::Grpc.create_stub('service', 'port', &blk)
      end.to yield_with_args(
        'service:port', composed_mock,
        interceptors: [], channel_args: channel_args
      )
    end

    it 'yields given channel' do
      mock = instance_double(GRPC::Core::Channel)
      interceptors = instance_double(Array)
      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', channel: mock, interceptors: interceptors, &blk
        )
      end.to yield_with_args(
        'service:port', nil, channel_override: mock, interceptors: interceptors
      )
    end

    it 'yields given channel and interceptors' do
      mock = instance_double(GRPC::Core::Channel)
      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', channel: mock, &blk
        )
      end.to yield_with_args(
        'service:port', nil, channel_override: mock, interceptors: []
      )
    end

    it 'yields given interceptors' do
      interceptors = instance_double(Array)
      channel = instance_double(GRPC::Core::Channel)
      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', channel: channel, interceptors: interceptors, &blk
        )
      end.to yield_with_args(
        'service:port', anything, channel_override: channel,
                                  interceptors: interceptors
      )
    end

    it 'yields given channel credentials' do
      channel_args = { 'grpc.service_config_disable_resolution' => 1 }
      mock = instance_double(GRPC::Core::ChannelCredentials)
      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', chan_creds: mock, &blk
        )
      end.to yield_with_args(
        'service:port', mock, interceptors: [], channel_args: channel_args
      )
    end

    it 'yields given channel credentials and interceptors' do
      mock = instance_double(GRPC::Core::ChannelCredentials)
      interceptors = instance_double(Array)
      channel_args = { 'grpc.service_config_disable_resolution' => 1 }
      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', chan_creds: mock, interceptors: interceptors, &blk
        )
      end.to yield_with_args(
        'service:port', mock,
        interceptors: interceptors, channel_args: channel_args
      )
    end

    it 'yields channel credentials composed of the given updater_proc' do
      chan_creds = instance_double(GRPC::Core::ChannelCredentials)
      composed_chan_creds = instance_double(GRPC::Core::ChannelCredentials)
      call_creds = instance_double(GRPC::Core::CallCredentials)
      updater_proc = proc {}
      channel_args = { 'grpc.service_config_disable_resolution' => 1 }

      allow(GRPC::Core::CallCredentials)
        .to receive(:new).with(updater_proc).and_return(call_creds)
      allow(GRPC::Core::ChannelCredentials)
        .to receive(:new).and_return(chan_creds)
      allow(chan_creds)
        .to receive(:compose).with(call_creds).and_return(composed_chan_creds)
      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', updater_proc: updater_proc, &blk
        )
      end.to yield_with_args(
        'service:port', composed_chan_creds,
        interceptors: [], channel_args: channel_args
      )
    end

    it 'raise an argument error if multiple creds are passed in' do
      channel = instance_double(GRPC::Core::Channel)
      chan_creds = instance_double(GRPC::Core::ChannelCredentials)
      updater_proc = instance_double(Proc)

      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', channel: channel, chan_creds: chan_creds, &blk
        )
      end.to raise_error(ArgumentError)

      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', channel: channel,
                             updater_proc: updater_proc, &blk
        )
      end.to raise_error(ArgumentError)

      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', chan_creds: chan_creds,
                             updater_proc: updater_proc, &blk
        )
      end.to raise_error(ArgumentError)

      expect do |blk|
        Google::Gax::Grpc.create_stub(
          'service', 'port', channel: channel, chan_creds: chan_creds,
                             updater_proc: updater_proc, &blk
        )
      end.to raise_error(ArgumentError)
    end
  end

  describe '#deserialize_error_status_details' do
    it 'deserializes a known error type' do
      expected_error = Google::Rpc::DebugInfo.new(detail: 'shoes are untied')

      any = Google::Protobuf::Any.new
      any.pack(expected_error)
      status = Google::Rpc::Status.new(details: [any])
      encoded = Google::Rpc::Status.encode(status)
      metadata = {
        'grpc-status-details-bin' => encoded
      }
      error = GRPC::BadStatus.new(1, '', metadata)

      expect(Google::Gax::Grpc.deserialize_error_status_details(error))
        .to eq [expected_error]
    end

    it 'does not deserialize an unknown error type' do
      expected_error = Random.new.bytes(8)

      any = Google::Protobuf::Any.new(
        type_url: 'unknown-type', value: expected_error
      )
      status = Google::Rpc::Status.new(details: [any])
      encoded = Google::Rpc::Status.encode(status)
      metadata = {
        'grpc-status-details-bin' => encoded
      }
      error = GRPC::BadStatus.new(1, '', metadata)

      expect(Google::Gax::Grpc.deserialize_error_status_details(error))
        .to eq [any]
    end
  end
end
