# Jay API

This gem provides a set of classes and modules to access Jay functionality
while abstracting internal implementations.

## Requirements

* Ruby >= 3.1.0
* Bundler ~> 2

## Setup

Clone the repository and install the dependencies by running:

```shell
bundle install
```

## Running Tests

You can run the tests just by executing rspec.

```shell
bundle exec rspec
```

To generate a Coverage report:

```shell
export COVERAGE=true
rspec
```

*The coverage report will be written to the `/coverage` path*

## Generating Documentation

```shell
bundle exec yard
```

*The documentation will be generated in the `/doc` path*

## Contributing

* This project uses [Semantic Versioning](https://semver.org/)
* This project uses a CHANGELOG.md to keep track of the changes.

1. Add your feature.
2. While editing your code keep an eye out for Rubocop and Reek suggestions
   try to keep both linters happy. 😉
3. Write unit and integration *(desirably but not required)* tests for it.
4. Run the tests with the coverage report generation enabled (Check the *Running
   Tests section)*.
5. Make sure your Unit Test coverage is at least 90%
6. Run the `yard` command to generate documentation and make sure your
   documentation coverage is 100% (everything should be documented)
7. Add your features to the `CHANGELOG.md` file under the *Unreleased* section.
   (Check the `CHANGELOG.md`) file for info on how to properly add the changes
   there.
8. Push your changes for code review
