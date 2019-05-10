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

require 'google/gax/bundling'
require 'google/gax'
require 'google/protobuf'

describe Google::Gax do
  Pool = Google::Protobuf::DescriptorPool.new
  Pool.build do
    add_message 'google.protobuf.Simple' do
      optional :field1, :string, 1
      optional :field2, :string, 2
    end
    add_message 'google.protobuf.Outer' do
      optional :inner, :message, 1, 'google.protobuf.Simple'
      optional :field1, :string, 2
    end
    add_message 'google.protobuf.Bundled' do
      repeated :field1, :string, 1
    end
  end

  Simple = Pool.lookup('google.protobuf.Simple').msgclass
  Outer = Pool.lookup('google.protobuf.Outer').msgclass
  Bundled = Pool.lookup('google.protobuf.Bundled').msgclass

  def simple_builder(value, other_value: nil)
    return Simple.new(field1: value) if other_value.nil?
    Simple.new(field1: value, field2: other_value)
  end

  def outer_builder(value)
    Outer.new(inner: simple_builder(value, other_value: value), field1: value)
  end

  def bundled_builder(value)
    Bundled.new(field1: value)
  end

  describe 'method `compute_bundle_id`' do
    context 'should work for' do
      it 'single field value' do
        actual =
          Google::Gax.compute_bundle_id(
            simple_builder('dummy_value'), ['field1']
          )
        expect(actual).to eq(['dummy_value'])
      end

      it 'composite value with nil' do
        actual =
          Google::Gax.compute_bundle_id(
            simple_builder('dummy_value'), %w[field1 field2]
          )
        expect(actual).to eq(['dummy_value', ''])
      end

      it 'composite value' do
        actual =
          Google::Gax.compute_bundle_id(
            simple_builder('dummy_value', other_value: 'other_value'),
            %w[field1 field2]
          )
        expect(actual).to eq(%w[dummy_value other_value])
      end

      it 'simple dotted value' do
        actual =
          Google::Gax.compute_bundle_id(
            outer_builder('dummy_value'),
            %w[inner.field1]
          )
        expect(actual).to eq(['dummy_value'])
      end

      it 'complex case' do
        actual =
          Google::Gax.compute_bundle_id(
            outer_builder('dummy_value'),
            %w[inner.field1 inner.field2 field1]
          )
        expect(actual).to eq(%w[dummy_value dummy_value dummy_value])
      end

      it 'should return false for a single missing field value' do
        expect(
          Google::Gax.compute_bundle_id(
            simple_builder('dummy_value'),
            ['field3']
          )
        ).to eq([nil])
      end

      it 'should return false for a composite value' do
        expect(
          Google::Gax.compute_bundle_id(
            simple_builder('dummy_value'),
            %w[field1 field3]
          )
        ).to eq(['dummy_value', nil])
      end

      it 'should return false for a simple dotted value' do
        expect(
          Google::Gax.compute_bundle_id(
            outer_builder('dotted this'),
            ['inner.field3']
          )
        ).to eq([nil])
      end
    end
  end

  # A dummy api call that simply returns the request.
  def return_request
    proc do |req|
      req
    end
  end

  def create_a_test_task(api_call: return_request)
    Google::Gax::Task.new(
      api_call,
      'an_id',
      'field1',
      bundled_builder([]),
      {}
    )
  end

  # A dummy api call that raises an exception
  def raise_exc
    proc do |_|
      raise Google::Gax::GaxError.new('Raised in a test')
    end
  end

  describe Google::Gax::Task do
    test_message = 'a simple msg'.freeze
    context 'increase in element count' do
      it 'no messages added' do
        test_task = create_a_test_task
        actual = test_task.element_count
        expect(actual).to eq(0)
      end

      it '1 message added' do
        test_task = create_a_test_task
        test_task.extend([test_message])
        actual = test_task.element_count
        expect(actual).to eq(1)
      end

      it '5 messages added' do
        test_task = create_a_test_task
        test_task.extend([test_message] * 5)
        actual = test_task.element_count
        expect(actual).to eq(5)
      end
    end

    context 'increase in request byte count' do
      it 'no messages added' do
        test_task = create_a_test_task
        actual = test_task.request_bytesize
        expect(actual).to eq(0)
      end

      it '1 message added' do
        test_task = create_a_test_task
        test_task.extend([test_message])
        actual = test_task.request_bytesize
        expect(actual).to eq(test_message.bytesize)
      end

      it '5 messages added' do
        test_task = create_a_test_task
        test_task.extend([test_message] * 5)
        actual = test_task.request_bytesize
        expect(actual).to eq(5 * test_message.bytesize)
      end
    end

    context 'sends bundle elements' do
      it 'no messages added' do
        test_task = create_a_test_task
        expect(test_task.element_count).to eq(0)
        test_task.run
        expect(test_task.element_count).to eq(0)
        expect(test_task.request_bytesize).to eq(0)
      end

      it '1 message added' do
        test_task = create_a_test_task
        event = test_task.extend([test_message])
        expect(test_task.element_count).to eq(1)
        test_task.run
        expect(test_task.element_count).to eq(0)
        expect(test_task.request_bytesize).to eq(0)
        expect(event).to_not be_nil
        expect(event.result).to eq(bundled_builder([test_message]))
      end

      it '5 messages added' do
        test_task = create_a_test_task
        event = test_task.extend([test_message] * 5)
        test_task.run
        expect(test_task.element_count).to eq(0)
        expect(test_task.request_bytesize).to eq(0)
        expect(event).to_not be_nil
        expect(event.result).to eq(bundled_builder([test_message] * 5))
      end
    end

    context 'api call execution fails' do
      it 'adds an error if execution fails' do
        test_task = create_a_test_task(api_call: raise_exc)
        event = test_task.extend([test_message])
        expect(test_task.element_count).to eq(1)
        test_task.run
        expect(test_task.element_count).to eq(0)
        expect(test_task.request_bytesize).to eq(0)
        expect(event.result).to be_a(Google::Gax::GaxError)
      end
    end

    context 'calling the canceller' do
      it 'stops the element from getting sent' do
        another_message = 'another msg'
        test_task = create_a_test_task
        an_event = test_task.extend([test_message])
        another_event = test_task.extend([another_message])
        expect(test_task.element_count).to eq(2)
        expect(an_event.cancel).to eq(true)
        expect(test_task.element_count).to eq(1)
        expect(an_event.cancel).to eq(false)
        expect(test_task.element_count).to eq(1)
        test_task.run
        expect(test_task.element_count).to eq(0)
        expect(another_event.result).to eq(bundled_builder([another_message]))
        expect(an_event.set?).to eq(false)
        expect(an_event.result).to be_nil
      end
    end
  end

  describe Google::Gax::Executor do
    SIMPLE_DESCRIPTOR = Google::Gax::BundleDescriptor.new('field1', [])
    DEMUX_DESCRIPTOR =
      Google::Gax::BundleDescriptor.new(
        'field1', [], subresponse_field: 'field1'
      )
    bundler = nil

    after(:each) do
      bundler.close if bundler.instance_of? Google::Gax::Executor
    end

    context 'grouped by bundle id' do
      it 'should group the api_calls by bundle_id' do
        an_elt = 'dummy_message'
        api_call = return_request
        bundle_ids = %w[id1 id2]
        threshold = 5
        options =
          Google::Gax::BundleOptions.new(element_count_threshold: threshold)
        bundler = Google::Gax::Executor.new(options)
        bundle_ids.each do |id|
          (threshold - 1).times do
            event = bundler.schedule(
              api_call,
              id,
              SIMPLE_DESCRIPTOR,
              bundled_builder([an_elt])
            )
            expect(event.canceller).to_not be_nil
            expect(event.set?).to eq(false)
            expect(event.result).to be_nil
          end
        end

        bundle_ids.each do |id|
          event = bundler.schedule(
            api_call,
            id,
            SIMPLE_DESCRIPTOR,
            bundled_builder([an_elt])
          )
          expect(event.canceller).to_not be_nil
          expect(event.set?).to eq(true)
          expect(event.result).to eq(
            bundled_builder([an_elt] * threshold)
          )
        end
      end
    end

    context 'bundling with subresponses' do
      it 'are demuxed correctly' do
        an_elt = 'dummy_message'
        api_call = return_request
        bundle_id = 'an_id'
        threshold = 5
        options =
          Google::Gax::BundleOptions.new(element_count_threshold: threshold)
        bundler = Google::Gax::Executor.new(options)
        events = []

        # send 3 groups of elements of different sizes in the bundle
        1.upto(3) do |i|
          event = bundler.schedule(
            api_call,
            bundle_id,
            DEMUX_DESCRIPTOR,
            bundled_builder(["#{an_elt}#{i}"] * i)
          )
          events.push(event)
        end
        previous_event = nil
        events.each_with_index do |current_event, i|
          index = i + 1
          expect(current_event).to_not eq(previous_event)
          expect(current_event.set?).to eq(true)
          expect(current_event.result).to eq(
            bundled_builder(["#{an_elt}#{index}"] * index)
          )
          previous_event = current_event
        end
      end

      it 'each have an exception when demuxed call fails' do
        an_elt = 'dummy_message'
        api_call = raise_exc
        bundle_id = 'an_id'
        threshold = 5
        options =
          Google::Gax::BundleOptions.new(element_count_threshold: threshold)
        bundler = Google::Gax::Executor.new(options)
        events = []

        0.upto(threshold - 2) do |i|
          event = bundler.schedule(
            api_call,
            bundle_id,
            DEMUX_DESCRIPTOR,
            bundled_builder(["#{an_elt}#{i}"])
          )
          expect(event.set?).to be(false)
          expect(event.result).to be_nil
          events.push(event)
        end
        last_event = bundler.schedule(
          api_call,
          bundle_id,
          DEMUX_DESCRIPTOR,
          bundled_builder(["#{an_elt}#{threshold - 1}"])
        )
        events.push(last_event)

        previous_event = nil
        events.each do |event|
          expect(event).to_not eq(previous_event)
          expect(event.set?).to eq(true)
          expect(event.result).to be_a(Google::Gax::GaxError)
          previous_event = event
        end
      end

      it 'each event has same result from mismatched demuxed api call' do
        an_elt = 'dummy_message'
        mismatched_result = bundled_builder([an_elt, an_elt])
        bundle_id = 'an_id'
        threshold = 5
        options =
          Google::Gax::BundleOptions.new(element_count_threshold: threshold)
        bundler = Google::Gax::Executor.new(options)
        events = []
        # send 3 groups of elements of different sizes in the bundle
        1.upto(3) do |i|
          event = bundler.schedule(
            proc { |_| mismatched_result },
            bundle_id,
            DEMUX_DESCRIPTOR,
            bundled_builder(["#{an_elt}#{i}"] * i)
          )
          events.push(event)
        end
        previous_event = nil
        events.each do |event|
          expect(event).to_not eq(previous_event)
          expect(event.set?).to eq(true)
          expect(event.result).to eq(
            mismatched_result
          )
          previous_event = event
        end
      end
    end

    context 'bundles are triggered to run correctly' do
      it 'api call not invoked until element threshold' do
        an_elt = 'dummy_msg'
        an_id = 'bundle_id'
        api_call = return_request
        threshold = 3
        options =
          Google::Gax::BundleOptions.new(element_count_threshold: threshold)
        bundler = Google::Gax::Executor.new(options)
        1.upto(3) do |i|
          event = bundler.schedule(
            api_call,
            an_id,
            SIMPLE_DESCRIPTOR,
            bundled_builder([an_elt])
          )

          expect(event.canceller).to_not be_nil
          if i < threshold
            expect(event.set?).to eq(false)
            expect(event.result).to be_nil
          else
            expect(event.set?).to eq(true)
            expect(event.result).to eq(
              bundled_builder([an_elt] * threshold)
            )
          end
        end
      end

      it 'api call not invoked until byte threshold' do
        an_elt = 'dummy_msg'
        an_id = 'bundle_id'
        api_call = return_request
        elts_for_threshold = 3
        threshold = elts_for_threshold * an_elt.bytesize
        options =
          Google::Gax::BundleOptions.new(request_byte_threshold: threshold)
        bundler = Google::Gax::Executor.new(options)
        1.upto(elts_for_threshold) do |i|
          event = bundler.schedule(
            api_call,
            an_id,
            SIMPLE_DESCRIPTOR,
            bundled_builder([an_elt])
          )

          expect(event.canceller).to_not be_nil
          if i < elts_for_threshold
            expect(event.set?).to eq(false)
            expect(event.result).to be_nil
          else
            expect(event.set?).to eq(true)
            expect(event.result).to eq(
              bundled_builder([an_elt] * elts_for_threshold)
            )
          end
        end
      end

      class MockTimer
        attr_accessor :asleep

        def initialize
          @asleep = true
        end

        def run_after(_)
          loop do
            break unless @asleep
            sleep(1 / Google::Gax::MILLIS_PER_SECOND)
          end
          yield
        end
      end

      it 'api call not invoked until time threshold' do
        test_timer = MockTimer.new
        an_elt = 'dummy_msg'
        an_id = 'bundle_id'
        api_call = return_request
        delay = 10_000
        options =
          Google::Gax::BundleOptions.new(delay_threshold_millis: delay)
        bundler = Google::Gax::Executor.new(options, timer: test_timer)
        event = bundler.schedule(
          api_call,
          an_id,
          SIMPLE_DESCRIPTOR,
          bundled_builder([an_elt])
        )
        expect(event.canceller).to_not be_nil
        expect(event.set?).to eq(false)

        test_timer.asleep = false

        # Wait until the event is set because the timer flag will need time
        # to propogate through to the thread.
        event.wait
        expect(event.result).to eq(bundled_builder([an_elt]))
      end
    end

    context 'method `close` works' do
      it 'non timed bundles are sent when the executor is closed' do
        an_elt = 'dummy_message'
        api_call = return_request
        bundle_id = 'an_id'
        threshold = 10 # arbitrary, greater than the number of elts sent
        options =
          Google::Gax::BundleOptions.new(element_count_threshold: threshold)
        bundler = Google::Gax::Executor.new(options)
        events = []

        # send 3 groups of elements of different sizes in the bundle
        1.upto(3) do |i|
          event = bundler.schedule(
            api_call,
            bundle_id,
            DEMUX_DESCRIPTOR,
            bundled_builder(["#{an_elt}#{i}"] * i)
          )
          events.push(event)
        end

        bundler.close

        previous_event = nil
        events.each_with_index do |current_event, i|
          index = i + 1
          expect(current_event).to_not eq(previous_event)
          expect(current_event.set?).to eq(true)
          expect(current_event.result).to eq(
            bundled_builder(["#{an_elt}#{index}"] * index)
          )
          previous_event = current_event
        end
      end

      it 'timed bundles are sent when the executor is closed' do
        an_elt = 'dummy_msg'
        an_id = 'bundle_id'
        api_call = return_request
        delay_threshold_millis = 100_000 # arbitrary, very high.
        options =
          Google::Gax::BundleOptions.new(
            delay_threshold_millis: delay_threshold_millis
          )
        bundler = Google::Gax::Executor.new(options)
        event = bundler.schedule(
          api_call,
          an_id,
          SIMPLE_DESCRIPTOR,
          bundled_builder([an_elt])
        )
        expect(event.canceller).to_not be_nil
        expect(event.set?).to eq(false)

        bundler.close
        expect(event.canceller).to_not be_nil
        expect(event.set?).to eq(true)
        expect(event.result).to eq(bundled_builder([an_elt]))
      end
    end
  end
  describe Google::Gax::Event do
    context 'event is working correctly' do
      it 'can be set' do
        event = Google::Gax::Event.new
        expect(event.set?).to eq(false)
        event.result = Object.new
        expect(event.set?).to eq(true)
      end

      it 'returns false when #cancel is called with no canceller' do
        event = Google::Gax::Event.new
        expect(event.canceller).to be_nil
        expect(event.cancel).to eq(false)
      end

      it 'returns cancellers result when # cancel is called' do
        event = Google::Gax::Event.new
        event.canceller = proc { true }
        expect(event.cancel).to eq(true)
        event.canceller = proc { false }
        expect(event.cancel).to eq(false)
      end

      it 'wait does not block if event is set' do
        event = Google::Gax::Event.new
        event.result = Object.new
        expect(event.wait).to eq(true)
      end

      it 'waits returns false after the timeout period' do
        event = Google::Gax::Event.new
        expect(event.wait(timeout_millis: 1)).to eq(false)
      end
    end
  end
end
