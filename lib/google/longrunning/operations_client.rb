# Copyright 2017, Google LLC All rights reserved.
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
#
# EDITING INSTRUCTIONS
# This file was generated from the file
# https://github.com/googleapis/googleapis/blob/master/google/longrunning/operations.proto,
# and updates to that file get reflected here through a refresh process.
# For the short term, the refresh process will only be runnable by Google
# engineers.
#
# The only allowed edits are to method and file documentation. A 3-way
# merge preserves those additions if the generated source changes.

require "json"
require "pathname"

require "google/gax"
require "googleauth"

require "google/longrunning/operations_pb"

module Google
  module Longrunning
    # Manages long-running operations with an API service.
    #
    # When an API method normally takes long time to complete, it can be designed
    # to return {Google::Longrunning::Operation Operation} to the client, and the client can use this
    # interface to receive the real response asynchronously by polling the
    # operation resource, or pass the operation resource to another API (such as
    # Google Cloud Pub/Sub API) to receive the response.  Any API service that
    # returns long-running operations should implement the +Operations+ interface
    # so developers can have a consistent client experience.
    #
    # @!attribute [r] operations_stub
    #   @return [Google::Longrunning::Operations::Stub]
    class OperationsClient
      attr_reader :operations_stub

      # The default address of the service.
      SERVICE_ADDRESS = "longrunning.googleapis.com".freeze

      # The default port of the service.
      DEFAULT_SERVICE_PORT = 443

      DEFAULT_TIMEOUT = 30

      # The scopes needed to make gRPC calls to all of the methods defined in
      # this service.
      ALL_SCOPES = [
      ].freeze


      # @param credentials [Google::Auth::Credentials, String, Hash, GRPC::Core::Channel, GRPC::Core::ChannelCredentials, Proc]
      #   Provides the means for authenticating requests made by the client. This parameter can
      #   be many types.
      #   A `Google::Auth::Credentials` uses a the properties of its represented keyfile for
      #   authenticating requests made by this client.
      #   A `String` will be treated as the path to the keyfile to be used for the construction of
      #   credentials for this client.
      #   A `Hash` will be treated as the contents of a keyfile to be used for the construction of
      #   credentials for this client.
      #   A `GRPC::Core::Channel` will be used to make calls through.
      #   A `GRPC::Core::ChannelCredentials` for the setting up the RPC client. The channel credentials
      #   should already be composed with a `GRPC::Core::CallCredentials` object.
      #   A `Proc` will be used as an updater_proc for the Grpc channel. The proc transforms the
      #   metadata for requests, generally, to give OAuth credentials.
      # @param scopes [Array<String>]
      #   The OAuth scopes for this service. This parameter is ignored if
      #   an updater_proc is supplied.
      # @param timeout [Numeric]
      #   The default timeout, in seconds, for calls made through this client.
      def initialize \
          credentials: nil,
          scopes: ALL_SCOPES,
          timeout: DEFAULT_TIMEOUT,
          lib_name: nil,
          lib_version: ""
        # These require statements are intentionally placed here to initialize
        # the gRPC module only when it's required.
        # See https://github.com/googleapis/toolkit/issues/446
        require "google/gax/grpc"
        require "google/longrunning/operations_services_pb"

        credentials ||= Google::Auth::Credentials.default(scope: scopes)

        if credentials.is_a?(String) || credentials.is_a?(Hash)
          updater_proc = Google::Auth::Credentials.new(credentials, scope: scopes).updater_proc
        end
        if credentials.is_a?(GRPC::Core::Channel)
          channel = credentials
        end
        if credentials.is_a?(GRPC::Core::ChannelCredentials)
          chan_creds = credentials
        end
        if credentials.is_a?(Proc)
          updater_proc = credentials
        end
        if credentials.is_a?(Google::Auth::Credentials)
          updater_proc = credentials.updater_proc
        end

        metadata = default_gax_client_metadata(lib_name, lib_version)

        # Allow overriding the service path/port in subclasses.
        service_path = self.class::SERVICE_ADDRESS
        port = self.class::DEFAULT_SERVICE_PORT
        @operations_stub = Google::Gax::Grpc.create_stub(
          service_path,
          port,
          chan_creds: chan_creds,
          channel: channel,
          updater_proc: updater_proc,
          scopes: scopes,
          &Google::Longrunning::Operations::Stub.method(:new)
        )

        @get_operation = Google::Gax.create_api_call(
          @operations_stub.method(:get_operation),
          timeout: timeout, metadata: metadata,
          retry_codes: [14]
        )
        @list_operations = Google::Gax.create_api_call(
          @operations_stub.method(:list_operations),
          timeout: timeout, metadata: metadata,
          retry_codes: [14]
        )
        @cancel_operation = Google::Gax.create_api_call(
          @operations_stub.method(:cancel_operation),
          timeout: timeout, metadata: metadata,
          retry_codes: [14]
        )
        @delete_operation = Google::Gax.create_api_call(
          @operations_stub.method(:delete_operation),
          timeout: timeout, metadata: metadata,
          retry_codes: [14]
        )
      end

      # Service calls

      # Gets the latest state of a long-running operation.  Clients can use this
      # method to poll the operation result at intervals as recommended by the API
      # service.
      #
      # @param name [String]
      #   The name of the operation resource.
      # @param options [Google::Gax::CallOptions]
      #   Overrides the default settings for this call, e.g, timeout,
      #   retries, etc.
      # @return [Google::Longrunning::Operation]
      # @raise [Google::Gax::GaxError] if the RPC is aborted.
      # @example
      #   require "google/longrunning"
      #
      #   operations_client = Google::Longrunning.new
      #   name = ''
      #   response = operations_client.get_operation(name)

      def get_operation \
          name,
          options: nil
        req = {
          name: name
        }.delete_if { |_, v| v.nil? }
        req = Google::Gax::to_proto(req, Google::Longrunning::GetOperationRequest)
        @get_operation.call(req, options)
      end

      # Lists operations that match the specified filter in the request. If the
      # server doesn't support this method, it returns +UNIMPLEMENTED+.
      #
      # NOTE: the +name+ binding below allows API services to override the binding
      # to use different resource name schemes, such as +users/*/operations+.
      #
      # @param name [String]
      #   The name of the operation collection.
      # @param filter [String]
      #   The standard list filter.
      # @param page_size [Integer]
      #   The maximum number of resources contained in the underlying API
      #   response. If page streaming is performed per-resource, this
      #   parameter does not affect the return value. If page streaming is
      #   performed per-page, this determines the maximum number of
      #   resources in a page.
      # @param options [Google::Gax::CallOptions]
      #   Overrides the default settings for this call, e.g, timeout,
      #   retries, etc.
      # @return [Google::Gax::PagedEnumerable<Google::Longrunning::Operation>]
      #   An enumerable of Google::Longrunning::Operation instances.
      #   See Google::Gax::PagedEnumerable documentation for other
      #   operations such as per-page iteration or access to the response
      #   object.
      # @raise [Google::Gax::GaxError] if the RPC is aborted.
      # @example
      #   require "google/longrunning"
      #
      #   operations_client = Google::Longrunning.new
      #   name = ''
      #   filter = ''
      #
      #   # Iterate over all results.
      #   operations_client.list_operations(name, filter).each do |element|
      #     # Process element.
      #   end
      #
      #   # Or iterate over results one page at a time.
      #   operations_client.list_operations(name, filter).each_page do |page|
      #     # Process each page at a time.
      #     page.each do |element|
      #       # Process element.
      #     end
      #   end

      def list_operations \
          name,
          filter,
          page_size: nil,
          options: nil
        req = {
          name: name,
          filter: filter,
          page_size: page_size
        }.delete_if { |_, v| v.nil? }
        req = Google::Gax::to_proto(req, Google::Longrunning::ListOperationsRequest)
        resp = @list_operations.call(req, options)
        Google::Gax::PagedEnumerable.new(@list_operations, req, resp, options)
      end

      # Starts asynchronous cancellation on a long-running operation.  The server
      # makes a best effort to cancel the operation, but success is not
      # guaranteed.  If the server doesn't support this method, it returns
      # +google.rpc.Code.UNIMPLEMENTED+.  Clients can use
      # {Google::Longrunning::Operations::GetOperation Operations::GetOperation} or
      # other methods to check whether the cancellation succeeded or whether the
      # operation completed despite cancellation. On successful cancellation,
      # the operation is not deleted; instead, it becomes an operation with
      # an {Google::Longrunning::Operation#error Operation#error} value with a {Google::Rpc::Status#code} of 1,
      # corresponding to +Code.CANCELLED+.
      #
      # @param name [String]
      #   The name of the operation resource to be cancelled.
      # @param options [Google::Gax::CallOptions]
      #   Overrides the default settings for this call, e.g, timeout,
      #   retries, etc.
      # @raise [Google::Gax::GaxError] if the RPC is aborted.
      # @example
      #   require "google/longrunning"
      #
      #   operations_client = Google::Longrunning.new
      #   name = ''
      #   operations_client.cancel_operation(name)

      def cancel_operation \
          name,
          options: nil
        req = {
          name: name
        }.delete_if { |_, v| v.nil? }
        req = Google::Gax::to_proto(req, Google::Longrunning::CancelOperationRequest)
        @cancel_operation.call(req, options)
        nil
      end

      # Deletes a long-running operation. This method indicates that the client is
      # no longer interested in the operation result. It does not cancel the
      # operation. If the server doesn't support this method, it returns
      # +google.rpc.Code.UNIMPLEMENTED+.
      #
      # @param name [String]
      #   The name of the operation resource to be deleted.
      # @param options [Google::Gax::CallOptions]
      #   Overrides the default settings for this call, e.g, timeout,
      #   retries, etc.
      # @raise [Google::Gax::GaxError] if the RPC is aborted.
      # @example
      #   require "google/longrunning"
      #
      #   operations_client = Google::Longrunning.new
      #   name = ''
      #   operations_client.delete_operation(name)

      def delete_operation \
          name,
          options: nil
        req = {
          name: name
        }.delete_if { |_, v| v.nil? }
        req = Google::Gax::to_proto(req, Google::Longrunning::DeleteOperationRequest)
        @delete_operation.call(req, options)
        nil
      end

      protected

      def default_gax_client_metadata(lib_name, lib_version)
        package_version = Gem.loaded_specs['google-gax'].version.version

        google_api_client = ["gl-ruby/#{RUBY_VERSION}"]
        google_api_client << "#{lib_name}/#{lib_version}" if lib_name
        google_api_client << "gapic/#{package_version}"
        google_api_client << "gax/#{Google::Gax::VERSION}"
        google_api_client << "grpc/#{GRPC::VERSION}"
        google_api_client.join " "

        { 'x-goog-api-client' => google_api_client }
      end
    end
  end
end
