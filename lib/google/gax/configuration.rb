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

require "google/gax/configuration/derived_configuration"
require "google/gax/configuration/deferred_value"
require "google/gax/configuration/schema"

module Google
  module Gax
    ##
    # Configuration mechanism for Google Gax libraries. A Configuration object
    # contains a list of predefined keys, some of which are values and others
    # of which are subconfigurations, i.e. categories. Field access is
    # generally validated to ensure that the field is defined, and when a
    # a value is set, it is validated for the correct type. Warnings are
    # printed when a validation fails.
    #
    # You generally access fields and subconfigs by calling accessor methods.
    # Methods meant for "administration" such as adding options, are named
    # with a trailing "!" or "?" so they don't pollute the method namespace.
    # It is also possible to access a field using the `[]` operator.
    #
    # Note that config objects inherit from `BasicObject`. This means it does
    # not define many methods you might expect to find in most Ruby objects.
    # For example, `to_s`, `is_a?`, `instance_variable_get`, and so forth.
    #
    # @example
    #   require "google/gax/configuration"
    #
    #   config = Google::Gax::Configuration.new do |c|
    #     c.add_field! :opt1, 10
    #     c.add_field! :opt2, :one, enum: [:one, :two, :three]
    #     c.add_field! :opt3, "hi", match: [String, Symbol]
    #     c.add_field! :opt4, "hi", match: /^[a-z]+$/, allow_nil: true
    #     c.add_config! :sub do |c2|
    #       c2.add_field! :opt5, false
    #     end
    #   end
    #
    #   config.opt1             #=> 10
    #   config.opt1 = 20        #=> 20
    #   config.opt1             #=> 20
    #   config.opt1 = "hi"      #=> "hi" (but prints a warning)
    #   config.opt1 = nil       #=> nil (but prints a warning)
    #
    #   config.opt2             #=> :one
    #   config.opt2 = :two      #=> :two
    #   config.opt2             #=> :two
    #   config.opt2 = :four     #=> :four (but prints a warning)
    #
    #   config.opt3             #=> "hi"
    #   config.opt3 = "hiho"    #=> "hiho"
    #   config.opt3             #=> "hiho"
    #   config.opt3 = "HI"      #=> "HI" (but prints a warning)
    #
    #   config.opt4             #=> "yo"
    #   config.opt4 = :yo       #=> :yo (Strings and Symbols allowed)
    #   config.opt4             #=> :yo
    #   config.opt4 = 3.14      #=> 3.14 (but prints a warning)
    #   config.opt4 = nil       #=> nil (no warning: nil allowed)
    #
    #   config.sub              #=> <Google::Gax::Configuration>
    #
    #   config.sub.opt5         #=> false
    #   config.sub.opt5 = true  #=> true  (true and false allowed)
    #   config.sub.opt5         #=> true
    #   config.sub.opt5 = nil   #=> nil (but prints a warning)
    #
    #   config.opt9 = "hi"      #=> "hi" (warning about unknown key)
    #   config.opt9             #=> "hi" (no warning: key now known)
    #   config.sub.opt9         #=> nil (warning about unknown key)
    #
    class Configuration < BasicObject
      ##
      # Determines if the given object is a config. Useful because Configuration
      # does not define the `is_a?` method.
      #
      # @return [Boolean]
      #
      def self.config? obj
        Configuration.send :===, obj
      end

      ##
      # Constructs a Configuration object. If a block is given, yields `self` to the
      # block, which makes it convenient to initialize the structure by making
      # calls to `add_field!` and `add_config!`.
      #
      # @param [boolean] show_warnings Whether to print warnings when a
      #     validation fails. Defaults to `true`.
      #
      def initialize show_warnings: true, &block
        @values = {}
        @schema = Schema.new show_warnings: show_warnings

        # Can't call yield because of BasicObject
        block&.call self
      end

      ##
      # Derive a Configuration object. The subsequent object can set local values,
      # but will not be able to change the structure.
      #
      def derive! &block
        DerivedConfiguration.new self, &block
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
      # @return [Configuration] self for chaining
      #
      def add_field! key, initial = nil, opts = {}, &block
        key = @schema.validate_new_key! key
        @values[key] = initial
        @schema.add_field! key, initial, opts, &block
        self
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
      # @param [String, Symbol] key The name of the subconfig
      # @param [Configuration] config A config object to attach here. If not provided,
      #     creates a new config.
      #
      # @return [Configuration] self for chaining
      #
      def add_config! key, config = nil, &block
        key = @schema.validate_new_key! key
        if config.nil?
          config = Configuration.new(&block)
        elsif block
          yield config
        end
        @values[key] = config
        @schema.add_config! key, config
        self
      end

      ##
      # Cause a key to be an alias of another key. The two keys will refer to
      # the same field.
      #
      def add_alias! key, to_key
        key = @schema.validate_new_key! key
        @values.delete key
        @schema.add_alias! key, to_key
        self
      end

      ##
      # Restore the original default value of the given key.
      # If the key is omitted, restore the original defaults for all keys,
      # and all keys of subconfigs, recursively.
      #
      # @param [Symbol, nil] key The key to reset. If omitted or `nil`,
      #     recursively reset all fields and subconfigs.
      #
      def reset! key = nil
        if key.nil?
          @values.each_key { |k| reset! k }
        else
          key = ::Kernel.String(key).to_sym
          if @schema.default? key
            @values[key] = @schema.default key
            @values[key].reset! if Configuration.config? @values[key]
          elsif @values.key? key
            @schema.warn! "Key #{key.inspect} has not been added, but has a value." \
                          " Removing the value."
            @values.delete key
          else
            @schema.warn! "Key #{key.inspect} does not exist. Nothing to reset."
          end
        end
        self
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
          @schema.delete!
          @values.clear
        else
          key = ::Kernel.String(key).to_sym
          @schema.delete! key
          @values.delete key
        end
        self
      end

      ##
      # Assign an option with the given name to the given value.
      #
      # @param [Symbol, String] key The option name
      # @param [Object] value The new option value
      #
      def []= key, value
        key = @schema.resolve_key! key
        @schema.validate_value! key, value
        @values[key] = value
      end

      ##
      # Get the option or subconfig with the given name.
      #
      # @param [Symbol, String] key The option or subconfig name
      # @return [Object] The option value or subconfig object
      #
      def [] key
        key = @schema.resolve_key! key
        @schema.warn! "Key #{key.inspect} does not exist. Returning nil." unless @schema.key? key
        value = @values[key]
        value = value.call if Configuration::DeferredValue === value
        value
      end

      ##
      # Check if the given key has been set in this object. Returns true if the
      # key has been added as a normal field, subconfig, or alias, or if it has
      # not been added explicitly but still has a value.
      #
      # @param [Symbol] key The key to check for.
      # @return [Boolean]
      #
      def value_set? key
        @values.key? @schema.resolve_key! key
      end

      ##
      # Check if the given key has been explicitly added as a field name.
      #
      # @param [Symbol] key The key to check for.
      # @return [Boolean]
      #
      def field? key
        @schema.field? key
      end

      ##
      # Check if the given key has been explicitly added as a subconfig name.
      #
      # @param [Symbol] key The key to check for.
      # @return [Boolean]
      #
      def subconfig? key
        @schema.subconfig? key
      end

      ##
      # Check if the given key has been explicitly added as an alias.
      # If so, return the target, otherwise return nil.
      #
      # @param [Symbol] key The key to check for.
      # @return [Symbol,nil] The alias target, or nil if not an alias.
      #
      def alias? key
        @schema.alias? key
      end

      ##
      # Return a list of explicitly added field names.
      #
      # @return [Array<Symbol>] a list of field names as symbols.
      #
      def fields!
        @schema.fields!
      end

      ##
      # Return a list of explicitly added subconfig names.
      #
      # @return [Array<Symbol>] a list of subconfig names as symbols.
      #
      def subconfigs!
        @schema.subconfigs!
      end

      ##
      # Return a list of alias names.
      #
      # @return [Array<Symbol>] a list of alias names as symbols.
      #
      def aliases!
        @schema.aliases!
      end

      ##
      # Returns a string representation of this configuration state, including
      # subconfigs. Only explicitly added fields and subconfigs are included.
      #
      # @return [String]
      #
      def to_s!
        elems = @schema.keys.map do |k|
          v = self[k]
          vstr = Configuration.config?(v) ? v.to_s! : v.inspect
          "#{k}=#{vstr}"
        end
        "<Google::Gax::Configuration: #{elems.join ' '}>"
      end

      ##
      # Returns a nested hash representation of this configuration state,
      # including subconfigs. Only explicitly added fields and subconfigs are
      # included.
      #
      # @return [Hash]
      #
      def to_h!
        h = {}
        @schema.keys.each do |k|
          v = self[k]
          h[k] = Configuration.config?(v) ? v.to_h! : v.inspect
        end
        h
      end

      ##
      # @private
      # Returns a string containing a human-readable representation of the configuration.
      #
      def inspect
        "##{to_s!}"
      end

      ##
      # @private
      # Dynamic methods accessed as keys.
      #
      def method_missing name, *args
        name_str = name.to_s
        super unless name_str =~ /^[a-zA-Z]\w*=?$/
        if name_str.chomp! "="
          self[name_str] = args.first
        else
          self[name]
        end
      end

      ##
      # @private
      # Dynamic methods accessed as keys.
      #
      def respond_to_missing? name, include_private
        return true if value_set? name.to_s.chomp("=")
        super
      end

      ##
      # @private
      # Implement standard nil check
      #
      # @return [false]
      #
      def nil?
        false
      end

      ##
      # @private
      # Check if the configuration has been derived.
      #
      # @return [Boolean]
      #
      def derived?
        false
      end
    end
  end
end
