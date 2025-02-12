Merging
=======

One feature of JayAPI::Configuration is that it can be 'merged' with another
JayAPI::Configuration object. More precisely, merging in a 'selective' way,
which differs from the standard merge behaviour of Hash objects. Merging in
this case can be defined as follows:

If ``config_a`` and ``config_b`` are two JayAPI::Configuration objects, they
are merged like this:

.. code-block:: ruby

    require 'jay_api/mergeables/merge_selector' # Note that this must be required to add the merging functionality to JayAPI::Configuration

    config_a = config_a.with_merge_selector
    config_a.merge_select(config_b)

Merging Rules
*************

The merging will follow the following rules:

1. All nodes in ``config_b`` will completely overwrite nodes in ``config_a``
   (Just like the standard Hash merging behaviour).
   Example:

   .. code-block:: yaml

       # config_a
       one:
         two: 3

       # config_b
       one:
         two: 4

       # config_a.merge_select(config_b)
       one:
         two: 4 # <== note that the 'b' node overwrites the 'a' node.

2. All nodes in ``config_a`` that are not found in ``config_b`` will be ignored
   in the result.

   .. code-block:: yaml

       # config_a
       one: 1
       two: 2
       three: 3

       # config_b
       four: 4

       # config_a.merge_select(config_b)
       four: 4 # <= note that only the node from 'config_b' shows up in the result.

3. If a node value is 'nil' in ``config_b`` and the node matches a node in
   ``config_a`` then the matching node in ``config_a`` will be 'selected' to
   be in the result.

   .. code-block:: yaml

       # config_a
       one:
         two: 3

       # config_b
       one: ~ # The tilde is a YAML nil.

       # config_a.merge_select(config_b)
       one:
         two: 3 # <= note that config_b 'one: ~' acts as a 'selector' for everything under 'one:' in config_a.

.. note::

  Note that internally the Hashes are converted to HashWithIndifferentAccess
  objects. This means that for example { 'c' => 1 } will override a Hash like
  { c: 1 }, because it treats Symbols and Strings as the same entity.

Realistic Example
*****************

To see how this can realistically be used in some configuration, the following
examples can be studied:

``config_a``

.. code-block:: yaml
  :linenos:

  htmls:
    index:
      render_config:
        config: ~
      template_data:
        breadcrumbs: Start
    all_internal:
      overall:
        template_data:
          filter: { category: ['software', 'architecture', 'module'] }
          breadcrumbs: ['SWE Specs', 'Overall']
      off_target:
        template_data:
          filter: { test_setups: off_target, category: ['software', 'architecture', 'module'] }
          breadcrumbs: ['SWE Specs', 'Off Target']
      on_target:
        template_data:
          filter: { test_setups: on_target, category: ['software', 'architecture', 'module'] }
          breadcrumbs: ['SWE Specs', 'On Target']
      manual:
        template_data:
          filter: { test_setups: manual, category: ['software', 'architecture', 'module'] }
          breadcrumbs: ['SWE Specs', 'Manual']

``config_b``

.. code-block:: yaml
  :linenos:

  htmls:
    index: ~
    all_internal:
      overall:
        template_data: ~
        some_new: attribute
      off_target:
        template_data:
          breadcrumbs: ['New', 'Breadcrumbs']
      on_target: ~

``config_a.merge_select(config_b)``

.. code-block:: yaml
  :linenos:

  htmls:
  index:
    render_config:
      config: ~
    template_data:
      breadcrumbs: Start
  all_internal:
    overall:
      template_data:
        filter: { category: ['software', 'architecture', 'module'] }
        breadcrumbs: ['SWE Specs', 'Overall']
      some_new: attribute
    off_target:
      template_data:
        breadcrumbs: ['New', 'Breadcrumbs']
    on_target:
      template_data:
        filter: { test_setups: on_target, category: ['software', 'architecture', 'module'] }
        breadcrumbs: ['SWE Specs', 'On Target']

Notice:

* Due to rule number 3, notice that ``config_a`` entries belonging to
  'htmls -> index' (lines 3-6) are in the result, because the ``config_b``'s
  'htmls -> index' value is '~', in effect instructing a 'selection'.
* Due to rule number 1, notice that ``config_a``'s' 'htmls -> all_internal ->
  off_target -> template_data -> breacrumbs' (line 15) is overwritten by the
  corresponding new node value in ``config_b``.
* Due to rule number 2, notice that the 'htmls -> all_internal -> manual' node
  (lines 20-23) in ``config_a`` does not show up in the result, because
  ``config_b`` does not contain it.
