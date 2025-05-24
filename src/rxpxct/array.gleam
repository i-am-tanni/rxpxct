//// A module wrapper for creating and reading from zero-based arrays.
//// 

pub type Array(a) {
  Array(a)
}

@external(erlang, "array", "from_list")
pub fn from_list(list: List(a)) -> Array(a)

@external(erlang, "rxpxct_ffi", "get")
pub fn get(array: Array(a), index: Int) -> Result(a, Nil)
