-module(rxpxct_ffi).

-export([get/2]).

get(Array, Index) ->
    case catch array:get(Index, Array) of
        {'EXIT', _} -> {error, nil};
        E -> {ok, E}
    end.
