# Copyright 2017, Google Inc.
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

require 'google/gax'
require 'spec/google/gax/util_pb'

describe Google::Gax do
  describe '#to_proto' do
    REQUEST_NAME = 'path/to/ernest'.freeze
    USER_NAME = 'Ernest'.freeze
    USER_TYPE = :ADMINISTRATOR
    POST_TEXT = 'This is a test post.'.freeze

    it 'creates a protobuf message from a simple hash' do
      hash = { name: USER_NAME, type: USER_TYPE }
      user = Google::Gax.to_proto(hash, User)
      expect(user).to be_an_instance_of(User)
      expect(user.name).to eq(USER_NAME)
      expect(user.type).to eq(USER_TYPE)
    end

    it 'creates a protobuf message from a hash with a nested message' do
      request_hash = {
        name: REQUEST_NAME,
        user: User.new(name: USER_NAME, type: USER_TYPE)
      }
      request = Google::Gax.to_proto(request_hash, CreateUserRequest)
      expect(request).to be_an_instance_of(CreateUserRequest)
      expect(request.name).to eq(REQUEST_NAME)
      expect(request.user).to be_an_instance_of(User)
      expect(request.user.name).to eq(USER_NAME)
      expect(request.user.type).to eq(USER_TYPE)
    end

    it 'creates a protobuf message from a hash with a nested hash' do
      request_hash = {
        name: REQUEST_NAME,
        user: { name: USER_NAME, type: USER_TYPE }
      }
      request = Google::Gax.to_proto(request_hash, CreateUserRequest)
      expect(request).to be_an_instance_of(CreateUserRequest)
      expect(request.name).to eq(REQUEST_NAME)
      expect(request.user).to be_an_instance_of(User)
      expect(request.user.name).to eq(USER_NAME)
      expect(request.user.type).to eq(USER_TYPE)
    end

    it 'handles nested arrays of both messages and hashes' do
      user_hash = {
        name: USER_NAME,
        type: USER_TYPE,
        posts: [
          { text: POST_TEXT },
          Post.new(text: POST_TEXT)
        ]
      }
      user = Google::Gax.to_proto(user_hash, User)
      expect(user).to be_an_instance_of(User)
      expect(user.name).to eq(USER_NAME)
      expect(user.type).to eq(USER_TYPE)
      expect(user.posts).to be_a(Google::Protobuf::RepeatedField)
      user.posts.each do |post|
        expect(post).to be_an_instance_of(Post)
        expect(post.text).to eq(POST_TEXT)
      end
    end

    it 'fails if a key does not exist in the target message type' do
      user_hash = {
        name: USER_NAME,
        fake_key: 'fake data'
      }
      expect do
        Google::Gax.to_proto(user_hash, User)
      end.to raise_error(ArgumentError)
    end
  end
end
