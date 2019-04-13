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

require 'test_helper'

class ApiCallRaiseTest < Minitest::Test
  def test_traps_exception
    transformer = proc do |ex|
      assert_kind_of(Google::Gax::GaxError, ex)
      raise CodeError.new('', FAKE_STATUS_CODE_2)
    end

    api_meth_stub = proc do
      raise Google::Gax::GaxError.new('')
    end

    api_call = Google::Gax::ApiCall.new(
      api_meth_stub, exception_transformer: transformer
    )

    assert_raises CodeError do
      api_call.call Object.new
    end
  end

  def test_traps_wrapped_exception
    transformer = proc do |ex|
      _(ex).must_be_kind_of(Google::Gax::GaxError)
      raise Exception.new('')
    end

    api_meth_stub = proc do
      raise CodeError.new('', :FAKE_STATUS_CODE_1)
    end

    api_call = Google::Gax::ApiCall.new(
      api_meth_stub, exception_transformer: transformer
    )

    assert_raises Exception do
      api_call.call Object.new
    end
  end

  def test_wraps_grpc_errors
    deadline_arg = nil
    call_count = 0

    api_meth_stub = proc do |deadline: nil, **_kwargs|
      deadline_arg = deadline
      call_count += 1
      raise GRPC::BadStatus.new(2, 'unknown')
    end

    api_call = Google::Gax::ApiCall.new(api_meth_stub)

    exc = assert_raises Google::Gax::GaxError do
      api_call.call Object.new
      raise 'This will never be reached'
    end
    assert_kind_of(GRPC::BadStatus, exc.cause)

    assert_kind_of(Time, deadline_arg)
    assert_equal(1, call_count)
  end

  def test_wont_wrap_non_grpc_errors
    deadline_arg = nil
    call_count = 0

    api_meth_stub = proc do |deadline: nil, **_kwargs|
      deadline_arg = deadline
      call_count += 1
      raise CodeError.new('', FAKE_STATUS_CODE_1)
    end

    api_call = Google::Gax::ApiCall.new(api_meth_stub)

    assert_raises CodeError do
      api_call.call Object.new
    end
    assert_kind_of(Time, deadline_arg)
    assert_equal(1, call_count)
  end
end
