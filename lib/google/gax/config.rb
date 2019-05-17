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
    module Config
      ##
      # Add configuration attribute methods to the configuratin class.
      #
      # @param [String, Symbol] key The name of the option
      # @param [Object, nil] initial Initial value (nil is allowed)
      # @param [Hash] opts Validation options
      #
      def config_attr name, default, *valid_values, &validator
        name = String(name).to_sym
        raise "cannot create field named parent_config" if name == :parent_config
        raise "method #{name} already exists" if method_defined? name

        raise "validation must be provided" if validator.nil? && valid_values.empty?
        validator ||= ->(value) { valid_values.any? { |v| v === value } }

        name_ivar = "@#{name}".to_sym

        if default.nil?
          # create getter
          define_method name do
            value = instance_variable_get name_ivar
            if value.nil?
              parent = instance_variable_get :@parent_config
              return parent.send name if parent&.respond_to? name
            end
            value
          end
          # create setter
          define_method "#{name}=" do |new_value|
            parent = instance_variable_get :@parent_config
            valid_value = validator.call new_value
            # Allow nil if parent config has the same method.
            valid_value = true if new_value.nil? && parent&.respond_to?(name)
            raise ArgumentError unless valid_value
            if new_value.nil?
              remove_instance_variable name_ivar if instance_variable_defined? name_ivar
            else
              instance_variable_set name_ivar, new_value
            end
          end
        else
          # create getter with default value
          define_method name do
            value = instance_variable_get name_ivar
            if value.nil?
              parent = instance_variable_get :@parent_config
              return parent.send name if parent&.respond_to? name
              return default
            end
            value
          end
          # create setter with default value
          define_method "#{name}=" do |new_value|
            valid_value = validator.call new_value
            # Always allow nil because we have a default value
            valid_value = true if new_value.nil?
            raise ArgumentError unless valid_value
            if new_value.nil?
              remove_instance_variable name_ivar if instance_variable_defined? name_ivar
            else
              instance_variable_set name_ivar, new_value
            end
          end
        end
      end
    end
  end
end
