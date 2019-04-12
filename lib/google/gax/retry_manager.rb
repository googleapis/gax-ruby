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
    class RetryManager
      def initialize(call_options)
        @call_options = call_options
        @call_options.set_default_values_for_internal_use!

        # pull out the retry incremental backoff settings
        @delay = @call_options.retry_settings.initial_delay
        @delay_multi = @call_options.retry_settings.delay_multiplier
        @max_delay = @call_options.retry_settings.max_delay
      end

      def deadline
        # CallOptions#timeout is the max total timeout.
        @deadline ||= Time.now + @call_options.timeout
      end

      def expired?
        Time.now > deadline
      end

      def retry?(error)
        return false if expired?

        error.respond_to?(:code) &&
          @call_options.retry_codes.include?(error.code)
      end

      def delay!
        # sleep(rand(@delay)) # Why was rand called before?

        # Call Kernel.sleep so we can stub it.
        Kernel.sleep(@delay)

        # Increment delay
        @delay = [@delay * @delay_multi, @max_delay].min
      end
    end
  end
end
