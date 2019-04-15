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
    class ApiCall
      ##
      # The policy for retrying failed API calls using an incremental backoff.
      # A new object instance should be used for every ApiCall invocation.
      #
      # Only errors orginating from GRPC will be retried.
      #
      class RetryPolicy
        def initialize(retry_codes: nil, initial_delay: nil, multiplier: nil,
                       max_delay: nil)
          @retry_codes   = retry_codes
          @initial_delay = initial_delay
          @multiplier    = multiplier
          @max_delay     = max_delay
        end

        def retry_codes
          @retry_codes || []
        end

        def initial_delay
          @initial_delay || 1
        end

        def multiplier
          @multiplier || 1.3
        end

        def max_delay
          @max_delay || 15
        end

        ##
        # The current delay value.
        def delay
          @delay || initial_delay
        end

        def call(error)
          return false unless retry?(error)

          delay!
          increment_delay!

          true
        end

        ##
        # @private Though not part of the public API, if the retry policy object
        # responds to merge ApiCall will pass a Hash of confiuration settings.
        #
        # @param settings [Hash] configuration settings to apply to the policy.
        #
        def merge(settings)
          return unless settings.is_a? Hash

          @retry_codes   ||= settings[:retry_codes]
          @initial_delay ||= settings[:initial_delay]
          @multiplier    ||= settings[:multiplier]
          @max_delay     ||= settings[:max_delay]

          self
        end

        private

        def retry?(error)
          error.is_a?(GRPC::BadStatus) && retry_codes.include?(error.code)
        end

        def delay!
          # Call Kernel.sleep so we can stub it.
          Kernel.sleep(delay)
        end

        ##
        # Calculate and set the next delay value.
        def increment_delay!
          @delay = [delay * multiplier, max_delay].min
        end
      end
    end
  end
end
