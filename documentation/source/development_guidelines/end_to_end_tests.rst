End-to-End Tests
================

The end-to-end tests located in `ci/end-to-end/` require a test Elasticsearch
server with dummy test data. This section outlines the steps to set up the
environment and run the tests effectively.

Setup and Test Execution
------------------------

1. Start the Elasticsearch Server:
   Before running the tests, ensure the Elasticsearch server is up and running.
   To start the server, use the following command:

   .. code-block:: bash

      bundle exec rake elasticsearch:start

   This will initiate the Elasticsearch server using Docker Compose.
   Allow a few seconds for the server to initialize.

2. Upload Test Data:
   After starting the server, upload the test data from all `.index` files.
   This step is essential to prepare the server for running the tests.

   .. code-block:: bash

      bundle exec rake elasticsearch:upload

3. Run the End-to-End Tests:
   With the Elasticsearch server and test data set up, execute the end-to-end
   tests:

   .. code-block:: bash

      bundle exec rspec spec/end-to-end/ --exclude-pattern=

Convenient Workflow
-------------------

For a more streamlined workflow, you can use the following task to start the
Elasticsearch server and upload test data consecutively:

.. code-block:: bash

   bundle exec rake elasticsearch:start_and_upload

This task will invoke the `elasticsearch:start` and `elasticsearch:upload`
tasks consecutively, ensuring that your server is up and running with the
required test data before running the tests.

Cleanup
-------

4. Stop the Elasticsearch Server:
   After completing the tests, shut down the Elasticsearch server using the
   following command:

   .. code-block:: bash

      bundle exec rake elasticsearch:stop

   This command will stop and remove the Docker containers associated with the
   test server.

By following these steps, you can successfully run and manage your end-to-end
tests in a controlled and organized manner.
