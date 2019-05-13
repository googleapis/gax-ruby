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

require "google/gax/configuration/deferred_value"
require "google/gax/configuration/schema"

module Google
  module Gax
    class Configuration < BasicObject
      ##
      # A Derived Configuration error. This is raised when a structural change
      # is attempted on a derived configuration
      #
      class DerivedConfigurationError < ::StandardError
      end

      ##
      # A Derived Configuration object. It can set local values,
      # but cannot change the configuration structure.
      #
      class DerivedConfiguration < Configuration
        ##
        # Constructs a DerivedConfiguration object. If a block is given, yields `self` to the
        # block, which makes it convenient to change the local values in the derived object.
        #
        # @param [Configuration] parent_config The parent configuration.
        #
        def initialize parent_config, &block
          @values = {}
          @parent_config = parent_config
          @schema = parent_config.instance_eval { @schema }

          # Can't call yield because of BasicObject
          block&.call self
        end

        ##
        def add_field! _key, _initial = nil, _opts = {}
          ::Kernel.raise DerivedConfigurationError
        end

        ##
        def add_config! _key, _config = nil
          ::Kernel.raise DerivedConfigurationError
        end

        ##
        def add_alias! _key, _to_key
          ::Kernel.raise DerivedConfigurationError
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
            @values.clear
          else
            key = ::Kernel.String(key).to_sym
            @values.delete key
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
        def delete! _key = nil
          ::Kernel.raise DerivedConfigurationError
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
          value ||= @parent_config[key]
          if Configuration.config? value
            unless value.derived?
              value = DerivedConfiguration.new value
              @values[key] = value
            end
          end
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
          local_value_set = @values.key? @schema.resolve_key! key
          parent_value_set = @parent_config.value_set? key
          local_value_set || parent_value_set
        end

        ##
        # @private
        # Check if the configuration has been derived.
        #
        # @return [Boolean]
        #
        def derived?
          true
        end
      end
    end
  end
end
