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

module Google
  # Gax defines Google API extensions
  module Gax
    # PathTemplate parses and format resource names
    class PathTemplate
      attr_reader :segments, :size

      def initialize(data)
        parts = []

        # split on / and then reassemble any that were contained within {}
        # (i.e. a/b/**/*/{a=hello/world})
        var = nil
        data.split('/').reject(&:empty?).each do |p|
          if var.nil?
            if p.start_with?('{') && !p.end_with?('}')
              var = [p]
            else
              parts << p
            end
          else
            var << p
            if p.end_with? '}'
              parts << var.join('/')
              var = nil
            end
          end
        end

        # validate
        raise 'Multiple wildcards are not allowed' if parts.count('**') > 1
        raise 'Non-terminated tokens are not allowed' unless var.nil?
        parts = parts.map { |p| create_token(p) }

        # save values
        @segments = parts.freeze
        @size = @segments.map { |s| s.literal.count('/') + 1 }
                         .reduce(0, :+)
      end

      def create_token(token)
        return Segment.new(:anon, '*') if token == '*'
        return Segment.new(:wildcard, '**') if token == '**'
        token.match(/^[^{}=*]+$/) do
          return Segment.new(:literal, token)
        end
        token.match(/^{([^={}]+)=([^={}]+)}$/) do |m|
          return Segment.new(:variable, token, m.captures[0], m.captures[1])
        end
        token.match(/^{([^=*{}]+)}$/) do |m|
          return Segment.new(:variable, token, m.captures[0])
        end
        raise "Invalid token '#{token}'"
      end

      # Formats segments as a string.
      #
      # @param [Array<Segments>]
      #   The segments to be formatted
      # @return [String] the formatted output
      def self.format_segments(*segments)
        formatted_segments = []
        at = 0

        segments.each do |segment|
          formatted = if segment.literal == '*'
                        at += 1
                        "{$#{at - 1}=*}"
                      elsif segment.literal == '**'
                        at += 1
                        "{$#{at - 1}=**}"
                      elsif segment.kind == :variable && segment.value.nil?
                        "#{segment.literal[0, segment.literal.length - 1]}=*}"
                      else segment.literal
                      end
          formatted_segments << formatted
        end

        formatted_segments.join '/'
      end

      # Renders a path template using the provided bindings.
      # @param binding [Hash]
      #   A mapping of var names to binding strings.
      # @return [String] A rendered representation of this path template.
      # @raise [ArgumentError] If a key isn't provided or if a sub-template
      #   can't be parsed.
      def render(**bindings)
        path = []
        at = 0

        @segments.each do |segment|
          if segment.kind == :anon || segment.kind == :wildcard
            key = "$#{at}".to_sym
            verify_binding(bindings, key, segment)
            path << bindings[key]
            at += 1
          elsif segment.kind == :variable
            key = segment.name.to_sym
            verify_binding(bindings, key, segment)
            path << bindings[key]
          else
            path << segment.literal
          end
        end

        path.join '/'
      end

      def verify_binding(bindings, key, segment)
        return if bindings.key?(key)
        raise ArgumentError.new "Value for key #{key} "\
                                "is not provided for '#{segment.literal}' "\
                                "in #{bindings}"
      end

      # Matches a fully qualified path template string.
      # @param path [String]
      #   A fully qualified path template string.
      # @return [Hash] Var names to matched binding values.
      # @raise [ArgumentError] If path can't be matched to the template.
      def match(path)
        that = path.split '/'
        at = 0
        bindings = {}
        segment_count = @size

        @segments.each do |segment|
          current_var = "$#{bindings.size}"
          current_sym = segment.literal

          # check for named variables (i.e. {foo=*}, {foo})
          if segment.kind == :variable
            current_var = segment.name
            current_sym = segment.value || '*'
          end

          # matched based on the literal in the template
          if current_sym == '**'
            size = that.size - segment_count + 1
            segment_count += size - 1
            bindings[current_var] = that[at, size].join('/')
            at += size
          elsif current_sym == '*'
            bindings[current_var] = that[at]
            at += 1
          elsif current_sym == that[at]
            at += 1
          else
            throw ArgumentError.new(
              "mismatched literal: '#{segment.literal}' != '#{that[at]}'"
            )
          end
        end

        # sanity check the sizes
        if at != that.size || at != segment_count
          throw ArgumentError.new(
            "match error: could not instantiate a path template from #{path}"
          )
        end

        # matched values
        bindings
      end

      def to_s
        self.class.format_segments(*@segments)
      end

      Segment = Struct.new(:kind, :literal, :name, :value)

      private :create_token, :verify_binding
    end
  end
end
