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
# 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "test_helper"

require "google/gax/config"

class ConfigErrorsTest < Minitest::Test
  def test_invalid_name
    error = assert_raises NameError do
      config_klass = Class.new do
        extend Google::Gax::Config

        config_attr "some method", nil, String
      end
    end
    assert_equal "invalid config name some method", error.message
  end

  def test_parent_config
    error = assert_raises NameError do
      config_klass = Class.new do
        extend Google::Gax::Config

        config_attr "parent_config", nil, String
      end
    end
    assert_equal "invalid config name parent_config", error.message
  end

  def test_existing_method
    error = assert_raises NameError do
      config_klass = Class.new do
        extend Google::Gax::Config

        config_attr "methods", nil, String
      end
    end
    assert_equal "method methods already exists", error.message
  end

  def test_missing_validation
    error = assert_raises ArgumentError do
      config_klass = Class.new do
        extend Google::Gax::Config

        config_attr "missing_validation", nil
      end
    end
    assert_equal "validation must be provided", error.message
  end
end
