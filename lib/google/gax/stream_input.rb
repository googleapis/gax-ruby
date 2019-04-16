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
    ##
    # Manages requests for an input stream and holds the stream open until {#close} is called.
    #
    class StreamInput
      ##
      # Create a new input stream object to manage streaming requests and hold the stream open until {#close} is called.
      #
      # @param requests [Object]
      #
      def initialize *requests
        @queue = Queue.new

        # Push initial requests into the queue
        requests.each { |request| @queue.push request }
      end

      ##
      # Adds a request object to the stream.
      #
      # @param request [Object]
      #
      # @return [StreamInput] Returns self.
      #
      def push request
        @queue.push request

        self
      end
      alias << push
      alias append push

      ##
      # Closes the stream.
      #
      # @return [StreamInput] Returns self.
      #
      def close
        @queue.push self

        self
      end

      ##
      # @private
      # Iterates the requests given to the stream.
      #
      # @yield [request] The block for accessing each request.
      # @yieldparam [Object] request The request object.
      #
      # @return [Enumerator] An Enumerator is returned if no block is given.
      #
      def to_enum
        return enum_for :to_enum unless block_given?
        loop do
          request = @queue.pop
          break if request.equal? self
          yield request
        end
      end
    end
  end
end
