# Copyright 2019, Google LLC
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

require "grpc"
require "googleauth"

module Google
  module Gax
    module Grpc
      ##
      # Stub
      # TODO: Add documentation
      module Stub
        ##
        # Creates a gRPC stub object.
        #
        # @param stub_class [Class] gRPC stub class to create a new instance of.
        # @param host [String] The domain name of the API remote host.
        # @param port [Fixnum] The port on which to connect to the remote host.
        # @param credentials [Google::Auth::Credentials, String, Hash, GRPC::Core::Channel,
        #   GRPC::Core::ChannelCredentials, Proc] Provides the means for authenticating requests made by the client.
        #   This parameter can be many types:
        #
        #   * A `Google::Auth::Credentials` uses a the properties of its represented keyfile for authenticating requests
        #     made by this client.
        #   * A `GRPC::Core::Channel` will be used to make calls through.
        #   * A `GRPC::Core::ChannelCredentials` for the setting up the RPC client. The channel credentials should
        #     already be composed with a `GRPC::Core::CallCredentials` object.
        #   * A `Proc` will be used as an updater_proc for the Grpc channel. The proc transforms the metadata for
        #     requests, generally, to give OAuth credentials.
        # @param interceptors [Array<GRPC::ClientInterceptor>] An array of {GRPC::ClientInterceptor} objects that will
        #   be used for intercepting calls before they are executed Interceptors are an EXPERIMENTAL API.
        #
        # @return The gRPC stub object.
        #
        def self.new stub_class, host:, port:, credentials:, interceptors: []
          raise ArgumentError, "stub_class is required" if stub_class.nil?
          raise ArgumentError, "host is required" if host.nil?
          raise ArgumentError, "port is required" if port.nil?
          raise ArgumentError, "credentials is required" if credentials.nil?

          address = "#{host}:#{port}"

          if credentials.is_a? GRPC::Core::Channel
            return stub_class.new address, nil, channel_override: credentials, interceptors: interceptors
          elsif credentials.is_a? GRPC::Core::ChannelCredentials
            return stub_class.new address, credentials, interceptors: interceptors
          end

          updater_proc = case credentials
                         when Google::Auth::Credentials
                           credentials.updater_proc
                         when Proc
                           credentials
                         else
                           raise ArgumentError, "invalid credentials (#{credentials.class})"
                         end

          call_creds = GRPC::Core::CallCredentials.new updater_proc
          chan_creds = GRPC::Core::ChannelCredentials.new.compose call_creds
          stub_class.new address, chan_creds, interceptors: interceptors
        end
      end
    end
  end
end
