-module(rebar3_efene).

-export([init/1]).

init(State) ->
    {ok, State1} = rebar3_efene_compile:init(State),
    {ok, State2} = rebar3_efene_ct:init(State1),
    rebar3_efene_shell:init(State2).
