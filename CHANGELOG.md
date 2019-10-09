# Release History

### 1.8.0 / 2019-10-09

This release requires Ruby 2.4 or later.

* Update dependencies on googleauth, grpc, google-protobuf, and googleapis-common-protos.

### 1.7.1 / 2019-08-29

* Fixed: Per-call timeout overrides from client configs are now honored.

### 1.7.0 / 2019-06-27

* Support overrides of the service address and port for long-running operations.

### 1.6.3 / 2019-06-04

* Override retry options even if no retry codes were specified.

### 1.6.2 / 2019-05-31

* Allow for a nil timeout to mean a nil deadline for non-retriable calls.

### 1.6.1 / 2019-05-29

* Non-retryable calls yielded only operation rather than response and operation. Fixed.

### 1.6.0 / 2019-05-29

* Added metadata argument to OperationsClient.new allowing users to set default headers.
* Fixes an issue where metadata set on CallSettings was not preserved after merging a CallOptions object.
* Fixes an issue where timeout wasn't being used when retry is configured.

### 1.5.0 / 2019-1-7

* Loosen googleauth dependency
* Make Operation class type arguments optional

### 1.4.0 / 2018-9-26

* Fix for misspelled scopes option in the operations_client
* Add option to use protobuf descriptor pool to unpack long running response types
* Use protobuf descriptor pool to unpack error message details instead of the expected class name

### 1.3.0 / 2018-6-7

* Add support for gRPC interceptors (experimental)

### 1.2.0 / 2018-4-10

* Add support for custom exception mapping

### 1.1.0 / 2018-3-20

* Add support for passing blocks to unary RPC calls
* Deprecated kwargs in call settings and replaced with metadata

### 1.0.1 / 2017-12-21

* Changes not logged up to this release
