%%%-------------------------------------------------------------------
%% @doc fisbang_persistent top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(fisbang_persistent_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
    ChildSpecs = [
                  {fisbang_persistent_worker_1,
                   {fisbang_persistent_worker, start_service, []},
                   permanent,
                   1000,
                   worker,
                   [fisbang_persistent_worker]},
                  {fisbang_persistent_worker_2,
                   {fisbang_persistent_worker, start_service, []},
                   permanent,
                   1000,
                   worker,
                   [fisbang_persistent_worker]}
                  ],

    {ok, { {one_for_one, 100, 1}, ChildSpecs} }.

%%====================================================================
%% Internal functions
%%====================================================================
