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

require 'grpc'
require 'grpc/google_rpc_status_utils'
require 'googleauth'
require 'google/gax/errors'
require 'google/protobuf/well_known_types'
# Required in order to deserialize common error detail proto types
require 'google/rpc/error_details_pb'

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

      def deserialize_error_status_details(error)
        return unless error.is_a? GRPC::BadStatus
        # If error status is malformed, swallow the gRPC error that gets raised.
        begin
          details =
            GRPC::GoogleRpcStatusUtils.extract_google_rpc_status(
              error.to_status
            ).details
        rescue
          return 'Could not parse error details due to a malformed server '\
                 'response trailer.'
        end
        return if details.nil?
        details =
          GRPC::GoogleRpcStatusUtils.extract_google_rpc_status(
            error.to_status
          ).details
        details.map do |any|
          # deserialize the proto wrapped by the Any in the error details
          begin
            type = Google::Protobuf::DescriptorPool.generated_pool.lookup(
              any.type_name
            )
            any.unpack(type.msgclass)
          rescue
            any
          end
        end
      end

      # rubocop:disable Metrics/ParameterLists

      # Creates a gRPC client stub.
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
      # @param interceptors [Array<GRPC::ClientInterceptor>] An array of
      #     GRPC::ClientInterceptor objects that will be used for
      #     intercepting calls before they are executed
      #     Interceptors are an EXPERIMENTAL API.
      #
      # @raise [ArgumentError] if a combination channel, chan_creds, and
      #    updater_proc are passed.
      #
      # @yield [address, creds, channel_override, interceptors]
      #   the generated gRPC method to create a stub.
      #
      # @return A gRPC client stub.
      def create_stub(service_path,
                      port,
                      channel: nil,
                      chan_creds: nil,
                      updater_proc: nil,
                      scopes: nil,
                      interceptors: [])
        verify_params(channel, chan_creds, updater_proc)
        address = "#{service_path}:#{port}"
        default_channel_args = { 'grpc.service_config_disable_resolution' => 1 }
        if channel
          yield(address, nil, channel_override: channel,
                              interceptors: interceptors)
        elsif chan_creds
          yield(address, chan_creds, interceptors: interceptors,
                                     channel_args: default_channel_args)
        else
          if updater_proc.nil?
            auth_creds = Google::Auth.get_application_default(scopes)
            updater_proc = auth_creds.updater_proc
          end
          call_creds = GRPC::Core::CallCredentials.new(updater_proc)
          chan_creds = GRPC::Core::ChannelCredentials.new.compose(call_creds)
          yield(address, chan_creds, interceptors: interceptors,
                                     channel_args: default_channel_args)
        end
      end

      module_function :create_stub, :deserialize_error_status_details

      def self.verify_params(channel, chan_creds, updater_proc)
        if (channel && chan_creds) ||
           (channel && updater_proc) ||
           (chan_creds && updater_proc)
          raise ArgumentError.new('Only one of channel, chan_creds, and ' \
              'updater_proc should be passed into ' \
              'Google::Gax::Grpc#create_stub.')
        end
      end

      # Capitalize all modules except the message class, which is already
      # correctly cased
      def self.class_case(modules)
        message = modules.pop
        modules = modules.map(&:capitalize)
        modules << message
      end

      private_class_method :verify_params, :class_case
    end
  end
end
