# defmodule RustlerInlineTest.Native do
#   use RustlerInline, app: :rustler_inline

#   ~i"""
#   #[rustler::nif]
#   /// nif: my_func/1
#   fn my_func(val: i64) -> i64 {
#     return val + 1;
#   }
#   """
# end

defmodule RustlerInlineTest do
  use ExUnit.Case

  test "" do
    assert 2 == RustlerInlineTest.Native.my_func(1)
  end
end
