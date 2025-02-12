Module Description
==================

JayAPI provides a functionality to manage configuration. There are helper
methods that convert YAML files, strings or Hash objects into
JayAPI::Configuration objects.

An example of usage

.. code-block:: ruby

    some_hash = {
      one: {
        two: 3
      }
    }

    some_config = JayAPI::Configuration.from_hash(some_hash)
    some_config.one.two # ==> 3

* :doc:`merging`
