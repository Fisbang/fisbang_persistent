-module(fisbang_persistent_worker).
-include("_build/default/lib/amqp_client/include/amqp_client.hrl").

-export([start_service/0]).

start_service() ->
    {ok, spawn_link(fun init/0)}.

init() ->
    {ok, MongoConnection} = mc_worker_api:connect ([{database, <<"fisbang">>}]),
    {ok, Connection} = amqp_connection:start(#amqp_params_network{}),
    {ok, Channel} = amqp_connection:open_channel(Connection),
    amqp_channel:call(Channel, #'queue.declare'{queue = <<"hello">>}),
    amqp_channel:call(Channel, #'queue.bind'{queue = <<"hello">>, exchange = <<"amq.topic">>, routing_key = <<".#">>}),
    io:format(" [*] Waiting for messages. To exit press CTRL+C~n"),
    amqp_channel:subscribe(Channel, #'basic.consume'{queue = <<"hello">>, no_ack = true}, self()),
    receive
        #'basic.consume_ok'{} -> ok
    end,
    loop(MongoConnection, Connection, Channel).

loop(MongoConnection, Connection, Channel) ->
    receive
        {#'basic.deliver'{}, #amqp_msg{payload = Body}} ->
            io:format(" [~p] Received ~p~n", [self(), Body]),
            if Body =:= <<"stop">> -> 
                    amqp_connection:close(Connection),
                    ok;
               true -> 
                    Timestamp = get_timestamp(),
                    mc_worker_api:insert(MongoConnection, <<"sensor_data">>, [ #{<<"time">> => Timestamp, <<"data">> => Body} ]),
                    loop(MongoConnection, Connection, Channel)
            end
            %% loop(Channel)
    end.

get_timestamp() ->
  {Mega, Sec, Micro} = os:timestamp(),
  (Mega*1000000 + Sec)*1000 + round(Micro/1000).
