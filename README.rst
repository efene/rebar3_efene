rebar3_efene
============

A `rebar3 <https://rebar3.org>`_ plugin to compile, test and run
`efene <https://github.com/efene/efene>`_ code.

It bundles four providers under the ``efene`` namespace:

- ``rebar3 efene compile`` — compile ``.fn`` sources (to ``beam`` by default,
  or to ``rawlex``/``lex``/``ast``/``mod``/``erlast``/``erl`` with ``--format``)
- ``rebar3 efene ct`` — compile the ``.fn`` files under ``test/``
- ``rebar3 efene shell`` — start an efene shell with the project apps and deps
  in the path
- ``rebar3 efene fmt`` — format ``.fn`` sources (prints to stdout by default,
  ``--write`` rewrites in place, ``--check`` verifies formatting)

Use
---

Add the plugin to your ``rebar.config``::

    {plugins, [rebar3_efene]}.

Then compile the ``.fn`` files in your project::

    $ rebar3 efene compile

Compile a single file or pick an output format::

    $ rebar3 efene compile --file src/example.fn
    $ rebar3 efene compile --format erl

Format the ``.fn`` files in your project::

    $ rebar3 efene fmt               # print formatted source to stdout
    $ rebar3 efene fmt --write       # rewrite the files in place
    $ rebar3 efene fmt --check       # exit non-zero if any file would change
    $ rebar3 efene fmt --file src/example.fn

Build (this repo)
-----------------

::

    $ rebar3 compile

The ``rebar3_efene_compile``/``ct``/``shell``/``fmt`` providers are vendored
under ``src/vendor/`` (see ``src/vendor/README.md``); the only runtime dependency is
`efene <https://hex.pm/packages/efene>`_, fetched from hex.

Compatibility
-------------

Builds on Erlang/OTP 22 through 29. ``rebar3 efene shell`` uses the
``tty_sl``/``user_drv`` startup on OTP < 26 and ``shell:start_interactive/1`` on
OTP >= 26 (the rewritten IO system).
