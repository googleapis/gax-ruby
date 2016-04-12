Contributing
============

Here are some guidelines for hacking on [gax-ruby][].

-  Please **sign** one of the [Contributor License Agreements][#contributor-license-agreements] below.
-  [File an issue][] to notify the maintainers about what you're working on.
-  [Fork the repo][]; develop and [test your code changes][]; add docs.
-  Make sure that your [commit messages][] clearly describe the changes.
-  [Make the pull request][].

[Fork the repo]: https://help.github.com/articles/fork-a-repo
[forking]: https://help.github.com/articles/fork-a-repo
[commit messages]: http://chris.beams.io/posts/git-commit/

[File an issue]: https://github.com/googleapis/gax-ruby/issues

Before writing code, file an issue
----------------------------------

Use the issue tracker to start the discussion. It is possible that someone else
is already working on your idea, your approach is not quite right, or that the
functionality exists already. The ticket you file in the issue tracker will be
used to hash that all out.

Fork gax-ruby
-------------------

We will use GitHub's mechanism for [forking][] repositories and making pull
requests. Fork the repository, and make your changes in the forked repository.

[test your code changes]:

Include tests
-------------

Be sure to add relevant tests and run then them using `rake` before making the pull request.

Make the pull request
---------------------

Once you have made all your changes and tested, make a pull make a
pull request to move everything back into the main gax-ruby
repository. Be sure to reference the original issue in the pull
request.  Expect some back-and-forth with regards to style and
compliance of these rules.

Using a Development Checkout
----------------------------

You'll have to create a development environment to hack on
[gax-ruby][], using a Git checkout:

- While logged into your GitHub account, navigate to the [gax-ruby repo][] on GitHub.
- Fork and clone the [gax-ruby][] repository to your GitHub account
  by clicking the "Fork" button.
- Clone your fork of [gax-ruby][] from your GitHub account to your
  local computer, substituting your account username and specifying
  the destination as `hack-on-gax-ruby`. For example:

  ```bash
  cd ${HOME}
  git clone git@github.com:USERNAME/gax-ruby.git hack-on-gax-ruby
  cd hack-on-gax-ruby

  # Configure remotes such that you can pull changes from the gax-ruby
  # repository into your local repository.
  git remote add upstream https://github.com:googleapis/gax-ruby

  # fetch and merge changes from upstream into master
  git fetch upstream
  git merge upstream/master
  ```

Now your local repo is set up such that you will push changes to your
GitHub repo, from which you can submit a pull request.

- Use bundler to make sure dependency:

  ```bash
  bundle update
  ```

[gax-ruby]: https://github.com/googleapis/gax-ruby
[gax-ruby repo]: https://github.com/googleapis/gax-ruby


Running Tests
-------------

RSpec is used for the tests of [gax-ruby][]. To run the tests, you
should run `rake` command with no arguments.

```bash
rake
```

This runs both RSpec and [rubocop][].

[rubocop]: http://batsov.com/rubocop/

To run RSpec only, run `rake rspec`. To run Rubocop style checking only,
run `rake rubocop`.

To suppress a rubocop style violation, first consider adding a comment line
of rubocop/disable to the exact place of the warning. If the warning
is generic to the project, run `rubocop --auto-gen-config` to update
the config file.

Contributor License Agreements
------------------------------

Before we can accept your pull requests you'll need to sign a Contributor
License Agreement (CLA):

-   **If you are an individual writing original source code** and **you own
    the intellectual property**, then you'll need to sign an
    [individual CLA][].
-   **If you work for a company that wants to allow you to contribute your
    work**, then you'll need to sign a [corporate CLA][].

You can sign these electronically (just scroll to the bottom). After that,
we'll be able to accept your pull requests.

[individual CLA]: https://developers.google.com/open-source/cla/individual
[corporate CLA]: https://developers.google.com/open-source/cla/corporate
