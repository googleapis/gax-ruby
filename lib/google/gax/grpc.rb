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

require "grpc"
require "google/gax/grpc/stub"
require "grpc/google_rpc_status_utils"
require "google/gax/errors"
require "google/protobuf/well_known_types"
# Required in order to deserialize common error detail proto types
require "google/rpc/error_details_pb"

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

      def self.deserialize_error_status_details error
        return unless error.is_a? GRPC::BadStatus
        # If error status is malformed, swallow the gRPC error that gets raised.
        begin
          details =
            GRPC::GoogleRpcStatusUtils.extract_google_rpc_status(
              error.to_status
            ).details
        rescue StandardError
          return "Could not parse error details due to a malformed server "\
                 "response trailer."
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
            any.unpack type.msgclass
          rescue StandardError
            any
          end
        end
      end
    end
  end
end
