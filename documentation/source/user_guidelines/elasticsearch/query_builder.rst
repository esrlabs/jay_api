QueryBuilder
============

The ``QueryBuilder`` class was created with the intention of offering an easy
way to build the most common queries in a ruby-like way. The class was designed
with the intention of imitating `Ruby on Rails' Query DSL`_ (adapted to
Elasticsearch).

This means that you can chain multiple methods together to build a query, for
example:

.. code-block:: ruby

   query_builder = QueryBuilder.new
     .size(100)
     .from(50)
     .sort(nane: :asc, age: :desc)
     .collapse('name')

   query_builder.query.bool.must do |query|
     query.query_string(fields: 'city', query: '(new york city) OR (big apple)')
     query.wildcard(field: 'company', value: '*Inc.')
   end

   index.search(query.to_query)

.. warning::

  The ``query`` method should always be called at the end because it doesn't
  return the instance of ``QueryBuilder`` but an instance of ``QueryClauses``
  so only query related methods can be chained on it.

Methods can also be called independently, for example:

.. code-block:: ruby

  query_builder = QueryBuilder.new
  query_builder.query.bool.must do |query|
    query.query_string(fields: 'city', query: '(new york city) OR (big apple)')
    query.wildcard(field: 'company', value: '*Inc.')
  end
  query_builder.size(100).from(50)
  query_builder.collapse('name')

  index.search(query.to_query)

.. note::

  Check `Elasticsearch's search API`_ to get a better idea of how searches work
  in Elasticsearch. Many of the clauses explained here are documented in detail
  there.

#from and #size
---------------

``from`` and ``size`` allow you to define the boundaries of the current batch.
``from`` decides the document offset from 0, so for example:

.. code-block:: ruby

  query_builder.from(100)

Will cause Elasticsearch to return documents starting from index 100. This
usually makes sense only if you are sorting the documents with `#sort`_.

``size`` defines the maximum number of documents to return. This is, of course,
needed in most cases to avoid queries that run for too long or need to transfer
big amounts of data. For example:

.. code-block:: ruby

  query_builder.size(50)

