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
    class Operation
      ##
      # The policy for retrying operation reloads using an incremental backoff. A new object instance should be used for
      # every Operation invocation.
      #
      class RetryPolicy
        ##
        # Create new Operation RetryPolicy.
        #
        # @param initial_delay [Numeric] client-side timeout
        # @param multiplier [Numeric] client-side timeout
        # @param max_delay [Numeric] client-side timeout
        # @param timeout [Numeric] client-side timeout
        #
        def initialize initial_delay: nil, multiplier: nil, max_delay: nil, timeout: nil
          @initial_delay = initial_delay
          @multiplier    = multiplier
          @max_delay     = max_delay
          @timeout       = timeout
        end

        def initial_delay
          @initial_delay || 10
        end

        def multiplier
          @multiplier || 1.3
        end

        def max_delay
          @max_delay || 300 # Five minutes
        end

        def timeout
          @timeout || 3600 # One hour
        end

        def call
          return unless retry?

          delay!
          increment_delay!

          true
        end

        private

        def deadline
          # memoize the deadline
          @deadline ||= Time.now + timeout
        end

        def retry?
          deadline > Time.now
        end

        ##
        # The current delay value.
        def delay
          @delay || initial_delay
        end

        def delay!
          # Call Kernel.sleep so we can stub it.
          Kernel.sleep delay
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
