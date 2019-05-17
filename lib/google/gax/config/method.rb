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
      # Config::Method is a configuration class that represents the configuration for an API RPC call.
      #
      # @example
      #   require "google/gax/config"
      #
      #   class ServiceConfig
      #     extend Google::Gax::Config
      #
      #     config_attr :host,     "localhost", String
      #     config_attr :port,     443,         Integer
      #     config_attr :timeout,  nil,         Numeric, nil
      #     config_attr :metadata, nil,         Hash, nil
      #
      #     attr_reader :rpc_method
      #
      #     def initialize parent_config = nil
      #       @parent_config = parent_config unless parent_config.nil?
      #       @rpc_method = Google::Gax::Config::Method.new
      #
      #       yield self if block_given?
      #     end
      #   end
      #
      #   config = ServiceConfig.new
      #
      #   config.timeout = 60
      #   config.rpc_method.timeout = 120
      #
      class Method
        extend Google::Gax::Config

        config_attr :timeout,      nil, Numeric, nil
        config_attr :metadata,     nil, Hash, nil
        config_attr :retry_policy, nil, Hash, Proc, nil

        ##
        # Create a new Config::Method object instance.
        #
        # @param parent_method [Google::Gax::Config::Method, nil] The config to look to values for.
        #
        def initialize parent_method = nil
          @parent_config = parent_method unless parent_method.nil?

          yield self if block_given?
        end
      end
    end
  end
end
