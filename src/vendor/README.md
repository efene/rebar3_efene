# Vendored sub-plugins

`rebar3_efene` is an umbrella plugin that previously pulled three separate hex
packages — `rebar3_efene_compile`, `rebar3_efene_ct`, `rebar3_efene_shell` —
each of which transitively depended on `efene`. Those packages are unmaintained
and do not build cleanly on modern OTP, so their single source modules are
vendored here and compiled as part of `rebar3_efene`. `src/rebar3_efene.erl`
still calls each module's `init/1` to register the providers.

The only remaining dependency is `efene` itself (declared in `rebar.config`),
which the compile provider drives. For local builds it is supplied through
rebar3's `_checkouts/efene` override (the fixed, self-contained efene in the
parent repository) — see the Dockerfile.

## Sources / licenses (all Apache-2.0, by the efene authors)

- `rebar3_efene_compile.erl` — hex `rebar3_efene_compile` 0.1.9, unmodified.
- `rebar3_efene_ct.erl` — hex `rebar3_efene_ct` 0.1.2, unmodified.
- `rebar3_efene_shell.erl` — hex `rebar3_efene_shell` 0.1.2. One patch: the two
  `erlang:get_stacktrace/0` calls (removed in OTP 24) were replaced with the
  modern `catch Class:Reason:Stack` syntax. The provider still uses the old
  `tty_sl`/`user_drv` shell startup, which was rewritten in OTP 26; that only
  affects `rebar3 efene shell` at runtime (it is guarded by a try/catch
  fallback) and is left for a later, dedicated update.
