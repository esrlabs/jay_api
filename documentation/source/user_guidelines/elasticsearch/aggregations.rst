Aggregations
============

The :doc:`query_builder` class has an ``aggregations`` method which allows you
to add aggregations to the query. This page explains how this method can be
used.

The ``aggregations`` method returns an instance of the ``Aggregations`` class,
therefore this class's method can be chained after the ``aggregations`` call.
Please check the examples provided below to get an idea of how this works.

terms
-----

This is a bucket-type aggregation which can count the number of individual
values in a field. Detailed information on how to use this type of aggregation
can be found on `Elasticsearch's documentation on the Terms aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.terms('genres', field: 'genre')

This would produce the following query:

.. code-block:: json

   {
     "query": {
       "match_all": { }
     },
     "aggs": {
       "genres": {
         "terms": {
           "field": "genre"
         }
       }
     }
   }

avg
---

This is a single-value aggregation that calculates the average value of a field
among all the matched documents.  Detailed information on how to use this type
of aggregation can be found on `Elasticsearch's documentation on the Avg aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.avg('avg_grade', field: 'grade')

This would produce the following query:

.. code-block:: json

   {
     "query": {
       "match_all": {
       }
     },
     "aggs": {
       "avg_grade": {
         "avg": {
           "field": "grade"
         }
       }
     }
   }

sum
---

This is a single-value aggregation that calculates the sum of the values in the
specified field through all the matched documents. Detailed information on how
to use this type of aggregation can be found on
`Elasticsearch's documentation on the Sum aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.query.term(field: 'type', value: 'hat')
   query_builder.aggregations.sum('hat_prices', field: 'price')

This would produce the following query:

.. code-block:: json

   {
     "query": {
       "term": {
         "type": {
           "value": "hat"
         }
       }
     },
     "aggs": {
       "hat_prices": {
         "sum": {
           "field": "price"
         }
       }
     }
   }

max
---

This is a single-value aggregation that calculates the maximum value in the
specified field among all matched documents. Detailed information on how to use
this type of aggregation can be found on `Elasticsearch's documentation on the Max aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.max('max_price', field: 'price')

This would produce the following query:

.. code-block:: json

   {
     "query": {
       "match_all": { }
     },
     "aggs": {
       "max_price": {
         "max": {
           "field": "price"
         }
       }
     }
   }

.. _`Elasticsearch's documentation on the Max aggregation`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-max-aggregation.html

value_count
-----------

This is a single-value aggregation that calculates the number of non-null values
in the specified field through all the matched documents. Detailed information
on how to use this type of aggregation can be found on
`Elasticsearch's documentation on the Value Count aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.value_count('types_count', field: 'type')

This would produce the following query:

.. code-block:: json

   {
     "query": {
       "match_all": { }
     },
     "aggs": {
       "types_count": {
         "value_count": { "field": "type" }
       }
     }
   }

filter
------

This is a single bucket aggregation that filters the set of documents using a
query to narrow it down. It is normally used in conjunction with other
aggregations to create break downs of the whole data set. Detailed information
on how to use this type of aggregation can be found on
`Elasticsearch's documentation on the Filter aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.avg('overall_avg_price', field: 'price')
   query_builder.aggregations.filter('t_shirts') do |query|
     query.term(field: 'type', value: 't-shirt')
   end.aggs do |aggs|
     aggs.avg('avg_price', field: 'price')
   end

This would generate the following query:

.. code-block:: json

   {
     "query": { "match_all": {} },
     "aggs": {
       "overall_avg_price": { "avg": { "field": "price" } },
       "t_shirts": {
         "filter": { "term": { "type": { "value": "t-shirt" } } },
         "aggs": {
           "avg_price": { "avg": { "field": "price" } }
         }
       }
     }
   }

cardinality
-----------

This is a single-value aggregation that counts the **approximate** number of
unique values that a field has in the index.

Detailed information on how to use this type of aggregation can be found on
`Elasticsearch's documentation on the Cardinality aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.sum('type_count', field: 'type')

This would produce the following query:

.. code-block:: json

   {
     "query": { "match_all": {} },
     "aggs": {
       "type_count": {
         "cardinality": {
           "field": "type"
         }
       }
     }
   }

date_histogram
--------------

This is a multi-bucket aggregation that automatically aggregates the documents
into buckets of a fixed time length. As its name indicates it is normally used
to create date-based histograms, for example, for graphs.

Detailed information on how to use this type of aggregation can be found on
`Elasticsearch's documentation on the Date Histogram aggregation`_

This aggregation is normally used in combination with sub-aggregations to get
more meaningful values than just the number of documents.

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.date_histogram('sales_over_time', field: 'date', calendar_interval: 'month')

This would produce the following query:

.. code-block:: json

   {
     "query": { "match_all": {} },
     "aggs": {
       "sales_over_time": {
         "date_histogram": {
           "field": "date",
           "calendar_interval": "month"
         }
       }
     }
   }

scripted_metric
---------------

This is a special type of single-value aggregation which can be used to build
custom aggregations that return a single value. This type of aggregation takes
a set of `Painless`_ scripts and returns a single value which can be a single
number an array or even a map.

Detailed information on how to use this type of aggregation can be found on
`Elasticsearch's documentation on the Scripted Metric aggregation`_

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.scripted_metric(
     'profit',
     init_script: 'state.transactions = []',
     map_script: "state.transactions.add(doc.type.value == 'sale' ? doc.amount.value : -1 * doc.amount.value)",
     combine_script: 'double profit = 0; for (t in state.transactions) { profit += t } return profit',
     reduce_script: 'double profit = 0; for (a in states) { profit += a } return profit'
   )

