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

module Google
  module Gax
    #
    # @!attribute initial_delay
    #   @return [Numeric] the initial delay time, in seconds,
    #     between the completion of the first failed request and the
    #     initiation of the first retrying request.
    # @!attribute delay_multiplier
    #   @return [Numeric] the multiplier by which to increase the
    #     delay time between the completion of failed requests, and
    #     the initiation of the subsequent retrying request.
    # @!attribute max_delay
    #   @return [Numeric] the maximum delay time, in seconds,
    #     between requests. When this value is reached,
    #     +delay_multiplier+ will no longer be used to
    #     increase delay time.
    class RetrySettings
      attr_accessor :initial_delay, :delay_multiplier, :max_delay

      def initialize(initial_delay: nil, delay_multiplier: nil, max_delay: nil)
        @initial_delay = initial_delay
        @delay_multiplier = delay_multiplier
        @max_delay = max_delay
      end

      # @private
      def self.from(other)
        return new if other.nil?
        return new(other) if other.is_a? Hash
        return other if other.is_a? RetrySettings

        raise ArgumentError.new("#{other} is not a RetrySettings")
      end

      # @private
      def merge(other)
        unless other.is_a? RetrySettings
          raise ArgumentError.new("#{other} is not a RetrySettings")
        end

        @initial_delay    ||= other.initial_delay
        @delay_multiplier ||= other.delay_multiplier
        @max_delay        ||= other.max_delay
      end

      # @private
      def set_default_values_for_internal_use!
        # Set defaults if missing
        @initial_delay    ||= 1
        @delay_multiplier ||= 1.3
        @max_delay        ||= 15

        # Set defaults for bad values
        @initial_delay = 1      if @initial_delay < 0
        @delay_multiplier = 1.3 if @delay_multiplier < 0
        @max_delay = 15         if @max_delay < 0
      end
    end
  end
end