This will cause Elasticsearch to return a maximum of 50 documents. (Less might
be returned if there aren't enough documents matching the query).

By using ``from`` and ``size`` you can only scroll through a maximum of 10,000
documents. If you have more than that in your index, you'll have to use
:ref:`Index#search` method with ``type: :search_after``.

#sort
-----

``sort`` is used to tell Elasticsearch how to sort the returned documents, this
is useful to present them in a particular order, but it could also be used in
combination with ``size`` to fetch the latest entry of a list or the top ten
items from a ranking.

The method receives a hash of fields -> sort orders, which can be either
``:asc`` for ascending or ``:desc`` for descending order. For example:

.. code-block:: ruby

  query_builder.sort(name: :asc, age: :desc)

The method can be called more than once if needed, all the calls will be
aggregated into a single ``sort`` clause, for example:

.. code-block:: ruby

  query_builder.sort(name: 'asc')
  query_builder.sort(age: 'desc')

#collapse
---------

You can collapse query results to get rid of duplicated values or to get only
the first, latest, biggest, smallest, etc. When you collapse results over a
certain field only one occurrence of each value on that field will appear in the
final resul set. In combination with `#sort`_ this is very powerful tool.

For more details please check `Elasticsearch's documentation on Collapse`_

Example:

.. code-block:: ruby

  query_builder = QueryBuilder.new
    .from(0)
    .sort('http.response.bytes': :desc)
    .collapse('user.id')

  index.search(query_builder.to_query)

The query above would return the biggest request each user has made.

.. warning::

  ``collapse`` cannot be used with Elasticsearch's Search After API.

#source
-------

This method allows you to filter the fields you want to include in the returned
documents, this can be very useful if you have very big documents but you are
only interested in part of them.

Example:

.. code-block:: ruby

  query_builder.source('obj.*')

With the above query only the attributes inside the nested structure ``obj``
will be returned.

It is also possible to completely remove the document's source from the result
by passing ``false`` as parameter:

.. code-block:: ruby

   query_builder.source(false)

Elasticsearch also allows the use of arrays to grab elements from multiple
objects:

.. code-block:: ruby

   query_builder.source(%w[test_case.* meta_data.*])

And the use of Hashes to include or exclude parts of the document, for example:

.. code-block:: ruby

   query_builder.source(
     { includes: 'test_case.*' , excludes: 'test_case.test_steps'}
   )

#to_h and #to_query
-------------------

Once you have added all the clauses you want on your queries you can call
``to_h`` or ``to_query`` to get the corresponding Hash. The class converts the
query to a Hash representation that can then be passed to :ref:`Index#search` to
perform the actual search.

.. note::

  💡
    You can use `Ruby's JSON module`_ to get a JSON representation of the query
    and use it to query Elasticsearch directly via API or using
    `Kibana's DevTools console`_.

  .. code-block:: ruby

    JSON.pretty_generate(query_builder.to_h)

#query
------

The ``query`` method returns an instance of the ``QueryClauses`` class which
provides you with a way to create complex Elasticsearch queries in a ruby way:

Simple Queries
++++++++++++++

Simple queries are of course queries with a single clause, for example:

.. code-block:: ruby

  query_builder = QueryBuilder.new
  query_builder.query.wildcard(field: 'user.id', value: 'ki*y')

.. warning::

  Simple queries can have only one clause, if you try to add another clause to
  a simple query an error will be raised:

  .. code-block:: ruby

    query_builder = QueryBuilder.new
    query_builder.query
      .wildcard(field: 'user.id', value: 'ki*y')
      .query_string(fields: 'city', query: '(new york city) OR (big apple)')

    # JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
    #   Queries can only have one top-level query clause, to use multiple
    #   clauses add a compound query, for example: `bool`

.. _`QueryBuilder#bool`:

Boolean Queries
+++++++++++++++

Boolean queries allow you to create compound queries and state whether all of
its clauses, or any of them, or none **must** be met. This is explained in more
detail in `Elasticsearch's documentation for boolean queries`_.

To build a boolean query you call the ``bool`` method on the ``QueryClauses``
object and then you use one of Elasticsearch's occurrence types: ``must``,
``filter``, ``should`` or ``must_not``. Then you can open a block to add your
query clauses:

.. code-block:: ruby

  query_builder = QueryBuilder.new
  query_builder.query.bool.must do |query|
    query.wildcard(field: 'user.id', value: 'ki*y')
    query.query_string(fields: 'city', query: '(new york city) OR (big apple)')
  end

Alternatively you can just add each clause on an independent call:

.. code-block:: ruby

  query_builder = QueryBuilder.new
  query_builder.query.bool.must.query.wildcard(field: 'user.id', value: 'ki*y')
  query_builder.query.bool.must.query_string(fields: 'city', query: '(new york city) OR (big apple)')

If you need multiple occurrence types in your query you can just call them in
turn:

.. code-block:: ruby

  query_builder = QueryBuilder.new
  query_builder.query.bool.must do |query|
    query.wildcard(field: 'user.id', value: 'ki*y')
    query.query_string(fields: 'city', query: '(new york city) OR (big apple)')
  end.must_not do |query|
    query.wildcard(field: 'company', value: '*Inc.')
  end

match_phrase
++++++++++++

A `Match Phrase Query`_ allows you to perform an exact phrase match. This is
useful because a standard match uses an analyzer which splits the given text
into words and then search for them individually, if you need an exact match
use ``match_phrase`` instead.

Example:

.. code-block:: ruby

  query_builder.query.match_phrase(field: 'message', phrase: 'this is a test')

match_all
+++++++++

A `Match All`_ clause matches all documents in the index.

Example:

.. code-block:: ruby

   query_builder.query.match_all

match_none
++++++++++

A `Match None`_ clause matches no documents.

Example:

.. code-block:: ruby

   query_builder.query.match_none

query_string
++++++++++++

A `Query String Query`_ allows you to provide very specific queries which might
span through multiple fields, or all of them, you can use boolean operators
between the fields, and even use comparison operators like ``>``, ``<=``, etc.

This type of query gives you the most flexibility but provides no abstraction,
things are sent to Elasticsearch as you type them, so you are on your own.

Example:

.. code-block:: ruby

  # without fields
  query_builder.query.query_string(query: '(new york city) OR (big apple)')

  # with fields
  query_builder.query.query_string(fields: 'content', query: "this AND that")

  # fields as part of the query string
  query_builder.query.query_string(query: 'age:>=10')

Note the use of the boolean operator ``AND``. This will actually be interpreted
by Elasticsearch. Please double check
`Elasticsearch's Documentation <Query String Query>`_ for all the possibilities
and the exact syntax.

.. warning::

  **Watch out!** When using this type of query remember that Elasticsearch is
  parsing the string, so if you aren't getting the results you expect you might
  need to escape the string or add quotation marks.

wildcard
++++++++

A `Wildcard Query`_ allows you to find documents in which one of the fields
match the given wildcard pattern. Check Elasticsearch's documentation for
information on what patterns are allowed and what they mean.

Example:

.. code-block:: ruby

  query_builder.query.wildcard(field: 'user.id', value: "ki*y")

exists
++++++

An `Exists Query`_ allows you to find documents in which the given field exists
(i.e. has a value). In combination with a :ref:`Boolean Query<QueryBuilder#bool>` and
the ``must_not`` occurrence type you can also search for documents in which the
field doesn't have a value.

Example:

.. code-block:: ruby

  # User must exist
  query_builder.query.exists(field: 'user')

  # Find users without an ID
  query_builder.query.bool.must_not.exists(field: 'user.id')

term
++++

A `Term Query`_ allows you to search for documents with exact matches for the
given value. This means that the value is matched directly by Elasticsearch
instead of being analyzed first.

Example:

.. code-block:: ruby

  query_builder.query.term(field: 'full_text', value: 'Quick Brown Foxes!')

range
+++++

A `Range Query`_ allows you to search for documents in which a particular field
is inside the given range. The range can be defined by one or more comparison
operators.

.. code-block:: ruby

  # All the documents in which the age is between 10 and 20
  query_builder.query.range(field: 'age', gte: 10, lte: 20)

terms
+++++

A `Terms Query`_ will match documents that have either of the given values in
the specified field. It is very similar to SQL's ``IN`` clause.

.. code-block:: ruby

   # All the documents in which the result is either failed or error
   query_builder.query.terms(field: 'test_case.result', %w[failed error])


regexp
++++++

A `Regexp Query`_ will match documents that satisfies the specified pattern

.. code-block:: ruby

   # All the documents in which the sut_revision starts with 'ff9'
   query_builder.query.regexp(field: test_env.sut_revision', value: 'ff9.*')

.. note::

    IMPORTANT: unintuitively, anchor operators such as `^` (beginning of line)
    or `$` (end of line) are not supported by Lucene, Elasticsearch's underlying
    search engine. To match a term, the regular expression must match the entire
    string.

#merge
------

The ``merge`` method merges two ``QueryBuilder`` objects into a single one. This
opens the door to the construction of compound queries.

Example:

.. code-block:: ruby

   users_query = QueryBuilder.new
     .terms(field: 'user.id', terms: %w[kimchy elkbee])
     .sort('user.created_at' => :desc)
     .size(100)

   bio_query = QueryBuilder.new
     .query_string(query: "user.bio: painter OR poet")
     .size(10)

   compound_query = users_query.merge(bio_query)

Would be equivalent to:

.. code-block:: ruby

   compound_query = QueryBuilder.new
     .sort('user.created_at' => :desc) # Kept from the users_query
     .size(10)                         # From bio_query, replaced the `size` clause in users_query

   compound_query.query.bool.must do |bool_query|
     bool_query.terms(field: 'user.id', terms: %w[kimchy elkbee])
     bool_query.query_string(query: "user.bio: painter OR poet")
   end

.. note::

   This method returns a new ``QueryBuilder`` object which can be further
   modified without affecting the source objects.

The different clauses of the query are merged like this:

``from``, ``size``, ``source`` and ``collapse``:
  The clause in the second ``QueryBuilder`` object will replace the one in the
  first. If the second object doesn't have the clause, the one in the first
  object is kept.

``sort``, ``query`` and ``aggregations``:
  These are merged, the result is a compound of the clauses in both objects.
  Query clauses are merged with a boolean ``must`` query (equivalent to ``AND``)

aggregations
------------

The ``aggregations`` method enables you to add aggregations to the query. For
more information please refer to the :doc:`aggregations` documentation page.

You can use the methods ``any?`` and ``none?`` to check if the query has
aggregations or not:

Example:

.. code-block:: ruby

    query_builder.aggregations.any? # => Returns true or false
    query_builder.aggregations.none? # => the opposite of #any?

.. _`Ruby on Rails' Query DSL`: https://guides.rubyonrails.org/active_record_querying.html
.. _`Elasticsearch's search API`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html
.. _`Elasticsearch's documentation on Collapse`: https://www.elastic.co/guide/en/elasticsearch/reference/current/collapse-search-results.html
.. _`Ruby's JSON module`: https://ruby-doc.org/stdlib-2.6.6/libdoc/json/rdoc/JSON.html
.. _`Kibana's DevTools console`: https://www.elastic.co/guide/en/kibana/current/console-kibana.html
.. _`Elasticsearch's documentation for boolean queries`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html
.. _`Match Phrase Query`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query-phrase.html#query-dsl-match-query-phrase
.. _`Match All`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html
.. _`Match None`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html#query-dsl-match-none-query
.. _`Query String Query`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
.. _`Wildcard Query`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-wildcard-query.html
.. _`Exists Query`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-exists-query.html
.. _`Term Query`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-term-query.html#query-dsl-term-query
.. _`Range Query`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-range-query.html
.. _`Terms Query`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-terms-query.html
.. _`Regexp Query`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-regexp-query.html
