Indexable
=========

The following methods are common to the following classes, which include the
``Indexable`` mixin:

.. toctree::
   :maxdepth: 2
   :glob:

   indexable/*

#push
-----

The ``push`` method stores a document in the ``Indexable``'s buffer. If the buffer
reaches the maximum number of records the buffer will be flushed automatically.

``push`` takes a single ``Hash``, the document you want to send to the index(es).

.. warning::

  When using the ``push`` method make sure to call ``flush`` at the end.
  Automatic flushing only occurs when the buffer is full, if you do not call
  ``flush`` at the end of the run you might lose some documents.

Example:

.. code-block:: ruby

  documents.each do |document|
    # do something with your document, then push it
    indexable.push(document)
  end

  indexable.flush # Do not forget to flush the indexable at the end.

#index
------

``index`` pushes a document directly to the Elasticsearch cluster without adding
it to the buffer first. So you don't need to call ``flush``:

``index`` takes a single ``Hash``, the document you want to send to the index(es).

Example:

.. code-block:: ruby

  indexable.index(my_document)

.. note::

  Pushing documents one at a time is very inefficient because the ``Indexable``
  needs to perform an HTTP Request for each one. If you want to send many
  documents use ``push`` instead.

.. _`Indexable#search`:

#search
-------

The ``search`` method allows you to search the Elasticsearch index(es) for
documents matching the provided query. This method takes two arguments:

* ``query`` A ``Hash`` with the query you want to execute, this Hash will be
  converted to JSON before being sent to Elasticsearch. It must follow
  `Elasticsearch's DSL`_. There is no limit to what you can put in this
  Hash, no validation, nor transformation is performed. Queries can be as simple
  or as complex as you want.
* ``type`` (optional): Specify `:search_after` for using the `Search After`_ feature.
  This is needed if you have more than 10,000 matching documents.

You can compose the ``query`` by yourself or you can use the
:doc:`query_builder`, which offers an easier, albeit limited interface.

The ``search`` method returns a :doc:`query_results` class which you can use to
iterate the result set in batches.

Example:

.. code-block:: ruby

  indexable.search(
    query: {
      match_all: { }
    },
    sort: [
      {
        '@timestamp': 'desc'
      }
    ],
    type: :search_after
  )

#flush
------

Flushes the current buffer to Elasticsearch, pushing all the documents currently
stored in the queue (if there are any).

Example:

.. code-block:: ruby

  documents.each do |document|
    indexable.push(document)
  end

  indexable.flush

#queue_size
-----------

Returns the current number of documents currently waiting to be flushed to
Elasticsearch:

Example

.. code-block:: ruby

  indexable.queue_size # => 16

#delete_by_query
----------------

This method allows you to remove the documents that match the given query from
the index(es). The method has a single parameter:

* ``query``: A ``Hash`` with the query you want to use to match documents for
  deletion. For more information on this parameter or how to create queries see
  the :ref:`Indexable#search` method documentation.

On success the method will return a ``Hash`` with information about the executed
command, for example:

.. code-block:: ruby

   {
     took: 740,
     timed_out: false,
     total: 1748,
     deleted: 1748,
     batches: 2,
     version_conflicts: 0,
     noops: 0,
     retries: { bulk: 0, search: 0 },
     throttled_millis: 0,
     requests_per_second: -1.0,
     throttled_until_millis: 0,
     failures: []
   }

On error an ``Elasticsearch::Transport::Transport::ServerError`` will be raised.

.. _`Elasticsearch's DSL`: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
.. _`Search After`: https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html#search-after
