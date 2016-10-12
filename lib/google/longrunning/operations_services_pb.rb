# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: google/longrunning/operations.proto for package 'google.longrunning'
# Original file comments:
# Copyright 2016 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'grpc'
require 'google/longrunning/operations_pb'

module Google
  module Longrunning
    module Operations
      # Manages long-running operations with an API service.
      #
      # When an API method normally takes long time to complete, it can be designed
      # to return [Operation][google.longrunning.Operation] to the client, and the client can use this
      # interface to receive the real response asynchronously by polling the
      # operation resource, or pass the operation resource to another API (such as
      # Google Cloud Pub/Sub API) to receive the response.  Any API service that
      # returns long-running operations should implement the `Operations` interface
      # so developers can have a consistent client experience.
      class Service

        include GRPC::GenericService

        self.marshal_class_method = :encode
        self.unmarshal_class_method = :decode
        self.service_name = 'google.longrunning.Operations'

        # Gets the latest state of a long-running operation.  Clients can use this
        # method to poll the operation result at intervals as recommended by the API
        # service.
        rpc :GetOperation, GetOperationRequest, Operation
        # Lists operations that match the specified filter in the request. If the
        # server doesn't support this method, it returns `UNIMPLEMENTED`.
        #
        # NOTE: the `name` binding below allows API services to override the binding
        # to use different resource name schemes, such as `users/*/operations`.
        rpc :ListOperations, ListOperationsRequest, ListOperationsResponse
        # Starts asynchronous cancellation on a long-running operation.  The server
        # makes a best effort to cancel the operation, but success is not
        # guaranteed.  If the server doesn't support this method, it returns
        # `google.rpc.Code.UNIMPLEMENTED`.  Clients can use
        # [Operations.GetOperation][google.longrunning.Operations.GetOperation] or
        # other methods to check whether the cancellation succeeded or whether the
        # operation completed despite cancellation. On successful cancellation,
        # the operation is not deleted; instead, it becomes an operation with
        # an [Operation.error][google.longrunning.Operation.error] value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
        # corresponding to `Code.CANCELLED`.
        rpc :CancelOperation, CancelOperationRequest, Google::Protobuf::Empty
        # Deletes a long-running operation. This method indicates that the client is
        # no longer interested in the operation result. It does not cancel the
        # operation. If the server doesn't support this method, it returns
        # `google.rpc.Code.UNIMPLEMENTED`.
        rpc :DeleteOperation, DeleteOperationRequest, Google::Protobuf::Empty
      end

      Stub = Service.rpc_stub_class
    end
  end
end
