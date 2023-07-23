defmodule RustlerInlineTest.Simple do
  @moduledoc """
  This will create elixir stubs and then links them to the rust nifs.any()
  
  The functions can then be called like normal Elixir functions:
  - add_one/1
  - sum_two/2
  - to_string_with_env/1
  """
  use RustlerInline, app: :rustler_inline

  rust """
  use rustler::Encoder;
  
  #[rustler::nif]
  /// nif: add_one/1
  fn add_one(val: i64) -> i64 {
    val + 1
  }
  
  #[rustler::nif]
  /// nif: sum_two/2
  fn sum_two(val: i64, val2: i64) -> i64 {
    val + val2
  }
  
  #[rustler::nif]
  /// nif: to_string_with_env/1
  fn to_string_with_env<'a>(env: rustler::Env<'a>, val: i64) -> rustler::NifResult<String> {
    // normally you can just do `return val.to_string()`
    val.to_string().encode(env).decode()
  }
  """
end
