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
    class Configuration < BasicObject
      ##
      # @private
      #
      class Schema
        ##
        # Constructs a Configuration object. If a block is given, yields `self` to the
        # block, which makes it convenient to initialize the structure by making
        # calls to `add_field!` and `add_config!`.
        #
        # @param [boolean] show_warnings Whether to print warnings when a
        #     validation fails. Defaults to `true`.
        #
        def initialize show_warnings: true
          @show_warnings = show_warnings
          @defaults = {}
          @validators = {}
        end

        ##
        # Add a value field to this configuration.
        #
        # You must provide a key, which becomes the field name in this config.
        # Field names may comprise only letters, numerals, and underscores, and
        # must begin with a letter. This will create accessor methods for the
        # new configuration key.
        #
        # You may pass an initial value (which defaults to nil if not provided).
        #
        # You may also specify how values are validated. Validation is defined
        # as follows:
        #
        # *   If you provide a block or a `:validator` option, it is used as the
        #     validator. A proposed value is passed to the proc, which should
        #     return `true` or `false` to indicate whether the value is valid.
        # *   If you provide a `:match` option, it is compared to the proposed
        #     value using the `===` operator. You may, for example, provide a
        #     class, a regular expression, or a range. If you pass an array,
        #     the value is accepted if _any_ of the elements match.
        # *   If you provide an `:enum` option, it should be an `Enumerable`.
        #     A proposed value is valid if it is included.
        # *   Otherwise if you do not provide any of the above options, then a
        #     default validation strategy is inferred from the initial value:
        #     *   If the initial is `true` or `false`, then either boolean value
        #         is considered valid. This is the same as `enum: [true, false]`.
        #     *   If the initial is `nil`, then any object is considered valid.
        #     *   Otherwise, any object of the same class as the initial value is
        #         considered valid. This is effectively the same as
        #         `match: initial.class`.
        # *   You may also provide the `:allow_nil` option, which, if set to
        #     true, alters any of the above validators to allow `nil` values.
        #
        # In many cases, you may find that the default validation behavior
        # (interpreted from the initial value) is sufficient. If you want to
        # accept any value, use `match: Object`.
        #
        # @param [String, Symbol] key The name of the option
        # @param [Object] initial Initial value (defaults to nil)
        # @param [Hash] opts Validation options
        #
        def add_field! key, initial, opts, &block
          key = validate_new_key! key
          opts[:validator] = block if block
          validator = resolve_validator! initial, opts
          validate_value! key, initial, validator
          @defaults[key] = initial
          @validators[key] = validator
        end

        ##
        # Add a subconfiguration field to this configuration.
        #
        # You must provide a key, which becomes the method name that you use to
        # navigate to the subconfig. Names may comprise only letters, numerals,
        # and underscores, and must begin with a letter.
        #
        # If you provide a block, the subconfig object is passed to the block,
        # so you can easily add fields to the subconfig.
        #
        # You may also pass in a config object that already exists. This will
        # "attach" that configuration in this location.
        #
        # @param [Symbol] key The name of the subconfig
        # @param [Configuration] config A config object to attach here. If not provided,
        #     creates a new config.
        #
        def add_config! key, config
          key = validate_new_key! key
          @defaults[key] = config
          @validators[key] = SUBCONFIG
        end

        ##
        # Cause a key to be an alias of another key. The two keys will refer to
        # the same field.
        #
        def add_alias! key, to_key
          key = validate_new_key! key
          to_key = String(to_key).to_sym
          @defaults.delete key
          @validators[key] = to_key
        end

        ##
        # Check if the given key has a default value.
        #
        # @param [Symbol] key The key to check for.
        # @return [Boolean]
        #
        def default? key
          @defaults.key? String(key).to_sym
        end

        ##
        # Return the default value for the given key.
        #
        # @param [Symbol] key The key to check for.
        # @return [Boolean]
        #
        def default key
          @defaults[String(key).to_sym]
        end

        ##
        # Remove the given key from the configuration, deleting any validation
        # and value. If the key is omitted, delete all keys. If the key is an
        # alias, deletes the alias but leaves the original.
        #
        # @param [Symbol, nil] key The key to delete. If omitted or `nil`,
        #     delete all fields and subconfigs.
        #
        def delete! key = nil
          if key.nil?
            @defaults.clear
            @validators.clear
          else
            @defaults.delete key
            @validators.delete key
          end
          self
        end

        ##
        # Check if the given key has been explicitly added as a field name.
        #
        # @param [Symbol] key The key to check for.
        # @return [Boolean]
        #
        def field? key
          @validators[String(key).to_sym].is_a? ::Proc
        end

        ##
        # Check if the given key has been explicitly added as a subconfig name.
        #
        # @param [Symbol] key The key to check for.
        # @return [Boolean]
        #
        def subconfig? key
          @validators[String(key).to_sym] == SUBCONFIG
        end

        ##
        # Check if the given key has been explicitly added as an alias.
        # If so, return the target, otherwise return nil.
        #
        # @param [Symbol] key The key to check for.
        # @return [Symbol,nil] The alias target, or nil if not an alias.
        #
        def alias? key
          target = @validators[String(key).to_sym]
          target.is_a?(::Symbol) ? target : nil
        end

        ##
        # Return a list of explicitly added field names.
        #
        # @return [Array<Symbol>] a list of field names as symbols.
        #
        def fields!
          @validators.keys.find_all { |key| @validators[key].is_a? ::Proc }
        end

        ##
        # Return a list of explicitly added subconfig names.
        #
        # @return [Array<Symbol>] a list of subconfig names as symbols.
        #
        def subconfigs!
          @validators.keys.find_all { |key| @validators[key] == SUBCONFIG }
        end

        ##
        # Return a list of alias names.
        #
        # @return [Array<Symbol>] a list of alias names as symbols.
        #
        def aliases!
          @validators.keys.find_all { |key| @validators[key].is_a? ::Symbol }
        end

        def key? key
          @validators.key? String(key).to_sym
        end

        def keys
          @validators.keys
        end

        ##
        # @private A validator that allows all values
        #
        OPEN_VALIDATOR = ::Proc.new { true }

        ##
        # @private a list of key names that are technically illegal because
        # they clash with method names.
        #
        ILLEGAL_KEYS = [:inspect, :initialize, :instance_eval, :instance_exec, :method_missing,
                        :singleton_method_added, :singleton_method_removed, :singleton_method_undefined].freeze

        ##
        # @private sentinel indicating a subconfig in the validators hash
        #
        SUBCONFIG = ::Object.new

        def resolve_key! key
          key = String(key).to_sym
          alias_target = @validators[key]
          alias_target.is_a?(::Symbol) ? alias_target : key
        end

        def validate_new_key! key
          key_str = String(key)
          key = key.to_sym
          if key_str !~ /^[a-zA-Z]\w*$/ || ILLEGAL_KEYS.include?(key)
            warn! "Illegal key name: #{key_str.inspect}. Method dispatch will" \
                  " not work for this key."
          end
          warn! "Key #{key.inspect} already exists. It will be replaced." if @validators.key? key
          key
        end

        def resolve_validator! initial, opts
          allow_nil = initial.nil? || opts[:allow_nil]
          if opts.key? :validator
            build_proc_validator! opts[:validator], allow_nil
          elsif opts.key? :match
            build_match_validator! opts[:match], allow_nil
          elsif opts.key? :enum
            build_enum_validator! opts[:enum], allow_nil
          elsif [true, false].include? initial
            build_enum_validator! [true, false], allow_nil
          elsif initial.nil?
            OPEN_VALIDATOR
          else
            klass = Configuration.config?(initial) ? Configuration : initial.class
            build_match_validator! klass, allow_nil
          end
        end

        def build_match_validator! matches, allow_nil
          matches = ::Kernel.Array(matches)
          matches += [nil] if allow_nil && !matches.include?(nil)
          ->(val) { matches.any? { |m| m.send :===, val } }
        end

        def build_enum_validator! allowed, allow_nil
          allowed = ::Kernel.Array(allowed)
          allowed += [nil] if allow_nil && !allowed.include?(nil)
          ->(val) { allowed.include? val }
        end

        def build_proc_validator! proc, allow_nil
          ->(val) { proc.call(val) || (allow_nil && val.nil?) }
        end

        def validate_value! key, value, validator = nil
          validator ||= @validators[key]
          value = value.call if Configuration::DeferredValue === value
          case validator
          when ::Proc
            unless validator.call value
              warn! "Invalid value #{value.inspect} for key #{key.inspect}." \
                    " Setting anyway."
            end
          when Configuration
            if value != validator
              warn! "Key #{key.inspect} refers to a subconfig and shouldn't" \
                    " be changed. Setting anyway."
            end
          else
            warn! "Key #{key.inspect} has not been added. Setting anyway."
          end
        end

        def warn! msg
          return unless @show_warnings
          location = ::Kernel.caller_locations.find do |s|
            !s.to_s.include? "/google/gax/configuration.rb:"
          end
          ::Kernel.warn "#{msg} at #{location}"
        end
      end
    end
  end
end
