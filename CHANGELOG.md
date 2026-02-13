# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Please mark backwards incompatible changes with an exclamation mark at the start.

## [Unreleased]

### Fixed
- A `NameError` that was being raised when `jay_api/elasticsearch/client` was
  required without requiring `elasticsearch`.
- A `NoMethodError` that was being raised by `Elasticsearch::Stats::Indices`
  when `active_support/core_ext/string` hadn't been loaded.

### Added
- The `Elasticsearch::Stats::Index::Totals` class. The class contains information
  about an index's total metrics, for example, total number of documents, total
  size, etc.
- The `#settings` method to the `Elasticsearch::Index` class. This gives the
  caller access to the index's settings.
- The `Elasticsearch::Indices::Settings::Blocks` class. The class encapsulates
  an index's blocks settings (for example, whether the index is read-only).
- The `Elasticsearch::Indices::Settings` class. The class encapsulates an
  index's settings.
- It is now possible to configure the type used by the `RSpec::TestDataCollector`
  class when pushing documents to Elasticsearch. If no type is specified in the
  configuration the default type will be used.
- Allow the `Elasticsearch::Index` and `Elasticsearch::Indexes`'s `#push` method
  to receive a `type` parameter, just like `#index` does.

## [29.4.0] - 2026-01-28

### Added
- Support for the `bucket_selector` pipeline aggregation in
  `Elasticsearch::QueryBuilder::Aggregations`. This allows filtering
  buckets based on computed metrics (e.g., filtering terms buckets by
  aggregated values).

## [29.3.1] - 2025-12-15

### Fixed
- `PropertiesFetcher#last` now correctly returns the last set of properties
  (ordered chronologically).

## [29.3.0] - 2025-12-11

### Added
- The `timeout` parameter to `Elasticsearch::ClientFactory#create`. The parameter
  allows the user to specify the timeout in seconds for Elasticsearch requests.

## [29.2.0] - 2025-12-09

### Added
- A `#clone` method to `Elasticsearch::QueryBuilder` that properly clones the
  `QueryBuilder` and its nested objects.
- ActiveSupport's `#present?`, `#presence` and `#blank?` methods can now be used
  in ERB configuration files.

## [29.1.0] - 2025-10-22

### Added
- The `#bool` method to the `QueryBuilder::QueryClauses::Bool` class. This
  allows boolean clauses to be nested.
- `QueryBuilder#sort` can now receive either the direction of the sorting (`asc`
  or `desc`) or a `Hash` with advanced sorting options. These are relayed
  directly to Elasticsearch.

## [29.0.0] - 2025-08-28

### Changed
- ! Updated the `git` dependency from `~> 1, >= 1.8.0-1` to `~> 3`.
- ! Increased the minimum Ruby version requirement to 3.1.0

## [28.4.0] - 2025-08-26

### Added
- The `Elasticsearch::Indexes` class. A class which allows multiple indexes to
  be used (fed or queried) at the same time.

## [28.3.0] - 2025-06-05

### Added
- The `Aggregations::Composite` class and the `Aggregations#composite` method.
  They make it possible to use Elasticsearch's `composite` aggregations.

## [28.2.0] - 2025-05-30

### Added
- The `#nodes` method to the `Elasticsearch::Stats` class. This method gives the
  user access to the node-related statistics of the Elasticsearch cluster.

## [28.1.0] - 2025-05-19

### Added
- The `#stats` method to the `Elasticsearch::Client` class. The method returns
  an object that can be used to retrieve statistics about the Cluster. For the
  moment only `#indices` is available, which returns index-related statistics.

## [28.0.0] - 2025-05-09

### Added
- ! The `#keys` method to the `Configuration` class. The method returns the
  array of keys that the `Configuration` object has.

  Note that the addition of this method means that it is no longer possible to
  access the value of an attribute called `keys` via the dot syntax, however,
  it is still possible to access its value using the brackets: `[]`

## [27.5.1] - 2025-04-24

### Fixed
- The `Aggregations::TopHits` class cloning. The nested aggregations are now
  also being cloned as expected.

## [27.5.0] - 2025-04-22

