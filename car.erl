-module(cars).
-behaviour(gen_statem).

-export([stop/0, start/0, start_link/0]).
-export([init/1, callback_mode/0, handle_event/4, terminate/3, code_change/4]).
-export([turn_on/1, turn_off/1, to_park/1, to_reverse/1, to_neutral/1, to_drive/1, to_low/1]).

% manager things
-export([manager_start/0,add_handler/0,start_error_man/0]).
%callback fuctions for all commnads
%if command is stop, call the stop function
stop() ->
    gen_statem:stop(?MODULE).

start() ->
    gen_statem:start({local, ?MODULE}, ?MODULE, [], []).

start_link() ->
    gen_statem:start_link({local, ?MODULE}, ?MODULE, [], []).

% start event manager 
manager_start() ->
    gen_event:start({local, error_man}).

add_handler() ->
    gen_event:add_handler(error_man, terminal_logger, []).

start_error_man() ->
    gen_event:start({local, error_man}),
    gen_event:add_handler(error_man, terminal_logger, []).

init(_Args) ->
    {ok, {engine_off, parked}, []}.

% facade functions
turn_on(Car) ->
    gen_statem:call(Car, {engine_on, parked}). 

turn_off(Car) ->
    gen_statem:call(Car, {engine_off, parked}).

to_park(Car) -> 
    gen_statem:call(Car, {engine_on, parked}).

to_reverse(Car) ->
    gen_statem:call(Car, {engine_on, reverse}).

to_neutral(Car) ->
    gen_statem:call(Car, {engine_on, neutral}).

to_drive(Car) ->
    gen_statem:call(Car, {engine_on, drive}).

to_low(Car) ->
    gen_statem:call(Car, {engine_on, low}).

%% state_functions | handle_event_function 
callback_mode() ->
    handle_event_function.

% event for turning on car
handle_event({call, From}, to_on, engine_off, State_data) ->
    % io:format("turning car on"),
    gen_event:notify(error_man, "turning car on"),

    % changed State_data to {engine_on, State_data} for testing 
    {next_state, engine_on, {engine_on, State_data}, [{reply, From, engine_is_on}]};

%event-turn car off
handle_event({call, From}, to_off, engine_on, State_data) ->
    io:format("turning car off"),
    {next_state, engine_off, State_data, [{reply, From, engine_is_off}]};

%event-reverse to parked
handle_event({call, From}, to_park, reverse, State_data) ->
    io:format("going from reverse to parked state"),
    {next_state, parked, State_data, [{reply, From, is_in_parked}]};

%event-parked to reverse ie to_reverse
handle_event({call, From}, to_reverse, parked,  State_data) ->
    io:format("going from parked to reverse state"),
    {next_state, reverse, State_data, [{reply, From, is_in_reverse}]};

%event-neutral to reverse 
handle_event({call, From}, to_reverse, neutral, State_data) ->
    io:format("going from neutral to reverse state"),
    {next_state, reverse, State_data, [{reply, From, is_in_reverse}]};

%event-reverse to neutral
handle_event({call, From}, to_neutral, reverse,  State_data) ->
    io:format("going from reverse to neutral state"),
    {next_state, neutral,  State_data, [{reply, From, is_in_neutral}]};

%event-drive to neutral
handle_event({call, From}, to_neutral, drive, State_data) ->
    io:format("going from drive to neutral state"),
    {next_state, neutral, State_data, [{reply, From, is_in_neutral}]};

%event-neutral to drive
handle_event({call, From}, to_drive, neutral, State_data) ->
    io:format("going from neutral to drive state"),
    {next_state, drive, State_data, [{reply, From, is_in_drive}]};

%event-low to drive
handle_event({call, From}, to_drive, low, State_data) ->
    io:format("going from low to drive state"),
    {next_state, drive, State_data, [{reply, From, is_in_drive}]};

%event-drive to low
handle_event({call, From}, to_low, drive, State_data) ->
    io:format("going from drive to low state"),
    {next_state, low, State_data, [{reply, From, is_in_low}]};

% catch-all
handle_event({call,From},Attemped_state,Current_state,{_Statem_name,State_data}) ->
    io:format("Current state, ~p, does not allow a change to ~p state~n",[Current_state,Attemped_state]),
    {next_state,Current_state,{Current_state,State_data},[{reply,From,fail}]}.

terminate(_Reason, _State, _Data) ->
    ok.

code_change(_OldVsn, State, Data, _Extra) ->
    {ok, State, Data}.

%make unit tests
-ifdef(EUNIT).
-include_lib("eunit/include/eunit.hrl").

handle_event_test_() ->
    [
        ?_assertEqual({next_state, engine_on, {engine_on, engine_off}, [{reply, pid, engine_is_on}]},
        cars:handle_event({call, pid}, to_on, engine_off, {statem_name, engine_off})),

        ?_assertEqual({next_state, park, {parked, drive}, [{reply, pid, is_in_parked}]},
        cars:handle_event({call, pid}, to_parked, drive, {statem_name, is_in_drive}))
    ].


-endif.