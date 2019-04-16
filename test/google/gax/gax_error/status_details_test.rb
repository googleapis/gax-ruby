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

class GaxErrorStatusDetailsTest < Minitest::Spec
  def test_deserializes_known_type
    expected_error = Google::Rpc::DebugInfo.new detail: "shoes are untied"

    any = Google::Protobuf::Any.new
    any.pack expected_error
    status = Google::Rpc::Status.new details: [any]
    encoded = Google::Rpc::Status.encode status
    metadata = {
      "grpc-status-details-bin" => encoded
    }
    error = GRPC::BadStatus.new 1, "", metadata
    gax_error = wrap_error error

    assert_equal [expected_error], gax_error.status_details
  end

  def test_wont_deserialize_unknown_type
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
    gax_error = wrap_error error

    assert_equal [any], gax_error.status_details
  end

  def wrap_error error
    raise error
  rescue => raised_error
    begin
      klass = Google::Gax.from_error raised_error
      raise klass, raised_error.message
    rescue Google::Gax::GaxError => gax_err
      gax_err
    end
  end
end
