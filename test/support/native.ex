defmodule RustlerInlineTest.Native do
  use RustlerInline, app: :rustler_inline

  ~i"""
  #[rustler::nif]
  /// nif: my_func/1
  fn my_func(val: i64) -> i64 {
    return val + 1;
  }

  #[rustler::nif]
  /// nif: my_func_2/2
  fn my_func_2(val: i64, val2: i64) -> i64 {
    return val + val2;
  }
  """

end
