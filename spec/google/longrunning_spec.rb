# Copyright 2019, Google LLC
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

require 'google/gax'
require 'google/longrunning/operations_client'

class MockCredentials < Google::Auth::Credentials
  def initialize; end

  def updater_proc
    proc do
      raise 'The credentials tried to make an update request. This should' \
        ' not happen since the grpc layer is being mocked.'
    end
  end
end

describe Google::Longrunning::OperationsClient do
  it 'uses the default address' do
    client = Google::Longrunning::OperationsClient.new(
      credentials: MockCredentials.new
    )
    host = client.instance_variable_get(:@operations_stub)
                 .instance_variable_get(:@host)
    expect(host).to eq('longrunning.googleapis.com:443')
  end

  it 'supports subclass overriding of the address' do
    class CustomClient < Google::Longrunning::OperationsClient
      SERVICE_ADDRESS = 'my-service.example.com'.freeze
      DEFAULT_SERVICE_PORT = 8080
    end
    client = CustomClient.new(credentials: MockCredentials.new)
    host = client.instance_variable_get(:@operations_stub)
                 .instance_variable_get(:@host)
    expect(host).to eq('my-service.example.com:8080')
  end

  it 'supports parameter overriding of the address' do
    client = CustomClient.new(credentials: MockCredentials.new,
                              service_address: 'foo-service.example.com',
                              service_port: 8081)
    host = client.instance_variable_get(:@operations_stub)
                 .instance_variable_get(:@host)
    expect(host).to eq('foo-service.example.com:8081')
  end
end
