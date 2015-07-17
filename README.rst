Vessel
======
Vessel is a native application used to setup and manage development environments
using Vagrant and Docker.

|Gitter|

Development
-----------
To get started, make sure you have npm and grunt-cli installed.

.. code-block:: bash

  # Install the dependencies
  npm install

  # Get the atom-shell structure in place
  grunt setup

  # Compile and run interactively
  grunt compile && grunt run

Distribution
------------
To create a distributable app that has all of the required dependencies, use the
`grunt build` job:

.. code:: bash

    grunt build

This will create a zipfile in the root of the application with a distributable
version of the application.

.. |Gitter| image:: https://badges.gitter.im/Join Chat.svg
   :target: https://gitter.im/awvessel/vessel?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
