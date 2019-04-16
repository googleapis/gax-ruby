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
require "google/protobuf/any_pb"
require "google/protobuf/timestamp_pb"
require "stringio"

class ProtobufTimeTest < Minitest::Spec
  SECONDS = 271_828_182
  NANOS = 845_904_523
  A_TIME = Time.at SECONDS + NANOS * 10**-9
  A_TIMESTAMP =
    Google::Protobuf::Timestamp.new seconds: SECONDS, nanos: NANOS

  it "converts time to timestamp" do
    _(Google::Gax::Protobuf.time_to_timestamp(A_TIME)).must_equal A_TIMESTAMP
  end

  it "converts timestamp to time" do
    _(Google::Gax::Protobuf.timestamp_to_time(A_TIMESTAMP)).must_equal A_TIME
  end

  it "is an identity when conversion is a round trip" do
    _(
      Google::Gax::Protobuf.timestamp_to_time(Google::Gax::Protobuf.time_to_timestamp(A_TIME))
    ).must_equal A_TIME
    _(
      Google::Gax::Protobuf.time_to_timestamp(
        Google::Gax::Protobuf.timestamp_to_time(A_TIMESTAMP)
      )
    ).must_equal A_TIMESTAMP
  end
end
