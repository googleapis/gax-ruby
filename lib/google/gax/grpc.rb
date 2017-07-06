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

require 'grpc'
require 'googleauth'

module Google
  module Gax
    # Grpc adapts the gRPC surface
    module Grpc
      STATUS_CODE_NAMES = Hash[
        GRPC::Core::StatusCodes.constants.map do |sym|
          [sym.to_s, GRPC::Core::StatusCodes.const_get(sym)]
        end
      ].freeze

      API_ERRORS = [GRPC::BadStatus, GRPC::Cancelled].freeze

      # rubocop:disable Metrics/ParameterLists

      # Creates a gRPC client stub. The following precedence will be taken if
      # multiple of channel, chan_creds, and updater_proc are given:
      # channel > chan_creds > updater_proc.
      #
      # @param service_path [String] The domain name of the API remote host.
      #
      # @param port [Fixnum] The port on which to connect to the remote host.
      #
      # @param channel [Object]
      #   A Channel object through which to make calls. If nil, a secure
      #   channel is constructed.
      #
      # @param chan_creds [Grpc::Core::ChannelCredentials]
      #   A ChannelCredentials object for use with an SSL-enabled Channel.
      #   If nil, credentials are pulled from a default location.
      #
      # @param updater_proc [Proc]
      #   A function that transforms the metadata for requests, e.g., to give
      #   OAuth credentials.
      #
      # @param scopes [Array<String>]
      #   The OAuth scopes for this service. This parameter is ignored if
      #   a custom metadata_transformer is supplied.
      #
      # @yield [address, creds]
      #   the generated gRPC method to create a stub.
      #
      # @return A gRPC client stub.
      def create_stub(service_path,
                      port,
                      channel: nil,
                      chan_creds: nil,
                      updater_proc: nil,
                      scopes: nil)
        address = "#{service_path}:#{port}"
        if channel
          yield(address, nil, channel_override: channel)
        elsif chan_creds
          yield(address, chan_creds)
        else
          if updater_proc.nil?
            auth_creds = Google::Auth.get_application_default(scopes)
            updater_proc = auth_creds.updater_proc
          end
          call_creds = GRPC::Core::CallCredentials.new(updater_proc)
          chan_creds = GRPC::Core::ChannelCredentials.new.compose(call_creds)
          yield(address, chan_creds)
        end
      end

      module_function :create_stub
    end
  end
end
