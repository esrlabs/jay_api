Examples
========

Fetching Data using Index, QueryBuilder and QueryResults
---------------------------------------------------------

.. code-block:: ruby

   # Creating a query that searches for persons named Klaus and are 45 age old
   # and sorts the finding by their height and give back 5 items
   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.query.bool.must do |bool_clause|
     bool_clause.query_string(fields: 'name', query: 'Klaus')
     bool_clause.query_string(fields: 'age', query: 45)
   end
   query_builder.sort('height').size(5)

   # Use the ClientFactory class to get an Elasticsearch Client to use with the
   # index
   client = JayAPI::Elasticsearch::ClientFactory.new(
     cluster_url: 'https://elasticsearch.com',
     port: 456
   ).create

   # Creating an Index object with the client
   index = JayAPI::Elasticsearch::Index.new(
     client: client, index_name: 'myjob_index'
   )

   # Search for data using the constructed query on the ES server
   results = index.search(query_builder.to_query)

Adding aggregations to Elasticsearch queries
--------------------------------------------

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.query.query_string(fields: 'build_job_name', query: 'Release-master')
   query_builder.size(0)
   #                  ^
   #                  0 causes Elasticsearch to return only the aggregations (no documents)

   query_builder.aggregations.avg('avg_runtime', field: 'test_case.runtime')
   #                               ^^^^^^^^^^^           ^^^^^^^^^^^^^^^^^
   #                            aggregation name         field to aggregate

   results = index.search(query_builder.to_query)
   results.aggregations # => {"avg_runtime"=>{"value"=>269.36}}

Fetching Build Properties using the PropertiesFetcher
-----------------------------------------------------

.. code-block:: ruby

   # Proper initialization of a PropertiesFetcher object
   fetcher = JayAPI::PropertiesFetcher.new(index: index)

    # Fetches the latest build from the given Job
    result = fetcher.by_build_job('Release-XYX01-Master').last
    # => {"_index" => "xyz01_build_properties", "_type" => "nested", ... }

    # Fetches a specific build given job name and number
    result = fetcher.by_build_job('Release-XYX01-Master').and.by_build_number(100).first
    # => {"_index" => "xyz01_build_properties", "_type" => "nested", ... }

    # Fetches builds marked with the provided software version
    result = fetcher.by_software_version('D300').limit(10).all
    # => #<Enumerator: ...>

    # Fetches release builds from a given job
    result = fetcher.by_build_job('Release-XYX01-Master').and.by_release_tag(true).all
    # => #<Enumerator: ...>