### Added
- The `Aggregations::DateHistogram` class and the `Aggregations#date_histogram`
  method. They make it possible to use Elasticsearch's `date_histogram`
  aggregations.

## [27.4.0] - 2025-04-10

### Added
- The `#ping` method to `Elasticsearch::Client`

## [27.3.0] - 2025-04-04

### Added
- The `Aggregations::Cardinality` class and the `Aggregations#cardinality`
  method. They make it possible to use Elasticsearch's `cardinality`
  aggregations.

### Changed
- `GitilesHelper#gitiles_url` can now be called without a `path`. When no path
  is given the method generates a link to the given `refspec` instead.

## [27.2.1] - 2025-03-14

### Fixed
- `PropertiesFetcher#last` now correctly returns the last set of properties
  (ordered chronologically).

## [27.2.0] - 2025-02-28

### Added
- `QueryBuilder#source` can now take `false`, `Array` and `Hash` in addition to
  simple strings.

## [27.1.0] - 2025-02-19

### Added
- The `max` method to the `QueryBuilders::Aggregations` class.
- Added the `Aggregations::Max` class. To model Elasticsearch's `max`
  aggregation type.

## [27.0.0] - 2025-01-02

### Fixed
- ! `QueryClauses#merge` no longer produces nested boolean clauses when two
  boolean queries are merged.

