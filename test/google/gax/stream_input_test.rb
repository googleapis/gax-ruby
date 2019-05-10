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

class StreamInputTest < Minitest::Test
  def test_blocks_until_closed
    closed = false
    stream_request_count = 0

    input = Google::Gax::StreamInput.new

    stream_check_thread = Thread.new do
      input.to_enum { |r| stream_request_count += 1 }
      closed = true
    end

    assert_equal 0, stream_request_count
    refute closed

    input << :foo
    sleep 0.01

    wait_until { 1 == stream_request_count }
    refute closed

    input.push :bar
    sleep 0.01

    wait_until { 2 == stream_request_count }
    refute closed

    input.append :baz
    sleep 0.01

    wait_until { 3 == stream_request_count }
    refute closed

    input.close
    stream_check_thread.join

    assert_equal 3, stream_request_count
    assert closed
  end

  ##
  # This is an ugly way to block on concurrent criteria, but it works...
  def wait_until iterations = 100
    count = 0
    loop do
      raise "criteria not met" if count >= iterations
      break if yield
      sleep 0.0001
      count += 1
    end
  end
end
