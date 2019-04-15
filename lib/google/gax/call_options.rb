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

require 'google/gax/api_call/retry_policy'

module Google
  module Gax
    ##
    # Encapsulates the overridable settings for a particular API call.
    #
    # @!attribute [r] metadata
    #   @return [Hash]
    # @!attribute [r] retry_policy
    #   @return [RetryPolicy, Object]
    #
    class CallOptions
      attr_reader :metadata, :retry_policy

      ##
      # Create a new CallOptions object instance.
      #
      # @param timeout [Numeric] The client-side timeout for API calls.
      # @param metadata [Hash] The request header params.
      # @param retry_policy [ApiCall::RetryPolicy, Hash, Proc] The policy for
      #   error retry. A custom proc that takes the error as an argument and
      #   blocks can also be provided.
      #
      def initialize(timeout: nil, metadata: nil, retry_policy: nil)
        if retry_policy.respond_to? :to_h
          # Converts hash and nil to a policy object
          retry_policy = ApiCall::RetryPolicy.new(retry_policy.to_h)
        end

        @timeout = timeout # allow to be nil so it can be overridden
        @metadata = metadata.to_h # Ensure always hash, even for nil
        @retry_policy = retry_policy
      end

      ##
      # client-side timeout for API calls
      #
      # @return [Numeric]
      def timeout
        @timeout || 300
      end

      ##
      # @private
      #
      # @param timeout [Numeric] The client-side timeout for API calls.
      # @param metadata [Hash] the request header params.
      # @param retry_policy [Hash] the policy for error retry.
      def merge(timeout: nil, metadata: nil, retry_policy: nil)
        @timeout ||= timeout
        @metadata = metadata.merge(@metadata) if metadata
        @retry_policy.merge(retry_policy) if @retry_policy.respond_to?(:merge)
      end
    end
  end
end
