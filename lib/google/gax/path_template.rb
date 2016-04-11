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
      token :PATH_WILDCARD, /\*\*/ # has to occur before WILDCARD
      token :WILDCARD, /\*/
      token :LITERAL, %r{[^*=\}\{\/]+}

      on_error do |t|
        if t
          fail "Syntax error at '#{t.value}'"
        else
          fail 'Syntax error at EOF'
        end
      end
    end

    # Parser for the path_template language
    class PathParse < Rly::Yacc
      attr_reader :segment_count, :binding_var_count

      def initialize(*args)
        super
        @segment_count = 0
        @binding_var_count = 0
      end

      def parse(*args)
        segments = super
        has_path_wildcard = false
        for s in segments
          next unless s.kind == TERMINAL && s.literal == '**'
          if has_path_wildcard
            fail 'path template cannot contain more than one path wildcard'
          else
            has_path_wildcard = true
          end
        end
        segments
      end

      rule 'template : FORWARD_SLASH bound_segments
                     | bound_segments' do |template, *segments|
        template.value = segments[-1].value
      end

      rule 'bound_segments : bound_segment FORWARD_SLASH bound_segments
                           | bound_segment' do |segs, a_seg, _, more_segs|
        segs.value = a_seg.value
        segs.value.push(*more_segs.value) unless more_segs.nil?
      end

      rule 'unbound_segments : unbound_terminal FORWARD_SLASH unbound_segments
                             | unbound_terminal' do |segs, a_term, _, more_segs|
        segs.value = a_term.value
        segs.value.push(*more_segs.value) unless more_segs.nil?
      end

      rule 'bound_segment : bound_terminal
                          | variable' do |segment, term_or_var|
        segment.value = term_or_var.value
      end

      rule 'unbound_terminal : WILDCARD
                             | PATH_WILDCARD
                             | LITERAL' do |term, literal|
        term.value = [Segment.new(TERMINAL, literal.value)]
        @segment_count += 1
      end

      rule 'bound_terminal : unbound_terminal' do |bound, unbound|
        p "what is unbound? #{unbound}"
        if ['*', '**'].include?(unbound.value[0].literal)
          bound.value = [
            Segment.new(BINDING, format('$%d', @binding_var_count)),
            unbound.value[0],
            Segment.new(END_BINDING, '')
          ]
          @binding_var_count += 1
        else
          bound.value = unbound.value
        end
      end

      rule 'variable : LEFT_BRACE LITERAL EQUALS unbound_segments RIGHT_BRACE
                     | LEFT_BRACE LITERAL RIGHT_BRACE' do |variable, *args|
        variable.value = [Segment.new(BINDING, args[1].value)]
        if args.size > 3
          variable.value.push(*args[3].value)
        else
          variable.value.push(Segment.new(TERMINAL, '*'))
          @segment_count += 1
        end
        variable.value.push(Segment.new(END_BINDING, ''))
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
        @size = parser.segment_count
      end

      def match(_path)
        true
      end
    end

    # Private constants/methods/classes
    BINDING = 1
    END_BINDING = 2
    TERMINAL = 3

    private_constant :BINDING, :END_BINDING, :TERMINAL

    private

    Segment = Struct.new(:kind, :literal)

    def format(_segments)
      ''
    end
  end
end
