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

require "google/gax/configuration"

describe Google::Gax::Configuration, :derive! do
  let(:new_config) { Google::Gax::Configuration.new }
  let(:simple_config) do
    Google::Gax::Configuration.new do |config|
      config.add_field! :opt_bool, true
      config.add_field! :opt_bool_nil, true, allow_nil: true
      config.add_field! :opt_enum, :one, enum: [:one, :two, :three]
      config.add_field! :opt_regex, "hi", match: /^[a-z]+$/
      config.add_field! :opt_class, "hi", match: [String, Symbol]
      config.add_field! :opt_default
    end
  end
  let(:nested_config) do
    Google::Gax::Configuration.new do |c1|
      c1.add_field! :opt1_int, 1
      c1.add_config! :sub1 do |c2|
        c2.add_field! :opt2_sym, :hi
        c2.add_config! :sub2 do |c3|
          c3.add_field! :opt3_bool, true
          c3.add_field! :opt3_bool_nil, true, allow_nil: true
          c3.add_field! :opt3_enum, :one, enum: [:one, :two, :three]
          c3.add_field! :opt3_regex, "hi", match: /^[a-z]+$/
          c3.add_field! :opt3_class, "hi", match: [String, Symbol]
          c3.add_field! :opt3_default
        end
      end
    end
  end

  it "allows value changes" do
    derived_config = simple_config.derive!

    refute simple_config.derived?
    assert derived_config.derived?

    assert_equal "hi", simple_config.opt_class
    assert_equal "hi", derived_config.opt_class

    simple_config.opt_class = "Hello SimpleConfig!"

    assert_equal "Hello SimpleConfig!", simple_config.opt_class
    assert_equal "Hello SimpleConfig!", derived_config.opt_class

    derived_config.opt_class = "Hello DerivedConfig!"

    assert_equal "Hello SimpleConfig!", simple_config.opt_class
    assert_equal "Hello DerivedConfig!", derived_config.opt_class

    derived_config.reset! :opt_class

    assert_equal "Hello SimpleConfig!", simple_config.opt_class
    assert_equal "Hello SimpleConfig!", derived_config.opt_class

    simple_config.reset! :opt_class

    assert_equal "hi", simple_config.opt_class
    assert_equal "hi", derived_config.opt_class
  end

  it "allows value changes using a block" do
    derived_config = simple_config.derive! do |dc|
      dc.opt_class = "yo"
    end

    refute simple_config.derived?
    assert derived_config.derived?

    assert_equal "hi", simple_config.opt_class
    assert_equal "yo", derived_config.opt_class

    simple_config.opt_class = "Hello SimpleConfig!"

    assert_equal "Hello SimpleConfig!", simple_config.opt_class
    assert_equal "yo", derived_config.opt_class

    derived_config.opt_class = "Hello DerivedConfig!"

    assert_equal "Hello SimpleConfig!", simple_config.opt_class
    assert_equal "Hello DerivedConfig!", derived_config.opt_class

    derived_config.reset! :opt_class

    assert_equal "Hello SimpleConfig!", simple_config.opt_class
    assert_equal "Hello SimpleConfig!", derived_config.opt_class

    simple_config.reset! :opt_class

    assert_equal "hi", simple_config.opt_class
    assert_equal "hi", derived_config.opt_class
  end

  it "allows nested value changes" do
    derived_config = nested_config.derive!

    refute nested_config.derived?
    assert derived_config.derived?

    assert_equal "hi", nested_config.sub1.sub2.opt3_class
    assert_equal "hi", derived_config.sub1.sub2.opt3_class

    nested_config.sub1.sub2.opt3_class = "Hello ComplexConfig!"

    assert_equal "Hello ComplexConfig!", nested_config.sub1.sub2.opt3_class
    assert_equal "Hello ComplexConfig!", derived_config.sub1.sub2.opt3_class

    derived_config.sub1.sub2.opt3_class = "Hello DerivedConfig!"

    assert_equal "Hello ComplexConfig!", nested_config.sub1.sub2.opt3_class
    assert_equal "Hello DerivedConfig!", derived_config.sub1.sub2.opt3_class

    derived_config.sub1.sub2.reset! :opt3_class

    assert_equal "Hello ComplexConfig!", nested_config.sub1.sub2.opt3_class
    assert_equal "Hello ComplexConfig!", derived_config.sub1.sub2.opt3_class

    nested_config.sub1.sub2.reset! :opt3_class

    assert_equal "hi", nested_config.sub1.sub2.opt3_class
    assert_equal "hi", derived_config.sub1.sub2.opt3_class
  end

  it "allows nested value changes using a block" do
    derived_config = nested_config.derive! do |dc|
      dc.sub1.sub2.opt3_class = "yo"
    end

    refute nested_config.derived?
    assert derived_config.derived?

    assert_equal "hi", nested_config.sub1.sub2.opt3_class
    assert_equal "yo", derived_config.sub1.sub2.opt3_class

    nested_config.sub1.sub2.opt3_class = "Hello ComplexConfig!"

    assert_equal "Hello ComplexConfig!", nested_config.sub1.sub2.opt3_class
    assert_equal "yo", derived_config.sub1.sub2.opt3_class

    derived_config.sub1.sub2.opt3_class = "Hello DerivedConfig!"

    assert_equal "Hello ComplexConfig!", nested_config.sub1.sub2.opt3_class
    assert_equal "Hello DerivedConfig!", derived_config.sub1.sub2.opt3_class

    derived_config.sub1.sub2.reset! :opt3_class

    assert_equal "Hello ComplexConfig!", nested_config.sub1.sub2.opt3_class
    assert_equal "Hello ComplexConfig!", derived_config.sub1.sub2.opt3_class

    nested_config.sub1.sub2.reset! :opt3_class

    assert_equal "hi", nested_config.sub1.sub2.opt3_class
    assert_equal "hi", derived_config.sub1.sub2.opt3_class
  end

  it "does not allow structural changes" do
    derived_config = simple_config.derive!

    refute simple_config.derived?
    assert derived_config.derived?

    assert_raises Google::Gax::Configuration::DerivedError do
      derived_config.add_field! :new_field, true
    end

    assert_raises Google::Gax::Configuration::DerivedError do
      derived_config.add_config! :new_sub do |c|
        c.add_field! :new_bool, true
        c.add_field! :new_bool_nil, true, allow_nil: true
        c.add_field! :new_enum, :one, enum: [:one, :two, :three]
        c.add_field! :new_regex, "hi", match: /^[a-z]+$/
        c.add_field! :new_class, "hi", match: [String, Symbol]
        c.add_field! :new_default
      end
    end

    assert_raises Google::Gax::Configuration::DerivedError do
      derived_config.add_alias! :new_bool, :opt_bool
    end

    assert_raises Google::Gax::Configuration::DerivedError do
      derived_config.delete! :opt_bool
    end

    assert_raises Google::Gax::Configuration::DerivedError do
      derived_config.delete!
    end
  end
end
