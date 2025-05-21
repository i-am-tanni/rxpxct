-module(rxpxct_ffi).

-export([get/2, from_list/1]).

get(Array, Index) ->
    case catch array:get(Index, Array) of
        {'EXIT', _} -> {error, nil};
        E -> {ok, E}
    end.

from_list(List) ->
    array:from_list(List).
