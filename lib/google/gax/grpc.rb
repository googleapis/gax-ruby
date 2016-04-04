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


# creates a test stub that accesses host:port securely.
def create_stub(opts)
  address = "#{opts.host}:#{opts.port}"
  if opts.secure
    creds = ssl_creds(opts.use_test_ca)
    stub_opts = {
      GRPC::Core::Channel::SSL_TARGET => opts.host_override
    }

    # Add service account creds if specified
    wants_creds = %w(all compute_engine_creds service_account_creds)
    if wants_creds.include?(opts.test_case)
      unless opts.oauth_scope.nil?
        auth_creds = Google::Auth.get_application_default(opts.oauth_scope)
        call_creds = GRPC::Core::CallCredentials.new(auth_creds.updater_proc)
        creds = creds.compose call_creds
      end
    end

    if opts.test_case == 'oauth2_auth_token'
      auth_creds = Google::Auth.get_application_default(opts.oauth_scope)
      kw = auth_creds.updater_proc.call({})  # gives as an auth token

      # use a metadata update proc that just adds the auth token.
      call_creds = GRPC::Core::CallCredentials.new(proc { |md| md.merge(kw) })
      creds = creds.compose call_creds
    end

    if opts.test_case == 'jwt_token_creds'  # don't use a scope
      auth_creds = Google::Auth.get_application_default
      call_creds = GRPC::Core::CallCredentials.new(auth_creds.updater_proc)
      creds = creds.compose call_creds
    end

    GRPC.logger.info("... connecting securely to #{address}")
    Grpc::Testing::TestService::Stub.new(address, creds, **stub_opts)
  else
    GRPC.logger.info("... connecting insecurely to #{address}")
    Grpc::Testing::TestService::Stub.new(address, :this_channel_is_insecure)
  end
end


module Google
  module Gax
    module Grpc
      API_ERRORS = [GRPC::BadStatus, GRPC::Cancelled].freeze


      # Creates a gRPC client stub.
      #
      # Args:
      #   generated_create_stub: The generated gRPC method to create a stub.
      #   service_path: The domain name of the API remote host.
      #   port: The port on which to connect to the remote host.
      #   ssl_creds: A ClientCredentials object for use with an SSL-enabled
      #         Channel. If none, credentials are pulled from a default location.
      #   channel: A Channel object through which to make calls. If none, a secure
      #         channel is constructed.
      #   metadata_transformer: A function that transforms the metadata for
      #         requests, e.g., to give OAuth credentials.
      #   scopes: The OAuth scopes for this service. This parameter is ignored if
      #      a custom metadata_transformer is supplied.
      #
      # Returns:
      #     A gRPC client stub.
      # """
      def create_stub(service_path,
                      port,
                      ssl_creds,
                      channel,
                      updater_proc,
                      scopes,
                      &blk)
        address = "#{service_path}:#{port}"
        if channel.nil?
          ssl_creds = GRPC::Core::ChannelCredentials.new if ssl_creds.nil?
        end
      end
      module_function :create_stub
    end
  end
end
