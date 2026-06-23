-module(rebar3_efene_ct).
-behaviour(provider).

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, ct).
-define(DEPS, [{default, install_deps}, {default, app_discovery}]).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
            {name, ?PROVIDER},           % The 'user friendly' name of the task
            {module, ?MODULE},           % The module implementation of the task
            {namespace, efene},
            {bare, false},
            {deps, ?DEPS},               % The list of dependencies
            {example, "rebar efene ct"}, % How to use the plugin
            {opts, []},                  % list of options understood by the plugin
            {short_desc, "efene rebar3 common test plugin"},
            {desc, ""}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.


-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    GetTargetDirFn = fun (AppInfo) ->
         OutDir = rebar_app_info:out_dir(AppInfo),
         filename:join(OutDir, "test")
    end,
    rebar3_efene_compile:do(State, "test", GetTargetDirFn).

-spec format_error(any()) ->  iolist().
format_error(Reason) ->
    rebar3_efene_compile:format_error(Reason).
