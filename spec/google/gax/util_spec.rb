# Copyright 2017, Google LLC
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

require 'google/gax'
require 'google/protobuf/any_pb'
require 'google/protobuf/timestamp_pb'
require 'spec/fixtures/fixture_pb'
require 'stringio'

describe Google::Gax do
  describe '#to_proto' do
    REQUEST_NAME = 'path/to/ernest'.freeze
    USER_NAME = 'Ernest'.freeze
    USER_TYPE = :ADMINISTRATOR
    POST_TEXT = 'This is a test post.'.freeze
    MAP = {
      'key1' => 'val1',
      'key2' => 'val2'
    }.freeze

    it 'creates a protobuf message from a simple hash' do
      hash = { name: USER_NAME, type: USER_TYPE }
      user = Google::Gax.to_proto(hash, Google::Protobuf::User)
      expect(user).to be_an_instance_of(Google::Protobuf::User)
      expect(user.name).to eq(USER_NAME)
      expect(user.type).to eq(USER_TYPE)
    end

    it 'creates a protobuf message from a hash with a nested message' do
      request_hash = {
        name: REQUEST_NAME,
        user: Google::Protobuf::User.new(name: USER_NAME, type: USER_TYPE)
      }
      request = Google::Gax.to_proto(request_hash, Google::Protobuf::Request)
      expect(request).to be_an_instance_of(Google::Protobuf::Request)
      expect(request.name).to eq(REQUEST_NAME)
      expect(request.user).to be_an_instance_of(Google::Protobuf::User)
      expect(request.user.name).to eq(USER_NAME)
      expect(request.user.type).to eq(USER_TYPE)
    end

    it 'creates a protobuf message from a hash with a nested hash' do
      request_hash = {
        name: REQUEST_NAME,
        user: { name: USER_NAME, type: USER_TYPE }
      }
      request = Google::Gax.to_proto(request_hash, Google::Protobuf::Request)
      expect(request).to be_an_instance_of(Google::Protobuf::Request)
      expect(request.name).to eq(REQUEST_NAME)
      expect(request.user).to be_an_instance_of(Google::Protobuf::User)
      expect(request.user.name).to eq(USER_NAME)
      expect(request.user.type).to eq(USER_TYPE)
    end

    it 'handles nested arrays of both messages and hashes' do
      user_hash = {
        name: USER_NAME,
        type: USER_TYPE,
        posts: [
          { text: POST_TEXT },
          Google::Protobuf::Post.new(text: POST_TEXT)
        ]
      }
      user = Google::Gax.to_proto(user_hash, Google::Protobuf::User)
      expect(user).to be_an_instance_of(Google::Protobuf::User)
      expect(user.name).to eq(USER_NAME)
      expect(user.type).to eq(USER_TYPE)
      expect(user.posts).to be_a(Google::Protobuf::RepeatedField)
      user.posts.each do |post|
        expect(post).to be_an_instance_of(Google::Protobuf::Post)
        expect(post.text).to eq(POST_TEXT)
      end
    end

    it 'handles maps' do
      request_hash = {
        name: USER_NAME,
        map_field: MAP
      }
      user = Google::Gax.to_proto(request_hash, Google::Protobuf::User)
      expect(user).to be_an_instance_of(Google::Protobuf::User)
      expect(user.name).to eq(USER_NAME)
      expect(user.map_field).to be_an_instance_of(Google::Protobuf::Map)
      user.map_field.each do |k, v|
        expect(MAP[k]).to eq v
      end
    end

    it 'handles IO instances' do
      file = File.new('spec/fixtures/fixture_file.txt')
      request_hash = {
        bytes_field: file
      }
      user = Google::Gax.to_proto(request_hash, Google::Protobuf::User)
      expect(user.bytes_field).to eq("This is a text file.\n")
    end

    it 'handles StringIO instances' do
      expected = 'This is a StringIO.'
      string_io = StringIO.new(expected)
      request_hash = {
        bytes_field: string_io
      }
      user = Google::Gax.to_proto(request_hash, Google::Protobuf::User)
      expect(user.bytes_field).to eq(expected)
    end

    it 'auto-coerces Time' do
      seconds = 271_828_182
      nanos = 845_904_523
      # Fixnum, not float, for precision
      sometime = seconds + nanos * 10**-9
      request_hash = {
        timestamp: Time.at(sometime)
      }
      user = Google::Gax.to_proto(request_hash, Google::Protobuf::User)
      expected = Google::Protobuf::Timestamp.new(seconds: seconds, nanos: nanos)
      expect(user.timestamp).to eq(expected)
    end

    it 'fails if a key does not exist in the target message type' do
      user_hash = {
        name: USER_NAME,
        fake_key: 'fake data'
      }
      expect do
        Google::Gax.to_proto(user_hash, Google::Protobuf::User)
      end.to raise_error(ArgumentError)
    end

    it 'handles proto messages' do
      user_message = Google::Protobuf::User.new(
        name: USER_NAME, type: USER_TYPE
      )
      user = Google::Gax.to_proto(user_message, Google::Protobuf::User)
      expect(user).to eq user_message
    end

    it 'fails if proto message has unexpected type' do
      user_message = Google::Protobuf::Any
      expect do
        Google::Gax.to_proto(user_message, Google::Protobuf::User)
      end.to raise_error(ArgumentError)
    end
  end

  describe 'time-timestamp conversion' do
    SECONDS = 271_828_182
    NANOS = 845_904_523
    A_TIME = Time.at(SECONDS + NANOS * 10**-9)
    A_TIMESTAMP =
      Google::Protobuf::Timestamp.new(seconds: SECONDS, nanos: NANOS)

    it 'converts time to timestamp' do
      expect(Google::Gax.time_to_timestamp(A_TIME)).to eq A_TIMESTAMP
    end

    it 'converts timestamp to time' do
      expect(Google::Gax.timestamp_to_time(A_TIMESTAMP)).to eq A_TIME
    end

    it 'is an identity when conversion is a round trip' do
      expect(
        Google::Gax.timestamp_to_time(Google::Gax.time_to_timestamp(A_TIME))
      ).to eq A_TIME
      expect(
        Google::Gax.time_to_timestamp(
          Google::Gax.timestamp_to_time(A_TIMESTAMP)
        )
      ).to eq A_TIMESTAMP
    end
  end
end
