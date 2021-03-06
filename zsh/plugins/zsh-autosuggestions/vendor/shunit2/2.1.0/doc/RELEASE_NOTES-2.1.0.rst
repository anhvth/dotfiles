Release Notes for shUnit2 2.1.0
===============================

This release was branched from shUnit2 2.0.1. It mostly adds new functionality,
but there are couple of bugs fixed from the previous release.

See the ``CHANGES-2.1.rst`` file for a full list of changes.


Tested Platforms
----------------

This list of platforms comes from the latest version of log4sh as shUnit2 is
used in the testing of log4sh on each of these platforms.

Cygwin

- bash 3.2.9(10)
- pdksh 5.2.14

Linux

- bash 3.1.17(1), 3.2.10(1)
- dash 0.5.3
- ksh 1993-12-28
- pdksh 5.2.14
- zsh 4.3.2 (does not work)

Mac OS X 1.4.8 (Darwin 8.8)

- bash 2.05b.0(1)
- ksh 1993-12-28

Solaris 8 U3 (x86)

- /bin/sh
- bash 2.03.0(1)
- ksh M-11/16/88i

Solaris 10 U2 (sparc)

- /bin/sh
- bash 3.00.16(1)
- ksh M-11/16/88i

Solaris 10 U2 (x86)

- /bin/sh
- bash 3.00.16(1)
- ksh M-11/16/88i


New Features
------------

Test skipping

  Support added for test "skipping". A skip mode can be enabled so that
  subsequent ``assert`` and ``fail`` functions that are called will be recorded
  as "skipped" rather than as "passed" or "failed". This functionality can be
  used such that when a set of tests makes sense on one platform but not on
  another, they can be effectively disabled without altering the total number
  of tests.

  One example might be when something is supported under ``bash``, but not
  under a standard Bourne shell.

  New functions: ``startSkipping()``, ``endSkipping``, ``isSkipping``


Changes and Enhancements
------------------------

Moving to the use of `reStructured Text
<http://docutils.sourceforge.net/rst.html>`_ for documentation. It is easy to
read and edit in textual form, but converts nicely to HTML.

The report format has changed. Rather than including a simple "success"
percentage at the end, a percentage is given for each type of test.


Bug Fixes
---------

The ``fail()`` function did not output the optional failure message.

Fixed the ``Makefile`` so that the DocBook XML and XSLT files would be
downloaded before documentation parsing will continue.


Deprecated Features
-------------------

None.


Known Bugs and Issues
---------------------

None.


.. $Revision$
.. vim:spell
