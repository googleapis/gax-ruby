# Copyright 2016, Google Inc.
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

    # Indicates an error during automatic GAX retrying.
    class RetryError < GaxError
    end
  end
end
