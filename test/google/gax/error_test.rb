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

describe Google::Gax::GaxError do
  describe "without cause" do
    it "presents GRPC::BadStatus values" do
      error = Google::Gax::GaxError.new "no cause"

      _(error).must_be_kind_of Google::Gax::GaxError
      _(error.message).must_equal "GaxError no cause"
      _(error.code).must_equal 0
      _(error.details).must_be_empty
      _(error.metadata).must_be_empty
      _(error.status_details).must_be_empty

      _(error.cause).must_be_nil
    end
  end

  describe "with cause as RuntimeError" do
    it "presents GRPC::BadStatus values" do
      error = wrapped_error "not allowed"

      _(error).must_be_kind_of Google::Gax::GaxError
      _(error.message).must_equal "GaxError not allowed, caused by not allowed"
      _(error.code).must_equal 0
      _(error.details).must_be_empty
      _(error.metadata).must_be_empty
      _(error.status_details).must_be_empty

      _(error.cause).must_be_kind_of RuntimeError
      _(error.cause.message).must_equal "not allowed"
    end
  end

  describe "with cause as GRPC::BadStatus" do
    it "presents GRPC::BadStatus values" do
      error = wrapped_badstatus 3, "invalid"

      _(error).must_be_kind_of Google::Gax::GaxError
      _(error.message).must_equal "GaxError 3:invalid, caused by 3:invalid"
      _(error.code).must_equal 3
      _(error.details).must_equal "invalid"
      _(error.metadata).must_equal({})
      _(error.status_details).must_be_empty

      _(error.cause).must_be_kind_of GRPC::BadStatus
      _(error.cause.message).must_equal "3:invalid"
      _(error.cause.code).must_equal 3
      _(error.cause.details).must_equal "invalid"
      _(error.cause.metadata).must_equal({})
    end
  end

  describe "with cause as GRPC::BadStatus with status_detail" do
    it "presents GRPC::BadStatus values" do
      status_detail = debug_info "hello world"
      encoded_status_detail = encoded_protobuf status_detail
      metadata = { "foo"                     => "bar",
                   "grpc-status-details-bin" => encoded_status_detail }
      error = wrapped_badstatus 1, "cancelled", metadata

      _(error).must_be_kind_of Google::Gax::GaxError
      _(error.message).must_equal "GaxError 1:cancelled, caused by 1:cancelled"
      _(error.code).must_equal 1
      _(error.details).must_equal "cancelled"
      _(error.metadata).must_equal metadata
      _(error.status_details).must_equal [status_detail]

      _(error.cause).must_be_kind_of GRPC::BadStatus
      _(error.cause.message).must_equal "1:cancelled"
      _(error.cause.code).must_equal 1
      _(error.cause.details).must_equal "cancelled"
      _(error.cause.metadata).must_equal metadata
    end
  end

  describe "#from_error" do
    it "identifies CanceledError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(1, "cancelled")
      _(mapped_error).must_equal Google::Gax::CanceledError
    end

    it "identifies UnknownError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(2, "unknown")
      _(mapped_error).must_equal Google::Gax::UnknownError
    end

    it "identifies InvalidArgumentError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(3, "invalid")
      _(mapped_error).must_equal Google::Gax::InvalidArgumentError
    end

    it "identifies DeadlineExceededError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(4, "exceeded")
      _(mapped_error).must_equal Google::Gax::DeadlineExceededError
    end

    it "identifies NotFoundError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(5, "not found")
      _(mapped_error).must_equal Google::Gax::NotFoundError
    end

    it "identifies AlreadyExistsError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(6, "exists")
      _(mapped_error).must_equal Google::Gax::AlreadyExistsError
    end

    it "identifies PermissionDeniedError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(7, "denied")
      _(mapped_error).must_equal Google::Gax::PermissionDeniedError
    end

    it "identifies ResourceExhaustedError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(8, "exhausted")
      _(mapped_error).must_equal Google::Gax::ResourceExhaustedError
    end

    it "identifies FailedPreconditionError" do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(9, "precondition")
      _(mapped_error).must_equal Google::Gax::FailedPreconditionError
    end

    it "identifies AbortedError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(10, "aborted")
      _(mapped_error).must_equal Google::Gax::AbortedError
    end

    it "identifies OutOfRangeError" do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(11, "out of range")
      _(mapped_error).must_equal Google::Gax::OutOfRangeError
    end

    it "identifies UnimplementedError" do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(12, "unimplemented")
      _(mapped_error).must_equal Google::Gax::UnimplementedError
    end

    it "identifies InternalError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(13, "internal")
      _(mapped_error).must_equal Google::Gax::InternalError
    end

    it "identifies UnavailableError" do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(14, "unavailable")
      _(mapped_error).must_equal Google::Gax::UnavailableError
    end

    it "identifies DataLossError" do
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(15, "data loss")
      _(mapped_error).must_equal Google::Gax::DataLossError
    end

    it "identifies UnauthenticatedError" do
      mapped_error =
        Google::Gax.from_error GRPC::BadStatus.new(16, "unauthenticated")
      _(mapped_error).must_equal Google::Gax::UnauthenticatedError
    end

    it "identifies unknown error" do
      # We don't know what to map this error case to
      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(0, "unknown")
      _(mapped_error).must_equal Google::Gax::GaxError

      mapped_error = Google::Gax.from_error GRPC::BadStatus.new(17, "unknown")
      _(mapped_error).must_equal Google::Gax::GaxError
    end
  end

  def wrap_with_gax_error err
    raise err
  rescue StandardError => e
    klass = Google::Gax.from_error e
    raise klass, e.message
  end

  def wrapped_error msg
    wrap_with_gax_error RuntimeError.new(msg)
  rescue StandardError => gax_err
    gax_err
  end

  def debug_info detail
    Google::Rpc::DebugInfo.new detail: detail
  end

  def encoded_protobuf debug_info
    any = Google::Protobuf::Any.new
    any.pack debug_info

    Google::Rpc::Status.encode(
      Google::Rpc::Status.new(details: [any])
    )
  end

  def wrapped_badstatus status, msg, metadata = {}
    wrap_with_gax_error GRPC::BadStatus.new(status, msg, metadata)
  rescue StandardError => gax_err
    gax_err
  end
end
