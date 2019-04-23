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
# 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "test_helper"
require "google/gax/grpc"

describe Google::Gax::Grpc do
  describe "#deserialize_error_status_details" do
    it "deserializes a known error type" do
      expected_error = Google::Rpc::DebugInfo.new detail: "shoes are untied"

      any = Google::Protobuf::Any.new
      any.pack expected_error
      status = Google::Rpc::Status.new details: [any]
      encoded = Google::Rpc::Status.encode status
      metadata = {
        "grpc-status-details-bin" => encoded
      }
      error = GRPC::BadStatus.new 1, "", metadata

      error_details = Google::Gax::Grpc.deserialize_error_status_details error
      _(error_details).must_equal [expected_error]
    end

    it "does not deserialize an unknown error type" do
      expected_error = Random.new.bytes 8

      any = Google::Protobuf::Any.new(
        type_url: "unknown-type", value: expected_error
      )
      status = Google::Rpc::Status.new details: [any]
      encoded = Google::Rpc::Status.encode status
      metadata = {
        "grpc-status-details-bin" => encoded
      }
      error = GRPC::BadStatus.new 1, "", metadata

      error_details = Google::Gax::Grpc.deserialize_error_status_details error
      _(error_details).must_equal [any]
    end
  end
end
