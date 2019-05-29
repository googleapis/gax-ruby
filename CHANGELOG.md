# Release History

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
