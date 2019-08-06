# Copyright 2017, Google LLC
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

require 'google/protobuf/timestamp_pb'

module Google
  # Gax defines Google API extensions
  module Gax
    # Regex used by gapic to find version files and directories.
    VERSION_MATCHER = /
        ([vV]\d+) # Major version eg: v1
        ([pP]\d+)? # Point release eg: p2
        (([aA]lpha|[bB]eta)\d*)? # Release level eg: alpha3
    /x

    # Creates an instance of a protobuf message from a hash that may include
    # nested hashes. `google/protobuf` allows for the instantiation of protobuf
    # messages using hashes but does not allow for nested hashes to instantiate
    # nested submessages.
    #
    # @param hash [Hash || Class] The hash to be converted into a proto message.
    #   If an instance of the proto message class is given, it is returned
    #   unchanged.
    # @param message_class [Class] The corresponding protobuf message class of
    #   the given hash.
    #
    # @return [Object] An instance of the given message class.
    def to_proto(hash, message_class)
      return hash if hash.is_a? message_class

      # Sanity check: input must be a Hash
      unless hash.is_a? Hash
        raise ArgumentError.new(
          "Value #{hash} must be a Hash or a #{message_class.name}"
        )
      end
      hash = coerce_submessages(hash, message_class)
      message_class.new(hash)
    end

    # Coerces values of the given hash to be acceptable by the instantiation
    #   method provided by `google/protobuf`
    #
    # @private
    #
    # @param hash [Hash] The hash whose nested hashes will be coerced.
    # @param message_class [Class] The corresponding protobuf message class of
    #   the given hash.
    #
    # @return [Hash] A hash whose nested hashes have been coerced.
    def coerce_submessages(hash, message_class)
      return nil if hash.nil?
      coerced = {}
      message_descriptor = message_class.descriptor
      hash.each do |key, val|
        field_descriptor = message_descriptor.lookup(key.to_s)
        if field_descriptor && field_descriptor.type == :message
          coerced[key] = coerce_submessage(val, field_descriptor)
        elsif field_descriptor && field_descriptor.type == :bytes &&
              (val.is_a?(IO) || val.is_a?(StringIO))
          coerced[key] = val.binmode.read
        else
          # `google/protobuf` should throw an error if no field descriptor is
          # found. Simply pass through.
          coerced[key] = val
        end
      end
      coerced
    end

    # Coerces the value of a field to be acceptable by the instantiation method
    # of the wrapping message.
    #
    # @private
    #
    # @param val [Object] The value to be coerced.
    # @param field_descriptor [Google::Protobuf::FieldDescriptor] The field
    #   descriptor of the value.
    #
    # @return [Object] The coerced version of the given value.
    def coerce_submessage(val, field_descriptor)
      if (field_descriptor.label == :repeated) && !(map_field? field_descriptor)
        coerce_array(val, field_descriptor)
      elsif field_descriptor.subtype.msgclass == Google::Protobuf::Timestamp &&
            val.is_a?(Time)
        time_to_timestamp(val)
      else
        coerce(val, field_descriptor)
      end
    end

    # Coerces the values of an array to be acceptable by the instantiation
    # method the wrapping message.
    #
    # @private
    #
    # @param array [Array<Object>] The values to be coerced.
    # @param field_descriptor [Google::Protobuf::FieldDescriptor] The field
    #   descriptor of the values.
    #
    # @return [Array<Object>] The coerced version of the given values.
    def coerce_array(array, field_descriptor)
      unless array.is_a? Array
        raise ArgumentError.new('Value ' + array.to_s + ' must be an array')
      end
      array.map do |val|
        coerce(val, field_descriptor)
      end
    end

    # Hack to determine if field_descriptor is for a map.
    #
    # TODO(geigerj): Remove this once protobuf Ruby supports an official way
    # to determine if a FieldDescriptor represents a map.
    # See: https://github.com/google/protobuf/issues/3425
    def map_field?(field_descriptor)
      (field_descriptor.label == :repeated) &&
        (field_descriptor.subtype.name.include? '_MapEntry_')
    end

    # Coerces the value of a field to be acceptable by the instantiation method
    # of the wrapping message.
    #
    # @private
    #
    # @param val [Object] The value to be coerced.
    # @param field_descriptor [Google::Protobuf::FieldDescriptor] The field
    #   descriptor of the value.
    #
    # @return [Object] The coerced version of the given value.
    def coerce(val, field_descriptor)
      return val unless (val.is_a? Hash) && !(map_field? field_descriptor)
      to_proto(val, field_descriptor.subtype.msgclass)
    end

    # Utility for converting a Google::Protobuf::Timestamp instance to a Ruby
    # time.
    #
    # @param timestamp [Google::Protobuf::Timestamp] The timestamp to be
    #   converted.
    #
    # @return [Time] The converted Time.
    def timestamp_to_time(timestamp)
      Time.at(timestamp.nanos * 10**-9 + timestamp.seconds)
    end

    # Utility for converting a Ruby Time instance to a
    # Google::Protobuf::Timestamp.
    #
    # @param time [Time] The Time to be converted.
    #
    # @return [Google::Protobuf::Timestamp] The converted
    #   Google::Protobuf::Timestamp.
    def time_to_timestamp(time)
      Google::Protobuf::Timestamp.new(seconds: time.to_i, nanos: time.nsec)
    end

    module_function :to_proto, :coerce_submessages, :coerce_submessage,
                    :coerce_array, :coerce, :map_field?, :timestamp_to_time,
                    :time_to_timestamp
    private_class_method :coerce_submessages, :coerce_submessage, :coerce_array,
                         :coerce, :map_field?
  end
end
