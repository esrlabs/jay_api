Indexes
=======

.. note::

   This class includes the :doc:`../indexable` mixin. It exposes all its methods.

This class represents a set of indexes in an elasticsearch cluster. It provides
a set of methods that allow the user to query the indexes or add new data to
all of them at the same time.

The class works exactly as :doc:`index`. It only differs in the fact that it can
be initialized with multiple ``index_names`` and not only one, like ``Index``.

Initializing
------------

Just like with ``Index`` you need an instance of ``Elasticsearch::Client``. You
can use the ``ClientFactory`` to get one:

.. code-block:: ruby

   require 'jay_api/elasticsearch/client_factory'

   client = JayAPI::Elasticsearch::ClientFactory.new(
     cluster_url: 'https://my-cluster.elastic.io'
   ).create

Then you can use the client to initialize the ``Indexes`` class:

.. code-block:: ruby

   require 'jay_api/elasticsearch/indexes'

   indexes = JayAPI::Elasticsearch::Indexes.new(
     client: client, index_names: %w[my_index my_other_index not_my_index]
   )

The following arguments are available for the ``#initialize`` method:

* ``client``: An instance of ``Elasticsearch::Client``. You can get one using
  the ``Elasticsearch::ClientFactory`` class.
* ``index_names``: An ``Array`` of ``String``. The names of the indexes you
  want to work with.
* ``batch_size``: The number of documents the ``Indexes`` class will store in
  its buffer before triggering a ``#flush`` call when the ``#push`` method is
  used to add data. The default is: 100.
* ``logger``: A ``Logger`` object used to log messages. If none is given the
  ``Indexes`` object will create one of its own.

.. warning::

   When the ``batch_size`` isn't a multiple of the number of elements in the
   ``index_names`` array there is a chance that the size of the batches sent to
   the Elasticsearch could be bigger than ``batch_size``. This can be avoided
   simply by choosing an integer multiple of the array's size.

#index_names
------------

This method returns the array of index names used to initialize the ``Indexes``
object.

.. warning::

   Unlike ``Index``, ``Indexes`` objects **DO NOT** respond to the
   ``#index_name`` message.
