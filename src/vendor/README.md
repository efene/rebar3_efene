# Vendored sub-plugins

`rebar3_efene` is an umbrella plugin that previously pulled three separate hex
packages — `rebar3_efene_compile`, `rebar3_efene_ct`, `rebar3_efene_shell` —
each of which transitively depended on `efene`. Those packages are unmaintained
and do not build cleanly on modern OTP, so their single source modules are
vendored here and compiled as part of `rebar3_efene`. `src/rebar3_efene.erl`
still calls each module's `init/1` to register the providers.

The only remaining dependency is `efene` itself (declared in `rebar.config`),
which the compile provider drives. It is fetched from hex (>= 0.99.3, the
modernized release that vendors aleppo + ast_walk and builds cleanly on current
OTP).

## Sources / licenses (all Apache-2.0, by the efene authors)

- `rebar3_efene_compile.erl` — hex `rebar3_efene_compile` 0.1.9, unmodified.
- `rebar3_efene_ct.erl` — hex `rebar3_efene_ct` 0.1.2, unmodified.
- `rebar3_efene_shell.erl` — hex `rebar3_efene_shell` 0.1.2, with three patches:
  the two `erlang:get_stacktrace/0` calls (removed in OTP 24) now use the modern
  `catch Class:Reason:Stack` syntax; the two legacy `catch Expr` expressions
  (deprecated in OTP 29) use `try ... catch`; and the shell startup now picks
  between the old `tty_sl`/`user_drv` path (OTP < 26) and
  `shell:start_interactive/1` (OTP >= 26, after the IO system rewrite), so
  `rebar3 efene shell` no longer crashes on modern OTP.
