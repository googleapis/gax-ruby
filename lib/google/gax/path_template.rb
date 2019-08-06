# Copyright 2016, Google LLC
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
      token :LITERAL, %r{[^*=\}\{\/ ]+}

      on_error do |t|
        raise t ? "Syntax error at '#{t.value}'" : 'Syntax error at EOF'
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
        raise 'path template has no segments' if segments.nil?
        segments.each do |s|
          next unless s.kind == TERMINAL && s.literal == '**'
          if has_path_wildcard
            raise 'path template cannot contain more than one path wildcard'
          end
          has_path_wildcard = true
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
        segs.value.concat(more_segs.value) unless more_segs.nil?
      end

      rule 'unbound_segments : unbound_terminal FORWARD_SLASH unbound_segments
                             | unbound_terminal' do |segs, a_term, _, more_segs|
        segs.value = a_term.value
        segs.value.concat(more_segs.value) unless more_segs.nil?
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
          variable.value.concat(args[3].value)
        else
          variable.value.push(Segment.new(TERMINAL, '*'))
          @segment_count += 1
        end
        variable.value.push(Segment.new(END_BINDING, ''))
      end
    end

    # PathTemplate parses and format resource names
    class PathTemplate
      attr_reader :segments, :size

      def initialize(data)
        parser = PathParse.new(PathLex.new)
        @segments = parser.parse(data)
        @size = parser.segment_count
      end

      # Formats segments as a string.
      #
      # @param [Array<Segments>]
      #   The segments to be formatted
      # @return [String] the formatted output
      def self.format_segments(*segments)
        template = ''
        slash = true
        segments.each do |segment|
          if segment.kind == TERMINAL
            template += '/' if slash
            template += segment.literal.to_s
            next
          end
          slash = true
          if segment.kind == BINDING
            template += "/{#{segment.literal}="
            slash = false
          else
            template += "#{segment.literal}}"
          end
        end
        template[1, template.length] # exclude the initial slash
      end

      # Renders a path template using the provided bindings.
      # @param binding [Hash]
      #   A mapping of var names to binding strings.
      # @return [String] A rendered representation of this path template.
      # @raise [ArgumentError] If a key isn't provided or if a sub-template
      #   can't be parsed.
      def render(**bindings)
        out = []
        binding = false
        @segments.each do |segment|
          if segment.kind == BINDING
            literal_sym = segment.literal.to_sym
            unless bindings.key?(literal_sym)
              msg = "Value for key #{segment.literal} is not provided"
              raise ArgumentError.new(msg)
            end
            out.concat(PathTemplate.new(bindings[literal_sym]).segments)
            binding = true
          elsif segment.kind == END_BINDING
            binding = false
          else
            next if binding
            out << segment
          end
        end
        path = self.class.format_segments(*out)
        match(path)
        path
      end

      # Matches a fully qualified path template string.
      # @param path [String]
      #   A fully qualified path template string.
      # @return [Hash] Var names to matched binding values.
      # @raise [ArgumentError] If path can't be matched to the template.
      def match(path)
        that = path.split('/')
        current_var = nil
        bindings = {}
        segment_count = @size
        i = 0
        @segments.each do |segment|
          break if i >= that.size
          if segment.kind == TERMINAL
            if segment.literal == '*'
              bindings[current_var] = that[i]
              i += 1
            elsif segment.literal == '**'
              size = that.size - segment_count + 1
              segment_count += size - 1
              bindings[current_var] = that[i, size].join('/')
              i += size
            elsif segment.literal != that[i]
              throw ArgumentError.new(
                "mismatched literal: '#{segment.literal}' != '#{that[i]}'"
              )
            else
              i += 1
            end
          elsif segment.kind == BINDING
            current_var = segment.literal
          end
        end
        if i != that.size || i != segment_count
          throw ArgumentError.new(
            "match error: could not instantiate a path template from #{path}"
          )
        end
        bindings
      end

      def to_s
        self.class.format_segments(*@segments)
      end
    end

    Segment = Struct.new(:kind, :literal)

    # Private constants/methods/classes
    BINDING = 1
    END_BINDING = 2
    TERMINAL = 3

    private_constant :BINDING, :END_BINDING, :TERMINAL
  end
end
