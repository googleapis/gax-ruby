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
require "grpc"

describe Google::Gax::Headers, :x_goog_api_client do
  it "with no arguments" do
    header = Google::Gax::Headers.x_goog_api_client
    _(header).must_equal "gl-ruby/#{RUBY_VERSION} gax/#{Google::Gax::VERSION} grpc/#{GRPC::VERSION}"
  end

  it "prints lib when provided" do
    header = Google::Gax::Headers.x_goog_api_client lib_name: "foo", lib_version: "bar"
    _(header).must_equal "gl-ruby/#{RUBY_VERSION} foo/bar gax/#{Google::Gax::VERSION} grpc/#{GRPC::VERSION}"
  end

  it "prints gapic version when provided" do
    header = Google::Gax::Headers.x_goog_api_client gapic_version: "foobar"
    _(header).must_equal "gl-ruby/#{RUBY_VERSION} gapic/foobar gax/#{Google::Gax::VERSION} grpc/#{GRPC::VERSION}"
  end

  it "prints all arguments provided" do
    header = Google::Gax::Headers.x_goog_api_client ruby_version: "1.2.3", lib_name: "foo", lib_version: "bar",
                                                    gapic_version: "4.5.6", gax_version: "7.8.9", grpc_version: "24601"
    _(header).must_equal "gl-ruby/1.2.3 foo/bar gapic/4.5.6 gax/7.8.9 grpc/24601"
  end
end
