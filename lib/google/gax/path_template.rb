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

require 'rly'

module Google
  # Gax defines Google API extensions
  module Gax
    # Lexer for the path_template language
    class PathLex < Rly::Lex
      token :FORWARD_SLASH, %r{/}
      token :LEFT_BRACE, /\{/
      token :RIGHT_BRACE, /\}/
      token :EQUALS, /=/
      token :WILDCARD, /\*/
      token :PATH_WILDCARD, /\*\*/
      token :LITERAL, %r{[^*=\}\{\/]+}

      # TODO: raise exception
      on_error do |p|
        puts 'lexer error'
        puts p
        nil
      end
    end

    # Parser for the path_template language
    class PathParse < Rly::Yacc
      rule 'template : FORWARD_SLASH bound_segments
                     | bound_segments' do |*p|
        # do something
      end

      rule 'bound_segments : bound_segment FORWARD_SLASH bound_segments
                           | bound_segment' do |*p|
      end

      rule 'unbound_segments : unbound_terminal FORWARD_SLASH unbound_segments
                             | unbound_terminal' do |*p|
      end

      rule 'bound_segment : bound_terminal
                          | variable' do |*p|
      end

      rule 'unbound_terminal : WILDCARD
                             | PATH_WILDCARD
                             | LITERAL' do |*p|
      end

      rule 'bound_terminal : unbound_terminal' do |*p|
      end

      rule 'variable : LEFT_BRACE LITERAL EQUALS unbound_segments RIGHT_BRACE
                     | LEFT_BRACE LITERAL RIGHT_BRACE' do |*p|
      end
    end

    # PathTemplate parses and format resource names
    class PathTemplate
      attr_reader :size

      def instantiate(_bindings)
        ''
      end

      def initialize(data)
        parser = PathParse.new(PathLex.new)
        @segments = parser.parse(data)
        #
        # TODO: figure out how to get the number of segments
        # from the parser
        # @size = parser.segment_count
        @size = 6
      end

      def match(_path)
        true
      end
    end

    # Private methods
    private

    def format(_segments)
      ''
    end
  end
end
