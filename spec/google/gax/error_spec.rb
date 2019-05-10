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

require 'google/gax/errors'
require 'google/protobuf/any_pb'
require 'spec/fixtures/fixture_pb'

describe Google::Gax::GaxError do
  describe 'without cause' do
    it 'presents GRPC::BadStatus values' do
      error = Google::Gax::GaxError.new('no cause')

      expect(error).to be_an_instance_of(Google::Gax::GaxError)
      expect(error.message).to eq('GaxError no cause')
      expect(error.code).to be_nil
      expect(error.details).to be_nil
      expect(error.metadata).to be_nil
      expect(error.status_details).to be_nil

      expect(error.cause).to be_nil
    end
  end

  describe 'with cause as RuntimeError' do
    it 'presents GRPC::BadStatus values' do
      error = wrapped_error('not allowed')

      expect(error).to be_an_instance_of(Google::Gax::GaxError)
      expect(error.message).to eq('GaxError not allowed, caused by not allowed')
      expect(error.code).to be_nil
      expect(error.details).to be_nil
      expect(error.metadata).to be_nil
      expect(error.status_details).to be_nil

      expect(error.cause).to be_an_instance_of(RuntimeError)
      expect(error.cause.message).to eq('not allowed')
    end
  end

  describe 'with cause as GRPC::BadStatus' do
    it 'presents GRPC::BadStatus values' do
      error = wrapped_badstatus(3, 'invalid')

      expect(error).to be_a_kind_of(Google::Gax::GaxError)
      expect(error.message).to eq('GaxError 3:invalid, caused by 3:invalid')
      expect(error.code).to eq(3)
      expect(error.details).to eq('invalid')
      expect(error.metadata).to eq({})
      expect(error.status_details).to eq(
        'Could not parse error details due to a ' \
        'malformed server response trailer.'
      )

      expect(error.cause).to be_an_instance_of(GRPC::BadStatus)
      expect(error.cause.message).to eq('3:invalid')
      expect(error.cause.code).to eq(3)
      expect(error.cause.details).to eq('invalid')
      expect(error.cause.metadata).to eq({})
    end
  end

  describe 'with cause as GRPC::BadStatus with status_detail' do
    it 'presents GRPC::BadStatus values' do
      status_detail = debug_info('hello world')
      encoded_status_detail = encoded_protobuf(status_detail)
      metadata = { 'foo' => 'bar',
                   'grpc-status-details-bin' => encoded_status_detail }
      error = wrapped_badstatus(1, 'cancelled', metadata)

      expect(error).to be_a_kind_of(Google::Gax::GaxError)
      expect(error.message).to eq('GaxError 1:cancelled, caused by 1:cancelled')
      expect(error.code).to eq(1)
      expect(error.details).to eq('cancelled')
      expect(error.metadata).to eq(metadata)
      expect(error.status_details).to eq([status_detail])

      expect(error.cause).to be_an_instance_of(GRPC::BadStatus)
      expect(error.cause.message).to eq('1:cancelled')
      expect(error.cause.code).to eq(1)
      expect(error.cause.details).to eq('cancelled')
      expect(error.cause.metadata).to eq(metadata)
    end
  end

  describe '#from_error' do
    it 'identifies CanceledError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(1, 'cancelled')
      expect(mapped_error).to eq Google::Gax::CanceledError
    end

    it 'identifies UnknownError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(2, 'unknown')
      expect(mapped_error).to eq Google::Gax::UnknownError
    end

    it 'identifies InvalidArgumentError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(3, 'invalid')
      expect(mapped_error).to eq Google::Gax::InvalidArgumentError
    end

    it 'identifies DeadlineExceededError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(4, 'exceeded')
      expect(mapped_error).to eq Google::Gax::DeadlineExceededError
    end

    it 'identifies NotFoundError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(5, 'not found')
      expect(mapped_error).to eq Google::Gax::NotFoundError
    end

    it 'identifies AlreadyExistsError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(6, 'exists')
      expect(mapped_error).to eq Google::Gax::AlreadyExistsError
    end

    it 'identifies PermissionDeniedError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(7, 'denied')
      expect(mapped_error).to eq Google::Gax::PermissionDeniedError
    end

    it 'identifies ResourceExhaustedError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(8, 'exhausted')
      expect(mapped_error).to eq Google::Gax::ResourceExhaustedError
    end

    it 'identifies FailedPreconditionError' do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(9, 'precondition')
      expect(mapped_error).to eq Google::Gax::FailedPreconditionError
    end

    it 'identifies AbortedError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(10, 'aborted')
      expect(mapped_error).to eq Google::Gax::AbortedError
    end

    it 'identifies OutOfRangeError' do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(11, 'out of range')
      expect(mapped_error).to eq Google::Gax::OutOfRangeError
    end

    it 'identifies UnimplementedError' do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(12, 'unimplemented')
      expect(mapped_error).to eq Google::Gax::UnimplementedError
    end

    it 'identifies InternalError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(13, 'internal')
      expect(mapped_error).to eq Google::Gax::InternalError
    end

    it 'identifies UnavailableError' do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(14, 'unavailable')
      expect(mapped_error).to eq Google::Gax::UnavailableError
    end

    it 'identifies DataLossError' do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(15, 'data loss')
      expect(mapped_error).to eq Google::Gax::DataLossError
    end

    it 'identifies UnauthenticatedError' do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(16, 'unauthenticated')
      expect(mapped_error).to eq Google::Gax::UnauthenticatedError
    end

    it 'identifies unknown error' do
      # We don't know what to map this error case to
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(0, 'unknown')
      expect(mapped_error).to eq Google::Gax::GaxError

      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(17, 'unknown')
      expect(mapped_error).to eq Google::Gax::GaxError
    end
  end

  def wrap_with_gax_error(err)
    raise err
  rescue => e
    klass = Google::Gax.from_error(e)
    raise klass.new(e.message)
  end

  def wrapped_error(msg)
    wrap_with_gax_error(RuntimeError.new(msg))
  rescue => gax_err
    return gax_err
  end

  def debug_info(detail)
    Google::Rpc::DebugInfo.new(detail: detail)
  end

  def encoded_protobuf(debug_info)
    any = Google::Protobuf::Any.new
    any.pack debug_info

    Google::Rpc::Status.encode(
      Google::Rpc::Status.new(details: [any])
    )
  end

  def wrapped_badstatus(status, msg, metadata = {})
    wrap_with_gax_error(GRPC::BadStatus.new(status, msg, metadata))
  rescue => gax_err
    return gax_err
  end
end
