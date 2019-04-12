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

require 'google/gax/retry_settings'

module Google
  module Gax
    # Encapsulates the overridable settings for a particular API call
    # @!attribute [rw] timeout
    #   @return [Numeric, nil]
    # @!attribute [rw] metadata
    #   @return [Hash, nil]
    # @!attribute [rw] retry_codes
    #   @return [Array<Integer>, nil]
    # @!attribute [rw] retry_settings
    #   @return [RetrySettings, nil]
    class CallOptions
      attr_accessor :timeout, :metadata, :retry_codes, :retry_settings

      # @param timeout [Numeric, nil]
      #   The client-side timeout for API calls.
      # @param metadata [Hash, nil] the request header params.
      # @param retry_codes [Array<Integer>, nil] the error codes to retry.
      # @param backoff_settings [RetrySettings, Hash, nil] the error codes to
      #   retry.
      def initialize(timeout: nil,
                     metadata: nil,
                     retry_codes: nil,
                     retry_settings: nil)
        @timeout = timeout
        @metadata = metadata
        @retry_codes = retry_codes
        @retry_settings = RetrySettings.from(retry_settings) if retry_settings
      end

      # @private
      def merge(timeout: nil,
                metadata: nil,
                retry_codes: nil,
                retry_settings: nil)
        @timeout     ||= timeout
        @metadata    ||= metadata
        @retry_codes ||= retry_codes
        @retry_settings ||= RetrySettings.from(retry_settings) if retry_settings
      end

      # @private
      def set_default_values_for_internal_use!
        # Set defaults if missing
        @timeout        ||= 300 # 5 minutes
        @metadata       ||= {}
        @retry_codes    ||= [GRPC::Core::StatusCodes::UNAVAILABLE]
        @retry_settings ||= RetrySettings.new
        @retry_settings.set_default_values_for_internal_use!
      end
    end
  end
end
