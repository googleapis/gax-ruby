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
require "google/gax/api_call"

module Google
  module Gax
    module Grpc
      ##
      # Gax gRPC Stub
      #
      # This class wraps the actual gRPC Stub object and it's RPC methods.
      #
      class Stub
        attr_reader :stub

        ##
        # Creates a Gax gRPC stub object.
        #
        # @param stub_class [Class] gRPC stub class to create a new instance of.
        # @param host [String] The domain name of the API remote host.
        # @param port [Fixnum] The port on which to connect to the remote host.
        # @param credentials [Google::Auth::Credentials, Signet::OAuth2::Client, String, Hash, Proc,
        #   GRPC::Core::Channel, GRPC::Core::ChannelCredentials] Provides the means for authenticating requests made by
        #   the client. This parameter can be many types:
        #
        #   * A `Google::Auth::Credentials` uses a the properties of its represented keyfile for authenticating requests
        #     made by this client.
        #   * A `Signet::OAuth2::Client` object used to apply the OAuth credentials.
        #   * A `GRPC::Core::Channel` will be used to make calls through.
        #   * A `GRPC::Core::ChannelCredentials` for the setting up the RPC client. The channel credentials should
        #     already be composed with a `GRPC::Core::CallCredentials` object.
        #   * A `Proc` will be used as an updater_proc for the Grpc channel. The proc transforms the metadata for
        #     requests, generally, to give OAuth credentials.
        # @param channel_args [Hash] The channel arguments. (This argument is ignored when `credentials` is
        #     provided as a `GRPC::Core::Channel`.)
        # @param interceptors [Array<GRPC::ClientInterceptor>] An array of {GRPC::ClientInterceptor} objects that will
        #   be used for intercepting calls before they are executed Interceptors are an EXPERIMENTAL API.
        #
        def initialize stub_class, host:, port:, credentials:, channel_args: nil, interceptors: nil
          raise ArgumentError, "stub_class is required" if stub_class.nil?
          raise ArgumentError, "host is required" if host.nil?
          raise ArgumentError, "port is required" if port.nil?
          raise ArgumentError, "credentials is required" if credentials.nil?

          address = "#{host}:#{port}"
          channel_args = Hash channel_args
          interceptors = Array interceptors

          @stub = if credentials.is_a? GRPC::Core::Channel
                    stub_class.new address, nil, channel_override: credentials, interceptors: interceptors
                  elsif credentials.is_a? GRPC::Core::ChannelCredentials
                    stub_class.new address, credentials, channel_args: channel_args, interceptors: interceptors
                  else
                    updater_proc = credentials.updater_proc if credentials.respond_to? :updater_proc
                    updater_proc ||= credentials if credentials.is_a? Proc
                    raise ArgumentError, "invalid credentials (#{credentials.class})" if updater_proc.nil?

                    call_creds = GRPC::Core::CallCredentials.new updater_proc
                    chan_creds = GRPC::Core::ChannelCredentials.new.compose call_creds
                    stub_class.new address, chan_creds, channel_args: channel_args, interceptors: interceptors
                  end
        end

        ##
        # Invoke the specified API call.
        #
        # @param method_name [Symbol] The RPC method name.
        # @param request [Object] The request object.
        # @param options [ApiCall::Options, Hash] The options for making the API call. A Hash can be provided to
        #   customize the options object, using keys that match the arguments for {ApiCall::Options.new}. This object
        #   should only be used once.
        # @param format_response [Proc] A Proc object to format the response object. The Proc should accept response as
        #   an argument, and return a formatted response object. Optional.
        #
        #   If `stream_callback` is also provided, the response argument will be an Enumerable of the responses.
        #   Returning a lazy enumerable that adds the desired formatting is recommended.
        # @param operation_callback [Proc] A Proc object to provide a callback of the response and operation objects.
        #   The response will be formatted with `format_response` if that is also provided. Optional.
        # @param stream_callback [Proc] A Proc object to provide a callback for every streamed response received. The
        #   Proc will be called with the response object. Should only be used on Bidi and Server streaming RPC calls.
        #   Optional.
        #
        # @return [Object, Thread] The response object. Or, when `stream_callback` is provided, a thread running the
        #   callback for every streamed response is returned.
        #
        # @example
        #   require "google/showcase/v1alpha3/echo_pb"
        #   require "google/showcase/v1alpha3/echo_services_pb"
        #   require "google/gax"
        #   require "google/gax/grpc"
        #
        #   echo_channel = GRPC::Core::Channel.new(
        #     "localhost:7469", nil, :this_channel_is_insecure
        #   )
        #   echo_stub = Google::Gax::Grpc::Stub.new(
        #     Google::Showcase::V1alpha3::Echo::Stub,
        #     host: "localhost", port: 7469, credentials: echo_channel
        #   )
        #
        #   request = Google::Showcase::V1alpha3::EchoRequest.new
        #   response = echo_stub.call_rpc :echo, request
        #
        # @example Using custom call options:
        #   require "google/showcase/v1alpha3/echo_pb"
        #   require "google/showcase/v1alpha3/echo_services_pb"
        #   require "google/gax"
        #   require "google/gax/grpc"
        #
        #   echo_channel = GRPC::Core::Channel.new(
        #     "localhost:7469", nil, :this_channel_is_insecure
        #   )
        #   echo_stub = Google::Gax::Grpc::Stub.new(
        #     Google::Showcase::V1alpha3::Echo::Stub,
        #     host: "localhost", port: 7469, credentials: echo_channel
        #   )
        #
        #   request = Google::Showcase::V1alpha3::EchoRequest.new
        #   options = Google::Gax::ApiCall::Options.new(
        #     retry_policy = {
        #       retry_codes: [GRPC::Core::StatusCodes::UNAVAILABLE]
        #     }
        #   )
        #   response = echo_stub.call_rpc :echo, request
        #                                 options: options
        #
        # @example Formatting the response in the call:
        #   require "google/showcase/v1alpha3/echo_pb"
        #   require "google/showcase/v1alpha3/echo_services_pb"
        #   require "google/gax"
        #   require "google/gax/grpc"
        #
        #   echo_channel = GRPC::Core::Channel.new(
        #     "localhost:7469", nil, :this_channel_is_insecure
        #   )
        #   echo_stub = Google::Gax::Grpc::Stub.new(
        #     Google::Showcase::V1alpha3::Echo::Stub,
        #     host: "localhost", port: 7469, credentials: echo_channel
        #   )
        #
        #   request = Google::Showcase::V1alpha3::EchoRequest.new
        #   content_upcaser = proc do |response|
        #     format_response = response.dup
        #     format_response.content.upcase!
        #     format_response
        #   end
        #   response = echo_stub.call_rpc :echo, request,
        #                                 format_response: content_upcaser
        #
        def call_rpc method_name, request, options: nil, format_response: nil, operation_callback: nil,
                     stream_callback: nil
          api_call = Google::Gax::ApiCall.new @stub.method method_name
          api_call.call request, options:            options,
                                 format_response:    format_response,
                                 operation_callback: operation_callback,
                                 stream_callback:    stream_callback
        end
      end
    end
  end
end
