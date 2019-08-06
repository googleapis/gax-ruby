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

require 'google/gax/path_template'
require 'rly'

describe Google::Gax::PathTemplate do
  PathTemplate = Google::Gax::PathTemplate

  def symbolize_keys(a_hash)
    Hash[a_hash.map { |(k, v)| [k.to_sym, v] }]
  end

  def runtime_error
    raise_error RuntimeError
  end

  describe 'method `initialize`' do
    it 'computes the length correctly' do
      a_template = PathTemplate.new('a/b/**/*/{a=hello/world}')
      expect(a_template.size).to eq(6)
    end

    it 'should fail on invalid tokens' do
      expect { PathTemplate.new('hello/wor* ld') }.to runtime_error
    end

    it 'should fail when multiple path wildcards' do
      expect { PathTemplate.new('buckets/*/**/**/objects/*') }.to runtime_error
    end

    it 'should fail on inner binding' do
      expect { PathTemplate.new('buckets/{hello={world}}') }.to runtime_error
    end

    it 'should fail unexpected eof' do
      expect { PathTemplate.new('a/{hello=world') }.to runtime_error
    end
  end

  describe 'method `match`' do
    it 'should fail on impossible match' do
      template = PathTemplate.new('hello/world')
      expect { template.match('hello') }.to raise_error(ArgumentError)
      expect { template.match('hello/world/fail') }.to raise_error(
        ArgumentError
      )
    end

    it 'should fail on mismatched literal' do
      template = PathTemplate.new('hello/world')
      expect { template.match('hello/world2') }.to raise_error(ArgumentError)
    end

    it 'should match atomic resource name' do
      template = PathTemplate.new('buckets/*/*/objects/*')
      want = { '$0' => 'f', '$1' => 'o', '$2' => 'bar' }
      expect(template.match('buckets/f/o/objects/bar')).to eq(want)

      template = PathTemplate.new('/buckets/{hello}')
      want = { 'hello' => 'world' }
      expect(template.match('buckets/world')).to eq(want)

      template = PathTemplate.new('/buckets/{hello=*}')
      expect(template.match('buckets/world')).to eq(want)
    end

    it 'should match escaped chars' do
      template = PathTemplate.new('buckets/*/objects')
      want = { '$0' => 'hello%2F%2Bworld' }
      expect(template.match('buckets/hello%2F%2Bworld/objects')).to eq(want)
    end

    it 'should match template with unbounded wildcard' do
      template = PathTemplate.new('buckets/*/objects/**')
      want = { '$0' => 'foo', '$1' => 'bar/baz' }
      expect(template.match('buckets/foo/objects/bar/baz')).to eq(want)
    end

    it 'should match with unbound in the middle' do
      template = PathTemplate.new('bar/**/foo/*')
      want = { '$0' => 'foo/foo', '$1' => 'bar' }
      expect(template.match('bar/foo/foo/foo/bar')).to eq(want)
    end
  end

  describe 'method `render`' do
    it 'should render atomic resource' do
      template = PathTemplate.new('buckets/*/*/*/objects/*')
      params = symbolize_keys(
        '$0' => 'f',
        '$1' => 'o',
        '$2' => 'o',
        '$3' => 'google.com:a-b'
      )

      want = 'buckets/f/o/o/objects/google.com:a-b'
      expect(template.render(params)).to eq(want)
    end

    it 'should fail when there are too few variables' do
      template = PathTemplate.new('buckets/*/*/*/objects/*')
      params = symbolize_keys(
        '$0' => 'f',
        '$1' => 'o',
        '$2' => 'o'
      )
      testf = proc { template.render(**params) }
      expect(testf).to raise_error ArgumentError
    end

    it 'should succeed with unbound in the middle' do
      template = PathTemplate.new('bar/**/foo/*')
      params = symbolize_keys('$0' => '1/2', '$1' => '3')
      want = 'bar/1/2/foo/3'
      expect(template.render(**params)).to eq(want)
    end
  end

  describe 'method `to_s`' do
    tests = {
      'bar/**/foo/*' => 'bar/{$0=**}/foo/{$1=*}',
      'buckets/*/objects/*' => 'buckets/{$0=*}/objects/{$1=*}',
      '/buckets/{hello}' => 'buckets/{hello=*}',
      '/buckets/{hello=what}/{world}' => 'buckets/{hello=what}/{world=*}',
      '/buckets/helloazAZ09-.~_what' => 'buckets/helloazAZ09-.~_what'
    }
    tests.each do |t, want|
      it "should render method #{t} ok" do
        expect(PathTemplate.new(t).to_s).to eq(want)
      end
    end
  end
end