### Added
- The `#negate` and `#negate!` methods to the `QueryClauses` class.
- The `QueryClauses::Negator` class.
- The `QueryClauses::MatchNone` class and the corresponding `#match_none` method
  to the `MatchClauses` module. This allows the use of Elasticsearch's
  [match_none](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html#query-dsl-match-none-query)
  query to be used with the Query Builder
- The `QueryClauses::MatchAll` class and the corresponding `#match_all` method
  to the `MatchClauses` module. This allows the use of Elasticsearch's
  [match_all](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html)
  query to be used with the Query Builder
- `#merge` and `#merge!` to the `QueryClauses:Bool` class

## [26.5.0] - 2024-12-06

### Added
- `Elasticsearch::Index#delete_by_query_async`, a method that asynchronously
  deletes the documents matching a query from the index
- `JayAPI::Elasticsearch::Async`, a class that provides functionality to
  perform asynchronous operations on an Elasticsearch index
- `JayAPI::Elasticsearch::Tasks`, a class that represents Elasticsearch tasks
- Two additional optional parameters: `slices` and `wait_for_completion` to
  `Elasticsearch::Index#delete_by_query`.
- `QueryBuilder::QueryClauses::MatchClauses#regexp`, a method that adds a
  `JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Regexp` clause to the
  Query Clauses set.
- `QueryBuilder::QueryClauses::Regexp`, a class that represents a Regexp query
  in Elasticsearch.

## [26.4.0] - 2024-12-03

### Added
- The `type` parameter to `Elasticsearch::Index`'s `#index` method. The
  parameter can be set to `nil` to avoid the creation of nested documents.
- The `Aggregations::TopHits` class and the `Aggregations#top_hits` method. They
  make it possible to use Elasticsearch's `top_hits` aggregations.

## [26.3.0] - 2024-09-11

### Added
- The `clone` method to the `QueryBuilder::Aggregations` class.

### Fixed
- Merging two `QueryBuilder` instances now preserves nested aggregations.
- `QueryBuilder::Aggregations::ValueCount` no longer accepts nested aggregations.
- `QueryBuilder::Aggregations::Sum` no longer accepts nested aggregations.

## [26.2.1] - 2024-09-05

### Fixed
- `QueryBuilder::Aggregations::Avg` no longer accepts nested aggregations.
- `Elasticsearch::Client` will no longer retry requests when they fail with
  one of the following errors: `BadRequest`, `Unauthorized`, `Forbidden`,
  `Not Found`, `MethodNotAllowed`, `RequestEntityTooLarge`, `NotImplemented`.

## [26.2.0] - 2024-08-13

### Added
- The `Aggregations::ValueCount` class and the `Aggregations#value_count`
  method. They make it possible to use Elasticsearch's `value_count`
  aggregations.

## [26.1.0] - 2024-08-12

### Added
- The `Aggregations::Filter` class and the `Aggregations#filter` method. They
  make it possible to use Elasticsearch's `filter` aggregations.

## [26.0.0] - 2024-08-08

### Changed
- ! The return value of `Aggregations#to_h`. Instead of returning only the
  aggregations themselves as a `Hash` the method now returns a `Hash` with a
  root `aggs` key under which the actual aggregations are placed.

### Added
- The `Aggregations::Sum` class and `Aggregations#sum` method. They allow
  Elasticsearch's `sum` aggregation to be used.
- The `clone` method to the `Aggregation` classes.
- The `aggs` method to the `Aggregation` classes. This allows Elasticsearch
  aggregations to be nested allowing the creation of composite aggregations.
- The `none?` method to the `Aggregations` class.

### Removed
! The CLI. The Gem no longer offers a CLI. The CLI functionality has been
  moved the `jay_cli` gem. Please install that gem instead.

## [25.0.1] - 2024-07-10

### Fixed
- An issue in the `PropertiesFetcher` class's `last` and `first` methods which
  produced incorrect results when the `build_number` field resets, for example,
  when build jobs are moved or re-created.

## [25.0.0] - 2024-06-20

### Removed
- ! The following methods from the `QueryBuilder::Aggregations` class:
  `add`, `clear`, `[]`

### Added
- The `terms`, `avg` and `scripted_metric` methods to the
  `QueryBuilders::Aggregations` class. These replace the former `add` method.
- Added the `Aggregations::Avg` class. To model Elasticsearch's `avg`
  aggregation type.
- Added the `Aggregations::ScriptedMetric` class. To model Elasticsearch's
  `scripted_metric` aggregation type.
- Added the `Aggregations::Terms` class. To model Elasticsearch's `terms`
  aggregation type.
- Added the `QueryBuilder::Script` class. The class represents a `script`ed
  element in an Elasticsearch query (can be used with some query clauses and
  aggregations).

## [24.0.0] - 2024-04-29

### Added
- Added the `merge` method to `QueryBuilder`
- Added the `merge` method to `Aggregations`
- Added the `merge` method to `QueryClauses`
- Added the `clone` method to `QueryClauses`
- Added the `empty?` method to `QueryClauses`
- Added the `clone` method to `QueryClauses::Bool`

### Removed
- ! Removed the `query=` method from `QueryClauses::QueryString`
- ! Removed the `conditions` method from the `QueryBuilder` class.

## [23.0.1] - 2024-03-12

### Fixed
- Added a missing `require` of `faraday/error` to `JayAPI::Elasticsearch::Client`

## [23.0.0] - 2024-03-12

### Changed
- ! The `PriorVersionFetcherBase` class no longer accepts a `cluster_url` and a
  `port` parameter, it now requires an already-initialized
  `JayAPI::Elasticsearch::Client` object.

## [22.2.0] - 2024-02-15

### Added
- Added the `delete_by_query` method to the `Elasticsearch::Index` class.
- Added the `QueryClauses::Terms` class and the corresponding `#terms` method to
  the `MatchClauses` module. These allow
  [Elasticsearch's Terms query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-terms-query.html)
  to be used when making use of the `QueryBuilder` class.

## [22.1.0] - 2023-12-18

### Added
- Enhanced `ClientFactory#create` with new configurable parameters:
  `max_attempts`, `wait_strategy` and `wait_time`.

## [22.0.0] - 2023-12-15

### Added
- A `Response` class that wraps around the raw Elasticsearch response Hash
- A `BatchCounter` class that keeps track of which batch of results the
  QueryResults object is for.
- A `SearchAfterResults` class that is a QueryResults class but for the
  Elasticsearch 'search_after' query type.
- Added 'search_after' param to Index#search, as a replacement for Scroll API.

### Removed
- ! Scroll API feature is removed, because it is deprecated.

## [21.0.2] - 2023-10-10

### Fixed
- Fixed a `NoMethodError` that was introduced with `activesupport 7.1.0`.

## [21.0.1] - 2023-09-22

### Fixed
- Add missing double splat operators to the calls for methods with keyword
  arguments. This fixes the `ArgumentError` being raised when running with
  Ruby 3.0+
- Fixed the `Elasticsearch::ClientFactory` class's type-hint documentation.

## [21.0.0] - 2023-09-14

### Changed
- ! Changed the `PropertiesFetcher#all` method:
  - The method can now take a block, if a block is given each of the fetched
    documents will be yielded to the given block.
  - If no block is given then an `Enumerator` is returned. Which can be used to
    iterate or access each of the individual elements of the fetched set.
  - The method no longer returns a `QueryResults` object.

## [20.2.0] - 2023-08-09

### Added
- Added `by_sut_revision` method to `PropertiesFetcher` class. This allows
  build properties to be fetched by specifying the desired 'sut_revision'.

## [20.1.0] - 2023-07-24

### Added
- Requirements in RSpec tests whose results are being collected with the
  `TestDataCollector` class can now be annotated with either `requirements` or
  `refs`.

## [20.0.1] - 2023-07-03

### Fixed
- Fixed a set of `ArgumentError`s that were happening during the initialization of the
  `JayAPI::Elasticsearch::Index`.

## [20.0.0] - 2023-06-26

### Added
- A wrapper class `JayAPI::Elasticsearch::Client` is introduced to wrap over
  `Elasticsearch::Client` class. Its API is the same as the original Client,
  but it will now retry a request a few times if one of the following errors
  are raised:
  * `Elasticsearch::Transport::Transport::ServerError`
  * `Faraday::TimeoutError`

### Changed
- !The Index class's constructor changed its signature to take an already
  initialized JayAPI::Elasticsearch::Client object, instead of the parameters
  needed to initialize it.

## [19.0.0] - 2023-05-30

### Removed
- ! Removed the `-b` switch from the J-Unit and C-Dash parsers. The parsers will
  no longer read build properties files.

### Changed
- ! Changed the J-Unit and C-Dash parsers, they will no longer read environment
  variables from the environment, instead they require the Test Environment to
  be specified in the configuration.

## [18.0.0] - 2023-04-28

### Changed
- ! Updated `activesupport` from `~> 6` to `~> 7`
- ! Updated `dredge` from `~> 0` to `~> 2`

## [17.0.0] - 2023-04-25

### Changed
- ! Set the minimum requirement for Ruby to 2.7.0

## [16.0.1] - 2023-04-18

### Fixed
- Restricted the version of the `ox` gem to `<= 2.14.14`

## [16.0.0] - 2023-04-18

### Changed
- ! Changed the `JayAPI::PropertiesFetcher` class. Instead of receiving all the
  parameters to initialize an index internally it now takes an already
  initialized `JayAPI::Elasticsearch::Index` object.

## [15.8.1] - 2023-04-05

### Fixed
- Fixed a bug in the `Elasticsearch::Index` class which caused the error message
  to be empty when an error occurred during push and the error details were not
  found in the first element of the response body.

## [15.8.0] - 2023-03-30

### Added
- Added the `json` as subcommand to the CLI's `import` command.

## [15.7.0] - 2023-03-27

### Added
- The `TestDataCollector` class will now push the remote URL of the repository
  from which the tests are running to Elasticsearch.

## [15.6.0] - 2023-03-24

### Added
- Added the `TimestampHandler` class for the Parsers.
- Added the `JSON::Parser` class.
- Added a `#to_yaml` method to `Configuration`, which allows to print
  the entire configuration in a human readable YAML format.
- If a search query causes an error, the corrupt query will be logged.

## [15.5.0] - 2023-01-18

### Added
- Improved the timestamp handling in the JUnit parser. The parser is now capable
  of parsing JUnit files in which the `timestamp` attribute is given in the
  `testsuite` tag, the `testcase` tag or both.

## [15.4.0] - 2022-12-19

### Added
- Added the possibility to use the `-m` command line switch when importing JUnit
  tests to provide test meta-data. The meta-data is expected to be stored in
  JSON files following ESR Labs's custom format for test meta-data.

## [15.3.0] - 2022-11-29

### Added
- Added functionality to merge, with specific rules, `JayAPI::Configuration` objects.

## [15.2.1] - 2022-11-04

### Fixed
- Fixed a bug in the methods `by_build_job` and `by_software_version` in the
  `PropertiesFetcher` class that caused the wrong data to be fetched from
  Elasticsearch for certain queries.

## [15.2.0] - 2022-10-27

### Changed
- Adapted the JUnit and CDash parsers to make them take the Test Environment
  from the Configuration instead of taking it from a hardcoded set of
  environment variables (backwards compatible).

### Added
- Added a `deep_to_h` method to the `JayAPI::Configuration` class.
- Added a `with_indifferent_access` method to the `JayAPI::Configuration` class.

## [15.1.0] - 2022-08-31

### Added
- Extended the CDash parser implementation to allow it to use the Dredge gem to
  extract meta-data from the source files and attach it to the test results
  before pushing them to Elasticsearch.

### Changed
- Removed the `jira-ruby` runtime dependency.

## [15.0.0] - 2022-06-23

### Changed
- Updated activesupport to version 6.x
- Changed the minimum Ruby version required by the gem to 2.5.0 (because of the
  `activesupport` gem update).

## [14.1.0] - 2022-06-21

### Added
- Added a public Repository#open_or_clone! method.
- Added the JayAPI::Git::Repository#remote_url method.

## [14.0.0] - 2022-06-15

### Changed
- Updated the `elasticsearch` gem to version 7.9.0
- Changed the minimum Ruby version required by the gem to 2.4.0 (because of the
  `elasticsearch` gem update).

## [13.6.0] - 2022-06-09

### Added
- Added the `cdash` subcommand to the `import` command that allows to parse
  CDash XML files and import them to Elasticsearch.

## [13.5.0] - 2022-06-07

### Changed
- Changed the `QueryString` clause to allow the user to omit the `fields`
  parameter.

### Added
- Added the `Exists` query clause to Elasticsearch's `QueryBuilder`
- Added the `Term` query clause to Elasticsearch's `QueryBuilder`
- Added the `Range` query clause to Elasticsearch's `QueryBuilder`

## [13.4.0] - 2022-04-28

### Changed
- Moved the functions `document`, `each`, and `initialize` to the base
  class `Parsers::Parser` so that both, `CDash::Parser` and `JUnit::Parser`
  can also use them.
- Changed the attribute `version_array` to `existent_versions` for readability
  purposes for the class `PriorVersionFetcherBase`.

### Added
- Added a new parser `CDash::Parser` that is able to parse XML files in CDash
  format.
- Added multiple classes `CDash::TestObject`, `CDash::Testing` that are able
  to parse specific CDash XML tags and extract information from them.
- Added a class `CDash::TestSuite` that is responsible for collecting
  `CDash::Test` objects and compute various information using those.

## [13.3.0] - 2022-03-30

### Fixed
- `PriorVesionFetcherBase` used the function `query` from `QueryBuilder` which
  has changed its meaning. Fixed the issue by using `to_query` instead.

### Added
- Added the `before` method to the `PropertiesFetcher` class.

### Changed
- Changed the `after` method of the `PropertiesFetcher` class to use `>` instead
  of `>=` when composing the query string (mainly to keep the two methods
  consistent).

### Changed
- Allows the `after` method from the `PropertiesFetcher` to take `String`s as
  arguments. The string should of course be in format expected by Elasticsearch.

## [13.2.0] - 2022-03-24

### Added
- Added the `after` method to the `PropertiesFetcher` to fetch only properties
  that were pushed after the given timestamp.

## [13.1.0] - 2022-03-18

### Added
- Added authentication params to the `Elasticsearch::Index` class constructor.
  It is now possible to specify authentication credentials for the connection to
  the Elasticsearch Clusters. The change is backwards compatible, if the cluster
  has no authentication these parameters can be omitted altogether.

## [13.0.0] - 2022-03-17

### Changed
- Refactored the `PropertiesFetcher` class to make it more flexible. The Class
  now allows the combination of multiple conditions and allows the caller to
  decide if it wants the first, the last or all the Build Properties records.

### Added
- Added a new class `PriorVersionFetcherBase` which is responsible for fetching
  the previous software version from the one provided. For that it checks all
  the versions on Jay to return a prior version that actually exists.
- Added the `MatchPhrase` query clause.

## [12.1.0] - 2022-03-16

(yanked)

## [12.0.0] - 2022-02-24

### Changed
- Changed the name of the file that contains the `PropertiesFetcher` class to
  match the name of the class.
- Changed the name of the `index` parameter of the `PropertiesFetcher` class's
  constructor to `index_name` to make it consistent with the same parameter in
  the `Elasticsearch::Index` class.
- Changed the way the `QueryBuilder` for Elasticsearch handles query clauses.
  These are now handled by the `QueryClauses` class, which allows for multiple
  types of query clauses. This also makes the API exposed by the `QueryBuilder`
  class backwards incompatible.

## [11.3.0] - 2022-02-03

### Changed
- Modified the J-Unit parser to attach the build properties `version_code` and
  `version_name` to each test suite.

## [11.2.0] - 2022-01-20

### Added
- Added the `--version` switch to the CLI.

## [11.1.0] - 2021-10-29

### Changed
- Expanded Jay API's J-Unit parser to make it work with the J-Unit files produced
  by Gradle (this requires the build job name and number, the project name and
  the version code to be provided via different means). Environment variables
  and `build.proprties` files are supported for this purpose.

## [11.0.0] - 2021-10-11

### Changed
- Removed all the `JayAPI::JIRA` modules and tests due to their migration to
  the `JIRATamer` gem.
- Change the way the `JayAPI::IDBuilder` class generates short IDs for test
  cases. Instead of removing all special characters from the string before
  computing the hash hyphens are now kept. This produces different Short IDs for
  test cases whose names differ only by a minus sign.

## [10.6.0] - 2021-10-07

### Added
- Functionality to access the Elasticsearch Scroll API. This allows to surpass the
  allowed query limit of data (default 10k docs).

## [10.5.0] - 2021-08-19

### Added
- Added the Aggregations feature to the Elasticsearch classes. This means:
  - The `QueryBuilder` class can now take aggregations and add them to the
    composed query.
  - The `QueryResults` object is now aware of the possibility that a Query
    result may contain an `aggregations` key and will provide direct access to
    it. (The implementation here is very crude).
  - Added the `Aggregations` class to manipulate aggregations when working with
    a `QueryBuilder`.

## [10.4.0] - 2021-08-13

### Added
- Added the `PropertiesFetcher` class that is responsible for fetching build
  properties from JAY when provided with proper configuration.

## [10.3.0] - 2021-07-27

### Added
- Added the `remotes` method to the `JayAPI::Git::Repository` class. The method
  returns the list of Remote Repositories linked to the repository.
- Added the `GitilesHelper` module. A module with methods to handle Gerrit's
  Gitiles URLs.

## [10.2.1] - 2021-07-02

### Fixed
- A bug in the `JIRA::CachedIssueBrowser`. When checking for known JIRA issues
  for a specific test case id, it would check whether the string value of the issue
  inside the ticket includes the specified test case id with 'include?' method. This
  would only be the case when they are identical. For a lot of cases, the test case id
  specified in a JIRA ticket is shorter and more general, so that it could encompass
  many different test cases that share a common namespace. In those cases, however,
  the current implementation would discard the relavant jira tickets, because their
  annotated test case ids are shorter than the specified one, and hence could
  not include it.
- Another issue in `JIRA::CachedIssueBrowser`. The class would split test case ids
  inside a JIRA issue by using a regular expression. This would generate a list, with
  different test case ids. However, sometimes empty elements would show up in the
  list which are now filtered out.

## [10.2.0] - 2021-06-09

### Added
- Added a 'checkout' method to the JayAPI::Git::Repository class.

## [10.1.0] - 2021-06-08

### Added
- Added the `JIRA::CachedIssueBrowser` class. This class is a drop-in replacement
  for the standard `JIRA::IssueBrowser` class. The major difference is that this
  class fetches all the issues and builds a local cache with them, then it
  performs a local search on the cache to find the issues related to a given
  Test Case ID.

  This is needed when a big number of failed test cases are expected. Querying
  JIRA for each failed test case takes a huge amount of time whereas searching
  the local cache is a lot faster, albeit it requires more memory and processing
  power on the machine executing the search.

### Fixed
- Fixed a bug in the `JIRA::IssueBrowser` class that caused the class to always
  use the field `Testcase_ID` without any regard for the given field name. This
  means that with a different field name issues would be found but never
  returned because they would be discarded by the `filter_issues` method.

## [10.0.0] - 2021-05-04

### Changed
- Updates the `thor` gem to Version 1.1.0. The changes between `thor` 0.x and
  1.x do not affect `jay_api` directly as it is already compliant. But other
  gems might need to add the `exit_on_failure?` method to their CLI classes.
- Documents the possibility of passing `nil` on the `url` parameter of the
  `Repository` class' constructor. Adjusts the class to react correctly under
  such circumstances. Tests were also added to verify the behaviour.

## [9.0.0] - 2021-04-27

### Added
- Added the `TestDataCollector` class. This class is a Formatter for `RSpec`
  that allows the pushing of test results to Jay's Elasticsearch backend. Its
  main purpose is to push the test results and in particular the annotated
  **requirements** for projects whose tests are running on pure `RSpec` (i.e.
  not inside Elite).

### Changed
- Moved `rspec` from the development to the runtime dependencies. This is needed
  because RSpec is now being included directly by one of the classes exposed by
  the API.

## [8.2.1] - 2021-04-14

### Fixed
- Removed the security feature for the ERB evaluation on configuration files.
  This was causing a `SecurityError` to be raised even when the statements
  inside the files were perfectly safe. The feature will be disabled until the
  root cause for the problem can be established and addressed.

## [8.2.0] - 2021-04-12

### Added
- Allow configuration files to use ERB, this allows (among other things) the use
  of environmental variables inside the configuration files.

## [8.1.0] - 2021-03-01

### Added
- Add the `configuration_file` and `check_configration` methods to the
  `JayAPI::CLI::Base` class. This methods allows the given configuration file
  to be checked before it is loaded. Only basic checks are performed.

## [8.0.0] - 2021-02-17

### Added
- Added a `version_clause` method to the `QueryComposer` class. The method
  allows subclasses to add a clause to restrict the query results to a
  particular software version, branch, or in the case of certain OEMs a specific
  cluster.

### Changed
- `JIRA::IssueBrowser` will now catch `SocketError` as well.

## [7.0.0] - 2021-01-12

### Changed
- Allows the `IssueBrowser` class to receive a `Hash` of options in addition to
  a `QueryComposer` class. This hash of options is then passed down to the
  given `QueryComposer` class' constructor during initialization.

## [6.0.0] - 2020-12-21

### Changed
- `Elasticsearch::QueryResults#all` can now be called without a block. In this
  case the method will return an `Enumerator` that can be used to iterate over
  the whole set of documents. An `Enumerator` is also an `Enumerable` so the
  whole spectrum of collection-based Ruby methods will be available.

## [5.3.0] - 2020-12-11

### Added
- Added a new module to elasticsearch that stores the time format recognized by
  elasticsearch and provides a function that transforms time into this format.

## [5.2.0] - 2020-11-06

### Added
- Added the `source` method to the `JayAPI::Elasticsearch::QueryBuilder` class to allow
  the user to extract only a subset of the document from Elasticsearch.

## [5.1.0] - 2020-10-30

### Added
- Added the `branches` method to the `JayAPI::Git::Repository` class to allow
  the user to fetch the list of available branches.
- Added the `log` method to the `JayAPI::Git::Repository` class to allow the
  user to get the list of commits in the current branch or a given branch.
- Added the `add_worktree` method to the `JayAPI::Git::Repository` class to
  allow the user to create worktrees out of a repository.
- Added the `worktrees` method to the `JayAPI::Git::Repository` class to allow
  the user to manipulate worktrees, list them, and remove them.

## [5.0.0] - 2020-10-12

### Changed
- Changed JIRA's `QueryComposer` class to filter out rejected tickets from the
  results.

## [4.1.0] - 2020-10-02

### Added
- Added the `object` method to the `JayAPI::Git::Repository` class to allow the
  user to fetch commit information by providing the commit `SHA1` or another Git
  reference (tag, branch, etc).
- Added the `all` method to the `JayAPI::Elasticsearch::QueryResults` class, the
  method allows the caller to easily iterate over all the records, not only the
  ones in the current `QueryResults` objects but all the available records until
  the whole result set has been traversed.

  This is a very common task, therefore the code was abstracted to the API.

### Fixed
- Fixed a bug in the `JayAPI::Elasticsearch::QueryBuilder` class that was
  causing strings to be improperly escaped when building the query. The
  quotation marks don't need to be escaped twice because this is being handled
  by the JSON library when converting the query `Hash` to a JSON string.

## [4.0.0] - 2020-09-15

### Changed
- Changed the `JayAPI::Configuration` class to allow it to parse Hashes that are
  nested inside arrays.

## [3.0.0] - 2020-09-02

### Added
- Added the necessary logic to generate the Short ID (`id`) and the Secure ID
  (`id_secure`) for the Imported JUnit Test Cases

### Changed
- Modifies the JUnit Parser it now receives a `project_name`, it uses it to
  generate the Test Case ID.

## [2.2.0] - 2020-08-09

### Added
- Added the `collapse` method to the `Elasticsearch::QueryBuilder` class.
- Added some convenient methods to the `Elasticsearch::QueryResults` class:
  `first`, `last`, `any?`

### Fixed
- Moved the `empty?` method on the `Elasticsearch::QueryResults` class to the
  delegator.

## [2.1.0] - 2020-08-05

### Added
- Added the `RequirementsExtractor` class for the JUnit Parser. The Class is
  able to parse the output of the Test Suites and extract the requirements for
  each of the Test Cases from it.
- Added the `IDBuilder` class to generate Short and Secure IDs for the Test
  Cases.

### Fixed
- Fixed a dependency issue with the `Ox` gem. The gemspec was requesting the Gem
  on version >= 2.13.2 which was not really required and was causing issues when
  trying to use the `jay_api` Gem inside Elise.

## [2.0.0] - 2020-07-31

### Fixed
- Fix a bug causing a `NoMethodError` when calling the `next_batch` method in
  the `QueryResults` class. The error was occurring because the `search` method
  in the `Index` class is returning an instance of the `QueryResults` class
  instead of a simple Hash. This change is backwards incompatible because the
  method no longer updates the state of the current instance but returns a
  different instance instead.

## [1.1.0] - 2020-07-23

### Added
- Added the Import/Parse feature for J-Unit files:
  * CLI for importing J-Unit files.
  * Parsing and importing logic.

### Fixed
- Locked the version of the elasticsearch gem to be less than `7.6.0` (because
  that version requires Ruby >= 2.4.0)
- Fixed a bug that caused the Repository class to clone the repositories in the
  wrong location (the name of the repository was being added twice to the path
  because of the way the git gem works).

### Changed
- Made the second parameter for `JayAPI::Errors::ConfigurationError` optional.

## [1.0.0] - 2020-07-17

### Added
- Added the Git::Repository class which features methods to perform lazy
  cloning and fetching of git repositories and to update they as needed.
- Added Unit Tests for the `fetch_ticket` method.

### Changed
- Changed the `fetch_ticket` method in the `JayAPI::JIRA::IssueBrowser` class to
  raise an error when an invalid JIRA Ticket ID is given.

## [0.2.0] - 2020-06-24

### Added
- Added the IssueBrowser and QueryComposer classes for JIRA, they provide
  functionality to search for issues by TestCase ID or to fetch an issue by its
  ID.

## [0.1.0] - 2020-06-18

### Added
- Added the Elasticsearch related classes. They provide access to Elastic
  Search functions and provide an easy interface to query, search and insert
  records into an Elasticsearch Index
