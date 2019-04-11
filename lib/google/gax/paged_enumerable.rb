# Copyright 2019, Google Inc.
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
    # A class to provide the Enumerable interface to the response of a
    # paginated method. PagedEnumerable assumes response message holds a list
    # of resources and the token to the next page.
    #
    # PagedEnumerable provides the enumerations over the resource data,
    # and also provides the enumerations over the pages themselves.
    #
    # @example normal iteration over resources.
    #   paged_enumerable.each { |resource| puts resource }
    #
    # @example per-page iteration.
    #   paged_enumerable.each_page { |page| puts page }
    #
    # @example Enumerable over pages.
    #   paged_enumerable.each_page do |page|
    #     page.each { |resource| puts resource }
    #   end
    #
    # @example more exact operations over pages.
    #   while some_condition()
    #     page = paged_enumerable.page
    #     do_something(page)
    #     break if paged_enumerable.next_page?
    #     paged_enumerable.next_page
    #   end
    #
    class PagedEnumerable
      include Enumerable

      # @attribute [r] page
      #   @return [Page] The current page object.
      attr_reader :page

      # @param request_page_token_field [String]
      #   The name of the field in request which will have the page token.
      # @param response_page_token_field [String]
      #   The name of the field in the response which holds the next page token.
      # @param resource_field [String]
      #   The name of the field in the response which holds the resources.
      def initialize(api_call, request, response, options: nil,
                     resource_field: nil)
        @api_call = api_call
        @request = request
        @response = response
        @options = options
        @resource_field = resource_field || determine_resource_field(response)

        @page = Page.new(@response, @resource_field)
      end

      # Iterate over the resources.
      # @yield [Object] Gives the resource objects in the stream.
      # @raise [RuntimeError] if it's not started yet.
      def each
        return enum_for :each unless block_given?

        each_page do |page|
          page.each do |obj|
            yield obj
          end
        end
      end

      # Iterate over the pages.
      # @yield [Page] Gives the pages in the stream.
      # @raise [GaxError] if it's not started yet.
      def each_page
        return enum_for :each_page unless block_given?

        yield @page
        loop do
          break unless next_page?
          yield next_page
        end
      end

      # True if it has the next page.
      def next_page?
        @page.next_page_token?
      end

      # Update the response in the current page.
      # @return [Page] the new page object.
      def next_page
        return unless next_page?

        next_request = @request.dup
        next_request.page_token = @page.next_page_token
        next_response = @api_call.call(next_request, @options)

        @page = Page.new(next_response, @resource_field)
      end

      # The page token to be used for the next API call.
      # @return [String]
      def next_page_token
        @page.next_page_token
      end

      # The current response object, for the current page.
      # @return [Object]
      def response
        @page.response
      end

      private

      # This inspects a response object and pulls out the first repeated field.
      def determine_resource_field(response)
        # Find the first repeated FieldDescriptor on the response Descriptor
        # Find uses the order of the FieldDescriptor on the Descriptor
        field = response.class.descriptor.find { |f| f.label == :repeated }

        # Raise if a FieldDescriptor was not found
        raise ArgumentError if field.nil?

        # Return the field name
        field.name
      end

      # A class to represent a page in a PagedEnumerable. This also implements
      # Enumerable, so it can iterate over the resource elements.
      #
      # @attribute [r] response
      #   @return [Object] the actual response object.
      # @attribute [r] next_page_token
      #   @return [Object] the page token to be used for the next API call.
      class Page
        include Enumerable
        attr_reader :response

        # @param response [Object]
        #   The response object for the page.
        # @param resource_field [String]
        #   The name of the field in response which holds the resources.
        def initialize(response, resource_field)
          @response = response
          @resource_field = resource_field
        end

        # Iterate over the resources.
        # @yield [Object] Gives the resource objects in the page.
        def each
          return enum_for :each unless block_given?

          return if @response.nil?

          # We trust that the field exists and is an Enumerable
          @response[@resource_field].each do |resource|
            yield resource
          end
        end

        def next_page_token
          return if @response.nil?

          @response.next_page_token
        end

        # Truthiness of next_page_token.
        def next_page_token?
          return if @response.nil?

          !@response.next_page_token.empty?
        end
      end
    end
  end
end
