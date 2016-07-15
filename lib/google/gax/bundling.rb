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
  module Gax
    DEMUX_WARNING = [
      'Warning: cannot demultiplex the bundled response, got ',
      '%d subresponses; want %d, each bundled request will ',
      'receive all responses'
    ].join

    # Helper function for #compute_bundle_id.
    # Used to retrieve a nested field signified by name where dots in name
    # indicate nested objects.
    #
    # @param obj [Object] an object.
    # @param name [String] a name for a field in the object.
    # @raise [NoMethodError] if the object does not contain the named attribute.
    # @return [Object] value of named attribute. Can be nil.
    def str_dotted_access(obj, name)
      name.split('.').each do |part|
        obj = obj.send(part)
      end
      obj.nil? ? nil : obj.to_s
    end

    # Computes a bundle id from the discriminator fields of `obj`.
    #
    # +discriminator_fields+ may include '.' as a separator, which is used to
    # indicate object traversal.  This is meant to allow fields in the
    # computed bundle_id.
    # the return is an array computed by going through the discriminator fields
    # in order and obtaining the str(value) object field (or nested object
    # field) if any discriminator field cannot be found, ValueError is raised.
    #
    # @param obj [Object] an object.
    # @param discriminator_fields [Array<String>] a list of discriminator
    #     fields in the order to be to be used in the id.
    # @raise [NoMethodError] if the object does not contain the named attribute.
    # @return [Array<Object>] array of objects computed as described above.
    def compute_bundle_id(obj, discriminator_fields)
      result = []
      discriminator_fields.each do |field|
        result.push(str_dotted_access(obj, field))
      end
      result
    end

    # rubocop:disable Metrics/ClassLength

    # Coordinates the execution of a single bundle.
    #
    # @attribute [r] bundle_id
    #   @return [String] the id of this bundle.
    # @attribute [r] bundled_field
    #   @return [String] the field used to create the bundled request.
    # @attribute [r] subresponse_field
    #   @return [String] tptional field used to demultiplex responses.
    class Task
      attr_reader :bundle_id, :bundled_field,
                  :subresponse_field

      # rubocop:disable Metrics/ParameterLists

      # @param api_call [Proc] used to make an api call when the task is run.
      # @param bundle_id [String] the id of this bundle.
      # @param bundled_field [String] the field used to create the
      #     bundled request.
      # @param bundling_request [Object] the request to pass as the arg to
      #     the api_call.
      # @param kwargs [Hash] the keyword arguments passed to the api_call.
      # @param subresponse_field [String] optional field used to demultiplex
      #     responses.
      def initialize(api_call,
                     bundle_id,
                     bundled_field,
                     bundling_request,
                     kwargs,
                     subresponse_field: nil)
        @api_call = api_call
        @bundle_id = bundle_id
        @bundled_field = bundled_field
        @bundling_request = bundling_request
        @kwargs = kwargs
        @subresponse_field = subresponse_field
        @in_deque = []
        @event_deque = []
      end

      # The number of bundled elements in the repeated field.
      # @return [Numeric]
      def element_count
        sum = 0
        @in_deque.each { |elts| sum += elts.count }
        sum
      end

      # The size of the request in bytes of the bundled field elements.
      # @return [Numeric]
      def request_bytesize
        sum = 0
        @in_deque.each do |elts|
          elts.each do |e|
            sum += e.to_s.bytesize
          end
        end
        sum
      end

      # Call the task's api_call.
      #
      # The task's func will be called with the bundling requests function.
      def run
        return if @in_deque.count == 0
        request = @bundling_request
        request.send(@bundled_field).clear
        request.send(@bundled_field).concat(@in_deque.flatten)
        if !@subresponse_field.nil?
          run_with_subresponses(request, @kwargs)
        else
          run_with_no_subresponse(request, @kwargs)
        end
      end

      # Disable this since the api_call may raise any type of exception.
      # rubocop:disable Lint/RescueException

      # Helper for #run to run the api call with no subresponses.
      #
      # @param request [Object] the request to pass as the arg to
      #     the api_call.
      # @param kwargs [Hash] the keyword arguments passed to the api_call.
      def run_with_no_subresponse(request, kwargs)
        response = @api_call.call(request, **kwargs)
        @event_deque.each do |event|
          event.result = response
          event.set
        end
      rescue Exception => err
        @event_deque.each do |event|
          event.result = err
          event.set
        end
      ensure
        @in_deque.clear
        @event_deque.clear
      end

      # Helper for #run to run the api call with subresponses.
      #
      # @param request [Object] the request to pass as the arg to
      #     the api_call.
      # @param subresponse_field subresponse_field.
      # @param kwargs [Hash] the keyword arguments passed to the api_call.
      def run_with_subresponses(request, kwargs)
        response = @api_call.call(request, **kwargs)
        in_sizes_sum = 0
        @in_deque.each { |elts| in_sizes_sum += elts.count }
        all_subresponses = response.send(@subresponse_field.to_s)
        if all_subresponses.count != in_sizes_sum
          # TODO: Implement a logging class to handle this.
          # warn DEMUX_WARNING
          @event_deque.each do |event|
            event.result = response
            event.set
          end
        else
          start = 0
          @in_deque.zip(@event_deque).each do |i, event|
            response_copy = response.dup
            subresponses = all_subresponses[start, i.count]
            response_copy.send(@subresponse_field).clear
            response_copy.send(@subresponse_field).concat(subresponses)
            start += i.count
            event.result = response_copy
            event.set
          end
        end
      rescue Exception => err
        @event_deque.each do |event|
          event.result = err
          event.set
        end
      ensure
        @in_deque.clear
        @event_deque.clear
      end

      # This adds elements to the tasks.
      #
      # @param elts [Array<Object>] an array of elements that can be appended
      #     to the tasks bundle_field.
      # @return [Event] an Event that can be used to wait on the response.
      def extend(elts)
        elts = [*elts]
        @in_deque.push(elts)
        event = event_for(elts)
        @event_deque.push(event)
        event
      end

      # Creates an Event that is set when the bundle with elts is sent.
      #
      # @param elts [Array<Object>] an array of elements that can be appended
      #     to the tasks bundle_field.
      # @return [Event] an Event that can be used to wait on the response.
      def event_for(elts)
        event = Event.new
        event.canceller = canceller_for(elts, event)
        event
      end

      # Creates a cancellation proc that removes elts.
      #
      # The returned proc returns true if all elements were successfully removed
      # from @in_deque and  @event_deque.
      #
      # @param elts [Array<Object>] an array of elements that can be appended
      #     to the tasks bundle_field.
      # @param [Event] an Event that can be used to wait on the response.
      # @return [Proc] the canceller that when called removes the elts
      #     and events.
      def canceller_for(elts, event)
        proc do
          event_index = @event_deque.find_index(event) || -1
          in_index = @in_deque.find_index(elts) || -1
          @event_deque.delete_at(event_index) unless event_index == -1
          @in_deque.delete_at(in_index) unless in_index == -1
          if event_index == -1 || in_index == -1
            false
          else
            true
          end
        end
      end

      # private_class_method :run_with_no_subresponse,
      #                      :run_with_subresponses,
      #                      :event_for, :cancellor_for
    end

    # Organizes bundling for an api service that requires it.
    class Executor
      UPDATE_THREADS_RATE = 60

      # @param [BundleOptions]configures strategy this instance
      #     uses when executing bundled functions.
      def initialize(options)
        @options = options
        @tasks = {}

        # Use a Monitor in order to have the mutex behave like a reentrant lock.
        @tasks_lock = Monitor.new
      end

      # Schedules bundle_desc of bundling_request as part of
      # bundle id.
      #
      # @param api_call [Proc] used to make an api call when the task is run.
      # @param bundle_id [String] the id of this bundle.
      # @param bundle_desc [BundleDescriptor] describes the structure of the
      #     bundled call.
      # @param bundling_request [Object] the request to pass as the arg to
      #     the api_call.
      # @param kwargs [Hash] the keyword arguments passed to the api_call.
      # @return [Event] an Event that can be used to wait on the response.
      def schedule(api_call, bundle_id, bundle_desc,
                   bundling_request, kwargs: {})
        bundle = bundle_for(api_call, bundle_id, bundle_desc,
                            bundling_request, kwargs)
        elts = bundling_request.send(bundle_desc.bundled_field.to_s)
        event = bundle.extend(elts)

        count_threshold = @options.element_count_threshold
        if count_threshold > 0 && bundle.element_count >= count_threshold
          run_now(bundle.bundle_id)
        end

        size_threshold = @options.request_byte_threshold
        if size_threshold > 0 && bundle.request_bytesize >= size_threshold
          run_now(bundle.bundle_id)
        end

        event
      end

      # Helper function for #schedule.
      #
      # Given a return the corresponding bundle for a certain bundle id. Create
      # a new bundle if the bundle does not exist yet.
      #
      # @param api_call [Proc] used to make an api call when the task is run.
      # @param bundle_id [String] the id of this bundle.
      # @param bundle_desc [BundleDescriptor] describes the structure of the
      #     bundled call.
      # @param bundling_request [Object] the request to pass as the arg to
      #     the api_call.
      # @param kwargs [Hash] the keyword arguments passed to the api_call.
      # @return [Task] the bundle containing the +api_call+.
      def bundle_for(api_call, bundle_id, bundle_desc, bundling_request, kwargs)
        @tasks_lock.synchronize do
          return @tasks[bundle_id] if @tasks.key?(bundle_id)
          bundle = Task.new(api_call, bundle_id, bundle_desc.bundled_field,
                            bundling_request, kwargs,
                            subresponse_field: bundle_desc.subresponse_field)
          delay_threshold_millis = @options.delay_threshold_millis
          if delay_threshold_millis > 0
            run_later(bundle.bundle_id, delay_threshold_millis)
          end
          @tasks[bundle_id] = bundle
          return bundle
        end
      end

      # Helper function for #schedule.
      #
      # Creates a new thread that will execute the encapsulated api calls after
      # the +delay_threshold_millis+ has elapsed. The thread that is
      # spawned is added to the @threads hash to ensure that the thread will
      # api call is made before the main thread exits.
      #
      # @param bundle_id [String] the id corresponding to the bundle that
      #     is run.
      # @param delay_threshold_millis [Numeric] the number of micro-seconds to
      #     wait before running the bundle.
      def run_later(bundle_id, delay_threshold_millis)
        Thread.new do
          sleep(delay_threshold_millis / MILLIS_PER_SECOND)
          run_now(bundle_id)
        end
      end

      # Helper function for #schedule.
      #
      # Immediately runs the bundle corresponding to the bundle id.
      # @param bundle_id [String] the id corresponding to the bundle that
      #     is run.
      def run_now(bundle_id)
        @tasks_lock.synchronize do
          if @tasks.key?(bundle_id)
            @task = @tasks.delete(bundle_id)
            @task.run
          end
        end
      end

      # This function should be called before the main thread exits in order to
      # ensure that all api calls are made.
      def close
        @tasks_lock.synchronize do
          @tasks.each do |bundle_id, _|
            run_now(bundle_id)
          end
        end
      end

      # private_class_method :bundle_for, :run_later, :run_now
    end

    # Container for a thread adding the ability to cancel, check if set, and
    # get the result of the thread.
    class Event
      attr_accessor :canceller
      attr_reader :result

      def initialize
        @canceller = nil
        @result = nil
        @is_set = false
        @mutex = Mutex.new
      end

      def result=(obj)
        @mutex.synchronize do
          @result = obj
        end
      end

      # Checks to see if the event has been set. A set Event signals that
      # there is data in @result.
      # @return [Boolean] Whether the event has been set.
      def set?
        @is_set
      end

      # Signifies that the event has been set and that there is data in @result.
      def set
        @mutex.synchronize do
          @is_set = true
        end
      end

      # Resets the Event to not being set and clears the @result.
      def clear
        @mutex.synchronize do
          @result = nil
          @is_set = false
        end
      end

      # Invokes the cancellation function provided.
      def cancel
        @mutex.synchronize do
          canceller.nil? ? false : canceller.call
        end
      end

      def wait(timeout_millis: nil)
        return @is_set if @is_set
        if !timeout_millis.nil?
          deadline = Time.now + (timeout_millis / MILLIS_PER_SECOND)
          loop { return @is_set if @is_set || (Time.now > deadline) }
        else
          loop { return @is_set if @is_set }
        end
      end
    end

    module_function :compute_bundle_id, :str_dotted_access
  end
end
