Google API Extensions for Ruby
================================

Google API Extensions for Ruby (gax-ruby) is a set of modules which aids the
development of APIs for clients and servers based on [gRPC][] and Google API
conventions.

Application code will rarely need to use most of the classes within this library
directly, but code generated automatically from the API definition files in
[Google APIs][] can use services such as page streaming and request bundling to
provide a more convenient and idiomatic API surface to callers.

[gRPC]: http://grpc.io
[Google APIs]: https://github.com/googleapis/googleapis/


Ruby Versions
---------------

gax-ruby is currently tested with Ruby 2.2.4.


Contributing
------------

Contributions to this library are always welcome and highly encouraged.

See the [CONTRIBUTING][] documentation for more information on how to get started.

[CONTRIBUTING]: https://github.com/googleapis/gax-ruby/blob/master/CONTRIBUTING.md


Versioning
----------

This library follows [Semantic Versioning][].

It is currently in major version zero (``0.y.z``), which means that anything
may change at any time and the public API should not be considered
stable.

[Semantic Versioning]: http://semver.org/


Details
-------

For detailed documentation of the modules in gax-python, please watch [DOCUMENTATION][].

[DOCUMENTATION]: http://www.rubydoc.info/gems/google-gax


License
-------

BSD - See [LICENSE][] for more information.

[LICENSE]: https://github.com/googleapis/gax-ruby/blob/master/LICENSE
