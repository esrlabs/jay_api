Stats
=====

The ``Stats`` class gives you access to various statistics about the
Elasticsearch cluster. The class can be accessed by calling the ``#stats``
method on an instance of the ``Elasticsearch::Client`` class. For example:

.. code-block:: ruby

   require 'jay_api/elasticsearch/client_factory'

   client_factory = JayAPI::Elasticsearch::ClientFactory.new(...)
   client = client_factory.create

   stats = client.stats

The ``Stats`` class has the following methods:

#indices
--------

This method gives you access to index-related statistics. The method returns an
instance of the ``Stats::Indices`` class, which in turn allows you to access
information on each of the individual indices through these methods:

#all
++++

This method returns an ``Enumerator`` whose elements are ``Stats::Index``
objects, one for each of the indices on the cluster, including system indices.

#system
+++++++

This method returns an ``Enumerator`` whose elements are ``Stats::Index``
objects, one for each of the system indices on the cluster.

#user
+++++

This method returns an ``Enumerator`` whose elements are ``Stats::Index``
objects, one for each of the user-created indices on the cluster.

The ``Stats::Index`` objects have the following methods:

``#name``
  The name of the index.
