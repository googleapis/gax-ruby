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

describe Google::Gax, :retry do
  it 'retries the API call with exponential backoff' do
    time_now = Time.now
    Time.stub :now, time_now do
      to_attempt = 5
      deadline_arg = nil

      func = proc do |deadline: nil, **_kwargs|
        deadline_arg = deadline
        to_attempt -= 1
        raise CodeError.new('', FAKE_STATUS_CODE_1) if to_attempt > 0
        1729
      end

      func2 = proc do |request, **kwargs|
        OperationStub.new { func.call(request, **kwargs) }
      end

      my_callable = Google::Gax.create_api_call(func2)

      options = Google::Gax::CallOptions.new retry_codes: [14, 101]

      mock = Minitest::Mock.new
      mock.expect :sleep, nil, [1]
      mock.expect :sleep, nil, [1 * 1.3]
      mock.expect :sleep, nil, [1 * 1.3 * 1.3]
      mock.expect :sleep, nil, [1 * 1.3 * 1.3 * 1.3]
      sleep_proc = ->(count) { mock.sleep count }

      Kernel.stub :sleep, sleep_proc do
        _(my_callable.call(nil, options)).must_equal(1729)
        _(to_attempt).must_equal(0)
        _(deadline_arg).must_be_kind_of(Time)
      end

      mock.verify
    end
  end

  it 'doesn\'t retry if no codes' do
    call_count = 0
    func = proc do
      call_count += 1
      raise GRPC::BadStatus.new(FAKE_STATUS_CODE_1, 'unknown')
    end

    my_callable = Google::Gax.create_api_call(func)

    expect { my_callable.call }.must_raise(Google::Gax::GaxError)
    _(call_count).must_equal(1)
  end

  it 'aborts retries' do
    func = proc { raise GRPC::BadStatus.new(FAKE_STATUS_CODE_1, 'unknown') }
    my_callable = Google::Gax.create_api_call(func)
    begin
      my_callable.call
      _(true).to be false # should not reach to this line.
    rescue Google::Gax::GaxError => exc
      _(exc.cause).must_be_kind_of(GRPC::BadStatus)
    end
  end

  it 'times out' do
    to_attempt = 6
    call_count = 0

    deadline_arg = nil
    func = proc do |deadline: nil, **_kwargs|
      deadline_arg = deadline
      call_count += 1
      raise GRPC::BadStatus.new(FAKE_STATUS_CODE_1, 'unknown')
    end

    my_callable = Google::Gax.create_api_call(func)

    options = Google::Gax::CallOptions.new retry_codes: [14, 101]

    time_now = Time.now
    time_proc = lambda do
      delay = 60
      time_dup = time_now
      time_now += delay
      time_dup
    end

    mock = Minitest::Mock.new
    mock.expect :sleep, nil, [1]
    mock.expect :sleep, nil, [1 * 1.3]
    mock.expect :sleep, nil, [1 * 1.3 * 1.3]
    mock.expect :sleep, nil, [1 * 1.3 * 1.3 * 1.3]
    mock.expect :sleep, nil, [1 * 1.3 * 1.3 * 1.3 * 1.3]
    sleep_proc = ->(count) { mock.sleep count }

    Kernel.stub :sleep, sleep_proc do
      Time.stub :now, time_proc do
        begin
          my_callable.call nil, options
          _(true).must_equal false # should not reach to this line.
        rescue Google::Gax::GaxError => exc
          _(exc.cause).must_be_kind_of(GRPC::BadStatus)
        end
        _(deadline_arg).must_equal(time_now - 120)
        _(call_count).must_equal(to_attempt)
      end
    end

    mock.verify
  end

  it 'aborts on unexpected exception' do
    call_count = 0
    func = proc do
      call_count += 1
      raise NonCodeError.new('')
    end
    my_callable = Google::Gax.create_api_call(func)
    expect { my_callable.call }.must_raise(NonCodeError)
    _(call_count).must_equal(1)
  end

  it 'does not retry even when no responses' do
    func = proc { nil }
    func2 = proc do |request, **kwargs|
      OperationStub.new { func.call(request, **kwargs) }
    end
    my_callable = Google::Gax.create_api_call(func2)
    _(my_callable.call).must_be_nil
  end
end
