Google API Extensions for Ruby
================================

[![Build Status](https://travis-ci.org/googleapis/gax-ruby.svg?branch=master)](https://travis-ci.org/googleapis/gax-ruby)
[![Code Coverage](https://img.shields.io/codecov/c/github/googleapis/gax-ruby.svg)](https://codecov.io/github/googleapis/gax-ruby)
[![Gem Version](https://badge.fury.io/rb/google-gax.svg)](https://badge.fury.io/rb/google-gax)

Google API Extensions for Ruby (gax-ruby) is a set of modules which aids the
development of APIs for clients and servers based on [gRPC][] and Google API
conventions.

Application code will rarely need to use most of the classes within this library
directly, but code generated automatically from the API definition files in
[Google APIs][] can use services such as page streaming and request bundling to
provide a more convenient and idiomatic API surface to callers.

[gRPC]: http://grpc.io
[Google APIs]: https://github.com/googleapis/googleapis/

## 2.0 Under development

The master branch is currently under development for version 2.0, which will
break backwards compatibility with the 1.x releases. A list of upcoming changes
in 2.0 can be seen by viewing [issues using the 2.0
tag](https://github.com/googleapis/gax-ruby/labels/2.0).

To view the code for the 1.x releases, see the [1.x
branch](https://github.com/googleapis/gax-ruby/tree/1.x).

## Documentation

Detailed documentation for gax-ruby can be seen on
[rubydoc.info](http://www.rubydoc.info/gems/google-gax).

## Supported Ruby Versions

This library is supported on Ruby 2.3+.

Google provides official support for Ruby versions that are actively supported
by Ruby Core—that is, Ruby versions that are either in normal maintenance or in
security maintenance, and not end of life. Currently, this means Ruby 2.3 and
later. Older versions of Ruby _may_ still work, but are unsupported and not
recommended. See https://www.ruby-lang.org/en/downloads/branches/ for details
about the Ruby support schedule.

## Contributing

Contributions to this library are always welcome and highly encouraged.

See the [Contributing
Guide](https://github.com/googleapis/gax-ruby/blob/master/CONTRIBUTING.md)
for more information on how to get started.

## Versioning

This library follows [Semantic Versioning](http://semver.org/).

## License

BSD - See [LICENSE](https://github.com/googleapis/gax-ruby/blob/master/LICENSE)
for more information.
