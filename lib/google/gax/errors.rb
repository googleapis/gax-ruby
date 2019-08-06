# Copyright 2016, Google LLC
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

require 'English'

require 'google/gax/grpc'

module Google
  module Gax
    # Common base class for exceptions raised by GAX.
    class GaxError < StandardError
      attr_reader :status_details

      # @param msg [String] describes the error that occurred.
      def initialize(msg)
        msg = "GaxError #{msg}"
        msg += ", caused by #{$ERROR_INFO}" if $ERROR_INFO
        super(msg)
        @cause = $ERROR_INFO
        @status_details = \
          Google::Gax::Grpc.deserialize_error_status_details(@cause)
      end

      # cause is a new method introduced in 2.1.0, bring this
      # method if it does not exist.
      unless respond_to?(:cause)
        define_method(:cause) do
          @cause
        end
      end

      def code
        return nil unless cause && cause.respond_to?(:code)
        cause.code
      end

      def details
        return nil unless cause && cause.respond_to?(:details)
        cause.details
      end

      def metadata
        return nil unless cause && cause.respond_to?(:metadata)
        cause.metadata
      end
    end

    def from_error(error)
      if error.respond_to? :code
        grpc_error_class_for error.code
      else
        GaxError
      end
    end

    # Indicates an error during automatic GAX retrying.
    class RetryError < GaxError
    end

    # Errors corresponding to standard HTTP/gRPC statuses.
    class CanceledError < GaxError
    end

    class UnknownError < GaxError
    end

    class InvalidArgumentError < GaxError
    end

    class DeadlineExceededError < GaxError
    end

    class NotFoundError < GaxError
    end

    class AlreadyExistsError < GaxError
    end

    class PermissionDeniedError < GaxError
    end

    class ResourceExhaustedError < GaxError
    end

    class FailedPreconditionError < GaxError
    end

    class AbortedError < GaxError
    end

    class OutOfRangeError < GaxError
    end

    class UnimplementedError < GaxError
    end

    class InternalError < GaxError
    end

    class UnavailableError < GaxError
    end

    class DataLossError < GaxError
    end

    class UnauthenticatedError < GaxError
    end

    # @private Identify the subclass for a gRPC error
    # Note: ported from
    # https:/g/github.com/GoogleCloudPlatform/google-cloud-ruby/blob/master/google-cloud-core/lib/google/cloud/errors.rb
    def self.grpc_error_class_for(grpc_error_code)
      # The gRPC status code 0 is for a successful response.
      # So there is no error subclass for a 0 status code, use current class.
      [GaxError, CanceledError, UnknownError, InvalidArgumentError,
       DeadlineExceededError, NotFoundError, AlreadyExistsError,
       PermissionDeniedError, ResourceExhaustedError, FailedPreconditionError,
       AbortedError, OutOfRangeError, UnimplementedError, InternalError,
       UnavailableError, DataLossError,
       UnauthenticatedError][grpc_error_code] || GaxError
    end

    module_function :from_error
  end
end
