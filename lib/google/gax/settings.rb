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

module Google
  module Gax
    # Encapsulates the overridable settings for a particular API call
    # @!attribute [rw] timeout
    #   @return [Numeric, :OPTION_INHERIT]
    # @!attribute [rw] metadata
    #   @return [Hash, :OPTION_INHERIT]
    class CallOptions
      attr_accessor :timeout, :metadata

      # @param timeout [Numeric, :OPTION_INHERIT]
      #   The client-side timeout for API calls.
      # @param metadata [Hash, :OPTION_INHERIT] the request header params.
      def initialize(timeout: :OPTION_INHERIT,
                     metadata: :OPTION_INHERIT)
        @timeout = timeout
        @metadata = metadata
      end
    end

    # Parameters to the exponential backoff algorithm for retrying.
    class BackoffSettings < Struct.new(
      :initial_retry_delay_millis,
      :retry_delay_multiplier,
      :max_retry_delay_millis,
      :initial_rpc_timeout_millis,
      :rpc_timeout_multiplier,
      :max_rpc_timeout_millis,
      :total_timeout_millis
    )
      # @!attribute initial_retry_delay_millis
      #   @return [Numeric] the initial delay time, in milliseconds,
      #     between the completion of the first failed request and the
      #     initiation of the first retrying request.
      # @!attribute retry_delay_multiplier
      #   @return [Numeric] the multiplier by which to increase the
      #     delay time between the completion of failed requests, and
      #     the initiation of the subsequent retrying request.
      # @!attribute max_retry_delay_millis
      #   @return [Numeric] the maximum delay time, in milliseconds,
      #     between requests. When this value is reached,
      #     +retry_delay_multiplier+ will no longer be used to
      #     increase delay time.
      # @!attribute initial_rpc_timeout_millis
      #   @return [Numeric] the initial timeout parameter to the request.
      # @!attribute rpc_timeout_multiplier
      #   @return [Numeric] the multiplier by which to increase the
      #     timeout parameter between failed requests.
      # @!attribute max_rpc_timeout_millis
      #   @return [Numeric] the maximum timeout parameter, in
      #     milliseconds, for a request. When this value is reached,
      #     +rpc_timeout_multiplier+ will no longer be used to
      #     increase the timeout.
      # @!attribute total_timeout_millis
      #   @return [Numeric] the total time, in milliseconds, starting
      #     from when the initial request is sent, after which an
      #     error will be returned, regardless of the retrying
      #     attempts made meanwhile.
    end
  end
end
