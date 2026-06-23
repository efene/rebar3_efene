-module(rebar3_efene_compile).
-behaviour(provider).

-export([init/1, do/1, format_error/1]).
% for rebar3_efene_ct
-export([do/3]).

%-include_lib("rebar3/include/rebar.hrl").
-include_lib("kernel/include/file.hrl").

-define(PROVIDER, compile).
-define(DEPS, [{default, install_deps}, {default, app_discovery}]).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
            {name, ?PROVIDER},          % The 'user friendly' name of the task
            {module, ?MODULE},          % The module implementation of the task
            {namespace, efene},
            {bare, false},
            {deps, ?DEPS},              % The list of dependencies
            {example, "rebar efene compile"}, % How to use the plugin
            % list of options understood by the plugin
            {opts, [{format, undefined, "format", string, help(format)},
                    {file, undefined, "file", string, help(file)}]},
            {short_desc, "efene rebar3 plugin"},
            {desc, ""}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.


-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    do(State, "src", fun rebar_app_info:ebin_dir/1).

do(State, SourceDirName, GetTargetDirFn) ->
    DepsPaths = rebar_state:code_paths(State, all_deps),
    %PluginDepsPaths = rebar_state:code_paths(State, all_plugin_deps),
    %rebar_utils:remove_from_code_path(PluginDepsPaths),
    code:add_pathsa(DepsPaths),

    {RawOpts, _} = rebar_state:command_parsed_args(State) ,
    Format = proplists:get_value(format, RawOpts, "beam"),
    case proplists:get_value(file, RawOpts, undefined) of
        undefined -> compile_all(State, Format, SourceDirName, GetTargetDirFn);
        FilePath -> compile_file(State, FilePath, Format, GetTargetDirFn)
    end.

compile_file(State, Path, Format, GetTargetDirFn) ->
    AppInfo = case rebar_state:current_app(State) of
               undefined -> hd(rebar_state:project_apps(State));
               AppInfo0 -> AppInfo0
           end,
    TargetDir = GetTargetDirFn(AppInfo),
    ErlOpts = rebar_state:get(State, erl_opts, []),
    rebar_api:info("Compiling ~s", [Path]),
    compile(Format, Path, TargetDir, ErlOpts),
    {ok, State}.

compile_all(State, Format, SourceDirName, GetTargetDirFn) ->
    Apps = case rebar_state:current_app(State) of
               undefined -> rebar_state:project_apps(State);
               AppInfo -> [AppInfo]
           end,

    FirstFiles = [],
    SourceExt = ".fn",
    TargetExt = "." ++ Format,

    [begin
         Opts = rebar_app_info:opts(AppInfo),
         TargetDir = GetTargetDirFn(AppInfo),
         SourceDir = filename:join(rebar_app_info:dir(AppInfo), SourceDirName),

         CompileFun = fun(Source, Target, Opts1) ->
                              ErlOpts = rebar_opts:erl_opts(Opts1),
                              compile_source(ErlOpts, Source, Target, Format)
                      end,

         rebar_base_compiler:run(Opts, FirstFiles, SourceDir, SourceExt,
                                 TargetDir, TargetExt, CompileFun, [])
     end || AppInfo <- Apps],

    {ok, State}.

-spec format_error(any()) ->  iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%% ===================================================================
%% Private API
%% ===================================================================

get_destpath(Path, DestDirPath, Ext) ->
    BaseName = filename:basename(Path, ".fn"),
    DestName = BaseName ++ "." ++ Ext,
    DestPath = filename:join(DestDirPath, DestName),
    rebar_api:info("writing to ~s", [DestPath]),
    DestPath.

write_terms_to_file(Term, DestPath) ->
    {ok, Handle} = file:open(DestPath, [write]),
    io:format(Handle, "~p~n", [Term]),
    file:close(Handle).

compile(Ext="rawlex", Path, DestDirPath, _ErlOpts) ->
    DestPath = get_destpath(Path, DestDirPath, Ext),
    write_terms_to_file(efene:to_raw_lex(Path), DestPath);
compile(Ext="lex", Path, DestDirPath, _ErlOpts) ->
    DestPath = get_destpath(Path, DestDirPath, Ext),
    write_terms_to_file(efene:to_lex(Path), DestPath);
compile(Ext="ast", Path, DestDirPath, _ErlOpts) ->
    DestPath = get_destpath(Path, DestDirPath, Ext),
    write_terms_to_file(efene:to_ast(Path), DestPath);
compile(Ext="mod", Path, DestDirPath, _ErlOpts) ->
    DestPath = get_destpath(Path, DestDirPath, Ext),
    write_terms_to_file(efene:to_mod(Path), DestPath);
compile(Ext="erl", Path, DestDirPath, _ErlOpts) ->
    DestPath = get_destpath(Path, DestDirPath, Ext),
    file:write_file(DestPath, efene:to_erl(Path));
compile(Ext="erlast", Path, DestDirPath, _ErlOpts) ->
    DestPath = get_destpath(Path, DestDirPath, Ext),
    case efene:to_erl_ast(Path) of
        {ok, {Ast, _State}} ->
            write_terms_to_file(Ast, DestPath);
        Other ->
            rebar_api:error("Unknown result: ~p", [Other])
    end;
compile("beam", Path, DestPath, ErlOpts) ->
    case efene:compile(Path, DestPath, ErlOpts) of
        {error, _}=Error ->
            FmtErrors = [fn_error:normalize(Error)],
            {error, FmtErrors, []};
        {error, Errors, Warnings} ->
            FmtErrors = [fn_error:normalize(Error) || Error  <- Errors],
            FmtWarnings = [fn_error:normalize(Warn) || Warn  <- Warnings],
            {error, FmtErrors, FmtWarnings};
        {ok, CompileInfo} ->
            Warnings = proplists:get_value(warnings, CompileInfo, []),
            FmtWarnings = [fn_error:normalize(Warn) || Warn  <- Warnings],
            {ok, FmtWarnings};
        Other ->
            {error, [io_lib:format("Unknown result: ~p", [Other])], []}
    end;
compile(Format, _Path, _DestPath, _ErlOpts) ->
    rebar_api:error("Invalid format: ~s", [Format]).

compile_source(ErlOpts, Source, DestPath, Format) ->
    {ok, SourceFileInfo} = file:read_file_info(Source),
    NeedsCompile = case file:read_file_info(DestPath) of
                       {ok, DestFileInfo} ->
                           #file_info{mtime=SourceMTime}=SourceFileInfo,
                           #file_info{mtime=DestMTime}=DestFileInfo,
                           SourceMSecs = calendar:datetime_to_gregorian_seconds(SourceMTime),
                           DestMSecs = calendar:datetime_to_gregorian_seconds(DestMTime),
                           SourceMSecs =/= DestMSecs;
                       {error, _} ->
                           true
                   end,
    ok = filelib:ensure_dir(DestPath),
    if NeedsCompile ->
            rebar_api:info("Compiling ~s", [Source]),
            compile(Format, Source, filename:dirname(DestPath), ErlOpts);
       true ->
            rebar_api:info("Skipping  ~s", [Source])
    end.

help(format) -> "format to compile code to, one of rawlex, lex, ast, mod, erlast, erl, beam";
help(file) -> "file to compile, if omited all files in the project are compiled".
