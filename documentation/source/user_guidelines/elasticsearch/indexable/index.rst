Index
=====

.. note::

   This class includes the :doc:`../indexable` mixin. It exposes all its methods.

This class represents an Index inside an Elasticsearch cluster. It provides a
set of methods that allow the user to query the index and add new data.

The class also keeps a buffer of documents waiting to be pushed to the index,
the user can add documents to the buffer and the class will push them as soon as
the buffer is full. The user can also force the push of the records by flushing
the buffer.

To initialize an index:

.. code-block:: ruby

  client = JayAPI::Elasticsearch::ClientFactory.new(
    cluster_url: 'https://my-cluster.elastic.io'
  ).create(max_attempts: 3, wait_strategy: :constant, wait_interval: 2)

  index = JayAPI::Elasticsearch::Index.new(
    client: client,
    index_name: 'my_index'
  )

The ``cluster_url`` and the ``index_name`` are the only required parameters. If
the cluster is configured to use Elasticsearch's default port (``9200``) and has
no authentication in place this is all you need. However in most cases that
would not be enough, so you can also provide the following extra parameters:

* ``port``: The port number where the Elasticsearch cluster is listening for
  connections.
* ``username``: The username to use when authentication against the cluster.
* ``password``: The user's password
* ``batch_size``: The amount of documents the ``Index`` will store in its buffer
  before triggering an automatic flush.
* ``logger``: If you want the messages to be logged to a particular logger. If
  you don't pass a logger then the class will create one.

The ``create`` method, that returns the client object, also takes optional arguments,
which define connection re-try behaviour:

* ``max_attempts``: Sets the maximum number of reconnection attempts in
  response to server errors.
* ``wait_strategy``: Determines the strategy for wait intervals between
  reconnection attempts. Options are:

  * ``:constant`` - Maintains a consistent wait time specified by ``wait_time``.
  * ``:geometric`` - Increases the wait time geometrically based on ``wait_time``.

* ``wait_time``: Specifies the base wait time (in seconds) for the chosen
  ``wait_strategy``.
