Cluster
=======

The ``Cluster`` class gives you access to cluster-level endpoints in
Elasticsearch. The class can be accessed by calling the ``#cluster`` method on
an instance of the ``Elasticsearch::Client`` class. For example:

.. code-block:: ruby

   require 'jay_api/elasticsearch/client_factory'

   client_factory = JayAPI::Elasticsearch::ClientFactory.new(...)
   client = client_factory.create

   cluster = client.cluster

The ``Cluster`` class has the following method:

#health
-------

This method retrieves the cluster health data from the ``/_cluster/health``
endpoint and returns the response hash from Elasticsearch.
