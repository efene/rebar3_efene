-module(rebar3_efene_fmt).
-behaviour(provider).

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, fmt).
-define(DEPS, [{default, app_discovery}]).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
            {name, ?PROVIDER},
            {module, ?MODULE},
            {namespace, efene},
            {bare, false},
            {deps, ?DEPS},
            {example, "rebar3 efene fmt"},
            {opts, [{file,  undefined, "file",  string,  help(file)},
                    {write, $w,        "write", boolean, help(write)},
                    {check, $c,        "check", boolean, help(check)}]},
            {short_desc, "format efene source code"},
            {desc, "Pretty-print efene source files. By default the formatted "
                   "source is printed to stdout; --write rewrites files in "
                   "place; --check verifies formatting without writing."}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    DepsPaths = rebar_state:code_paths(State, all_deps),
    code:add_pathsa(DepsPaths),

    {RawOpts, _} = rebar_state:command_parsed_args(State),
    Mode = mode(RawOpts),
    Files = case proplists:get_value(file, RawOpts, undefined) of
                undefined -> project_fn_files(State);
                FilePath -> [FilePath]
            end,
    Unformatted = lists:foldl(fun (Path, Acc) ->
                                      case fmt_file(Path, Mode) of
                                          changed -> [Path | Acc];
                                          _ -> Acc
                                      end
                              end, [], Files),
    case {Mode, lists:reverse(Unformatted)} of
        {check, []} -> {ok, State};
        {check, Bad} -> {error, {?MODULE, {unformatted, Bad}}};
        {_, _} -> {ok, State}
    end.

-spec format_error(any()) -> iolist().
format_error({unformatted, Files}) ->
    io_lib:format("the following files are not formatted:~n~s",
                  [[io_lib:format("  ~s~n", [F]) || F <- Files]]);
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%% ===================================================================
%% Private API
%% ===================================================================

mode(RawOpts) ->
    case proplists:get_value(check, RawOpts, false) of
        true -> check;
        false ->
            case proplists:get_value(write, RawOpts, false) of
                true -> write;
                false -> stdout
            end
    end.

project_fn_files(State) ->
    Apps = case rebar_state:current_app(State) of
               undefined -> rebar_state:project_apps(State);
               AppInfo -> [AppInfo]
           end,
    lists:flatmap(fun (App) ->
                          SourceDir = filename:join(rebar_app_info:dir(App), "src"),
                          filelib:wildcard(filename:join(SourceDir, "**/*.fn"))
                  end, Apps).

%% returns: ok | changed | error
fmt_file(Path, Mode) ->
    case format_one(Path) of
        {ok, Formatted} ->
            handle(Mode, Path, Formatted);
        {error, Error} ->
            rebar_api:error("~s: ~s", [Path, fn_error:normalize(Error)]),
            error
    end.

format_one(Path) ->
    case efene:to_efene(Path) of
        Result when is_list(Result) -> {ok, Result};
        Error -> {error, Error}
    end.

handle(stdout, _Path, Formatted) ->
    io:format("~s~n", [Formatted]),
    ok;
handle(write, Path, Formatted) ->
    rebar_api:info("Formatting ~s", [Path]),
    ok = file:write_file(Path, [Formatted, $\n]),
    ok;
handle(check, Path, Formatted) ->
    case file:read_file(Path) of
        {ok, Current} ->
            case normalize(Current) =:= normalize(Formatted) of
                true ->
                    ok;
                false ->
                    rebar_api:warn("~s is not formatted", [Path]),
                    changed
            end;
        {error, Reason} ->
            rebar_api:error("~s: ~p", [Path, Reason]),
            error
    end.

%% compare ignoring a single trailing newline so the stdout/write trailing
%% newline doesn't cause spurious mismatches in check mode
normalize(IoData) ->
    string:trim(iolist_to_binary(IoData), trailing, "\n").

help(file)  -> "file to format, if omitted all .fn files in the project are formatted";
help(write) -> "rewrite the formatted source back to the file in place";
help(check) -> "check formatting without writing; exit non-zero if any file would change".
