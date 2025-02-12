QueryResults
============

This class allows you to access and iterate the results of a query to
Elasticsearch. It allows you to use Ruby's Enumerable_ methods that you already
know and love to scroll the results as if they were a standard collector. The
class takes care of requesting the results in batches for you and it works
seamlessly with or without `Elasticsearch's Scroll API`_ enabled.

You do not need to create instances of this class yourself, instead you'll get
them as return value when you use the :ref:`Index#search` method of the
:doc:`index` class:

.. code-block:: ruby

  results = index.search(
    query: {
      term: {
        'user.id': 'kimchy'
      }
    }
  )

  results.class # => JayAPI::Elasticsearch::QueryResults

#more?
******

This method returns ``true`` if there are more documents in the result set,
``false`` otherwise. This method is nowadays more or less obsolete. The idea is
that, when this method returns ``true`` then you can call `#next_batch`_ to get
the next batch of documents, if it returns ``false`` then you have reached the
end of the result set and subsequent calls to `#next_batch`_ won't yield any
more results.

It is better, however, to use `#all`_ instead, since it gives you an
`Enumerator`_ that you can iterate without worrying about this.

Example:

.. code-block:: ruby

  while results.any?
    results.each do |document|
      # do something with the document
    end

    break unless results.more?
    results = results.next_batch
  end

#each
*****

This method allows you to iterate through the current batch of documents. If you
call it with a block it will yield each document to the block, if you call it
without a block then an `Enumerator`_ will be returned, which you then can
iterate or transform with any of the methods from Ruby's standard `Enumerable`_
module.

The use of this method is also discouraged, instead you should use `#all`_ which
will give you the exact same features but you don't need to fetch the next batch
after the reaching the end.

.. code-block:: ruby

  results.each do |document|
    # do something with the document
  end

  results.each.select { |doc| doc.dig('_source', 'type') == 'test_result' }

#all
****

This method allows you to iterate the whole collection of documents matching
your query as if they were a single collection. The ``QueryResults`` class will
take care of fetching more documents for you as you reach the end of the current
batch.

If you call the method with a block each of the documents will be yielded to the
block until the end of the whole result set is reached. If you do not provide a
block an `Enumerator`_ will be returned which you can then iterate, transform or
filter with any of the methods from Ruby's `Enumerable`_ module.

Example:

.. code-block:: ruby

  results.all do |document|
    # do something with your document
  end

  results.all.map { |doc| doc['_id'] }

The returned enumerator is lazy, which means that it will only fetch the next
batch of documents if you reach the end of the current batch.

#aggregations
*************

If the query you passed to the :ref:`Index#search` method contains any
Aggregations_ they will show up here.

Example:

.. code-block:: ruby

  results = index.search(
    aggs: {
      'my-agg-name': {
        terms: {
          field: 'my-field'
        }
      }
    }
  )

  results.aggregations

  {
    "my-agg-name": {
      "doc_count_error_upper_bound": 0,
      "sum_other_doc_count": 0,
      "buckets": [
        # ...
      ]
    }
  }

#next_batch
***********

Fetches the next batch of documents from Elasticsearch.

.. warning::

  This method returns a new instance of the ``QueryResults`` class, which is the
  one containing the data for the next batch, the current instance (the
  receiver) of the method call retains the same data.

  In this sense you should think of each instance of the ``QueryResults`` class
  as immutable.

Example:

.. code-block:: ruby

  if results.more?
    results = results.next_batch
    #       ^
    #   Not the re-assigning of the variable
  end

.. _Enumerable: https://ruby-doc.org/core-2.6/Enumerable.html
.. _Enumerator: https://ruby-doc.org/core-2.6/Enumerator.html
.. _`Elasticsearch's scroll API`: https://www.elastic.co/guide/en/elasticsearch/reference/current/scroll-api.html
.. _Aggregations: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
