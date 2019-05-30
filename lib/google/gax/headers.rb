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

require "google/gax/operation/retry_policy"
require "google/protobuf/well_known_types"

module Google
  module Gax
    # A collection of common header values.
    module Headers
      ##
      # @param ruby_version [String] The ruby version. Defaults to `RUBY_VERSION`.
      # @param lib_name [String] The client library name.
      # @param lib_version [String] The client library version.
      # @param gapic_version [String] The GAPIC client version.
      # @param gax_version [String] The Gax version. Defaults to `Google::Gax::VERSION`.
      # @param grpc_version [String] The GRPC version. Defaults to `GRPC::VERSION`.
      def self.x_goog_api_client ruby_version: nil, lib_name: nil, lib_version: nil,
                                 gapic_version: nil, gax_version: nil, grpc_version: nil
        ruby_version ||= ::RUBY_VERSION
        gax_version  ||= ::Google::Gax::VERSION
        grpc_version ||= ::GRPC::VERSION if defined? ::GRPC

        x_goog_api_client_header = ["gl-ruby/#{ruby_version}"]
        x_goog_api_client_header << "#{lib_name}/#{lib_version}" if lib_name
        x_goog_api_client_header << "gapic/#{gapic_version}" if gapic_version
        x_goog_api_client_header << "gax/#{gax_version}"
        x_goog_api_client_header << "grpc/#{grpc_version}" if grpc_version
        x_goog_api_client_header.join " ".freeze
      end
    end
  end
end