The ``init_script`` is optional, the rest of the scripts are required.

The code above would produce the following query:

.. code-block:: json

   {
     "query": {
       "match_all": {
       }
     },
     "aggs": {
       "profit": {
         "scripted_metric": {
           "init_script": "state.transactions = []",
           "map_script": "state.transactions.add(doc.type.value == 'sale' ? doc.amount.value : -1 * doc.amount.value)",
           "combine_script": "double profit = 0; for (t in state.transactions) { profit += t } return profit",
           "reduce_script": "double profit = 0; for (a in states) { profit += a } return profit"
         }
       }
     }
   }

.. warning::

   These scripts **must** be simple strings, they do not follow the pattern of
   other scripted elements in Elasticsearch's DSL. Do not use
   ``QueryBuilder::Script`` objects here. Their use will produce unintended
   results.

composite
---------

This is a multi-bucket aggregation that aggregates the set of documents using a
compound value made out of all the existing combinations of values from the
specified sources. Currently Jay API only allows one type of source: ``terms``.

Using the ``terms`` source it is possible to create a bucket for each existing
combination of values from a set of fields.

Detailed information on how to use this type of aggregation can be found on
`Elasticsearch's documentation on the Composite aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.aggregations.composite('products_by_brand') do |sources|
     sources.terms('product', field: 'product.name')
     sources.terms('brand', field: 'brand.name')
   end

This would generate the following query:

.. code-block:: json

   {
     "query": {
       "match_all": {}
     },
     "aggs": {
       "products_by_brand": {
         "composite": {
           "sources": [
             { "product": { "terms": { "field": "product.name" } } },
             { "brand": { "terms": { "field": "brand.name" } } }
           ]
         }
       }
     }
   }

This will create one bucket for each existing combination of ``product.name``
and ``brand.name`` in the index. The buckets will only say how many documents
(``doc_count``) exist for each combination. Nested aggregations could be added
to get other information out of the documents in each bucket.

bucket_selector
---------------

This is a pipeline aggregation that can select (or filter out, depending on how
you see it) some of the buckets produced by a multi-bucket aggregation.

Detailed information on how to use this aggregation can be found on
`Elasticsearch's documentation on the Bucket Selector aggregation`_

Code example:

.. code-block:: ruby

   query_builder = JayAPI::Elasticsearch::QueryBuilder.new
   query_builder.size(0)
   query_builder.aggregations.date_histogram('sales_per_month', field: 'date', calendar_interval: 'month').aggs do |aggs|
     aggs.sum('total_sales', field: 'price')
     aggs.bucket_selector(
       'sales_bucket_filter', buckets_path: { totalSales: 'total_sales' },
                              script: JayAPI::Elasticsearch::QueryBuilder::Script.new(source: 'params.totalSales > 200')
     )
   end

This would generate the following query:

.. code-block:: json

   {
     "size": 0,
     "query": {
       "match_all": {}
     },
     "aggs": {
       "sales_per_month": {
         "date_histogram": {
           "field": "date",
           "calendar_interval": "month"
         },
         "aggs": {
           "total_sales": {
             "sum": {
               "field": "price"
             }
           },
           "sales_bucket_filter": {
             "bucket_selector": {
               "buckets_path": {
                 "totalSales": "total_sales"
               },
               "script": {
                 "source": "params.totalSales > 200",
                 "lang": "painless"
               }
             }
           }
         }
       }
     }
   }

This query tells Elasticsearch to create a Date Histogram divided by month.
In each of the buckets of the histogram it uses a Sum aggregation to calculate
the total sales amount for that month, finally the bucket_selector aggregation
picks only the buckets that have ``total_sales`` greater than 200.

Note that the Bucket Selector aggregation is a sibling of the ``sum``
aggregation and **NOT** a nested aggregation, which ``sum`` cannot have.

Also, note that the ``buckets_path`` expression is just ``total_sales``. This
works because ``sum`` is a single-value aggregation. The syntax would need to
be different if the filtering was happening on a multi-bucket / multi-value
aggregation. Please see `Elasticsearch's documentation for buckets_path`_.

.. _`Elasticsearch's documentation on the Terms aggregation`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html
.. _`Elasticsearch's documentation on the Avg aggregation`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-avg-aggregation.html
.. _`Elasticsearch's documentation on the Sum aggregation`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-sum-aggregation.html
.. _`Elasticsearch's documentation on the Value Count aggregation`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-valuecount-aggregation.html
.. _`Elasticsearch's documentation on the Filter aggregation`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-filter-aggregation.html
.. _`Elasticsearch's documentation on the Cardinality aggregation`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-cardinality-aggregation.html
.. _`Elasticsearch's documentation on the Date Histogram aggregation`: https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-datehistogram-aggregation
.. _`Elasticsearch's documentation on the Scripted Metric aggregation`: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-scripted-metric-aggregation.html
.. _`Elasticsearch's documentation on the Composite aggregation`: https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-composite-aggregation
.. _`Elasticsearch's documentation on the Bucket Selector aggregation`: https://www.elastic.co/docs/reference/aggregations/search-aggregations-pipeline-bucket-selector-aggregation
.. _`Elasticsearch's documentation for buckets_path`: https://www.elastic.co/docs/reference/aggregations/pipeline#buckets-path-syntax
.. _`Painless`: https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-scripting-painless.html
