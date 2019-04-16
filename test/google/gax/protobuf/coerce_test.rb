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

class ProtobufCoerceTest < Minitest::Spec
  REQUEST_NAME = "path/to/ernest".freeze
  USER_NAME = "Ernest".freeze
  USER_TYPE = :ADMINISTRATOR
  POST_TEXT = "This is a test post.".freeze
  MAP = {
    "key1" => "val1",
    "key2" => "val2"
  }.freeze

  it "creates a protobuf message from a simple hash" do
    hash = { name: USER_NAME, type: USER_TYPE }
    user = Google::Gax::Protobuf.coerce hash, to: Google::Gax::User
    _(user).must_be_kind_of Google::Gax::User
    _(user.name).must_equal USER_NAME
    _(user.type).must_equal USER_TYPE
  end

  it "creates a protobuf message from a hash with a nested message" do
    request_hash = { name: REQUEST_NAME, user: Google::Gax::User.new(name: USER_NAME, type: USER_TYPE) }
    request = Google::Gax::Protobuf.coerce request_hash, to: Google::Gax::Request
    _(request).must_be_kind_of Google::Gax::Request
    _(request.name).must_equal REQUEST_NAME
    _(request.user).must_be_kind_of Google::Gax::User
    _(request.user.name).must_equal USER_NAME
    _(request.user.type).must_equal USER_TYPE
  end

  it "creates a protobuf message from a hash with a nested hash" do
    request_hash = { name: REQUEST_NAME, user: { name: USER_NAME, type: USER_TYPE } }
    request = Google::Gax::Protobuf.coerce request_hash, to: Google::Gax::Request
    _(request).must_be_kind_of Google::Gax::Request
    _(request.name).must_equal REQUEST_NAME
    _(request.user).must_be_kind_of Google::Gax::User
    _(request.user.name).must_equal USER_NAME
    _(request.user.type).must_equal USER_TYPE
  end

  it "handles nested arrays of both messages and hashes" do
    user_hash = {
      name:  USER_NAME,
      type:  USER_TYPE,
      posts: [
        { text: POST_TEXT },
        Google::Gax::Post.new(text: POST_TEXT)
      ]
    }
    user = Google::Gax::Protobuf.coerce user_hash, to: Google::Gax::User
    _(user).must_be_kind_of Google::Gax::User
    _(user.name).must_equal USER_NAME
    _(user.type).must_equal USER_TYPE
    _(user.posts).must_be_kind_of Google::Protobuf::RepeatedField
    user.posts.each do |post|
      _(post).must_be_kind_of Google::Gax::Post
      _(post.text).must_equal POST_TEXT
    end
  end

  it "handles maps" do
    request_hash = { name: USER_NAME, map_field: MAP }
    user = Google::Gax::Protobuf.coerce request_hash, to: Google::Gax::User
    _(user).must_be_kind_of Google::Gax::User
    _(user.name).must_equal USER_NAME
    _(user.map_field).must_be_kind_of Google::Protobuf::Map
    user.map_field.each do |k, v|
      _(MAP[k]).must_equal v
    end
  end

  it "handles IO instances" do
    file = File.new "test/fixtures/fixture_file.txt"
    request_hash = { bytes_field: file }
    user = Google::Gax::Protobuf.coerce request_hash, to: Google::Gax::User
    _(user.bytes_field).must_equal "This is a text file.\n"
  end

  it "handles StringIO instances" do
    expected = "This is a StringIO."
    string_io = StringIO.new expected
    request_hash = { bytes_field: string_io }
    user = Google::Gax::Protobuf.coerce request_hash, to: Google::Gax::User
    _(user.bytes_field).must_equal expected
  end

  it "auto-coerces Time" do
    seconds = 271_828_182
    nanos = 845_904_523
    # Fixnum, not float, for precision
    sometime = seconds + nanos * 10**-9
    request_hash = { timestamp: Time.at(sometime) }
    user = Google::Gax::Protobuf.coerce request_hash, to: Google::Gax::User
    expected = Google::Protobuf::Timestamp.new seconds: seconds, nanos: nanos
    _(user.timestamp).must_equal expected
  end

  it "fails if a key does not exist in the target message type" do
    user_hash = { name: USER_NAME, fake_key: "fake data" }
    expect do
      Google::Gax::Protobuf.coerce user_hash, to: Google::Gax::User
    end.must_raise(ArgumentError)
  end

  it "handles proto messages" do
    user_message = Google::Gax::User.new( name: USER_NAME, type: USER_TYPE )
    user = Google::Gax::Protobuf.coerce user_message, to: Google::Gax::User
    _(user).must_equal user_message
  end

  it "fails if proto message has unexpected type" do
    user_message = Google::Protobuf::Any
    expect do
      Google::Gax::Protobuf.coerce user_message, Google::Gax::User
    end.must_raise(ArgumentError)
  end
end
