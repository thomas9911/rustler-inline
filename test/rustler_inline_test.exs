defmodule RustlerInlineTest do
  use ExUnit.Case

  test "my_func" do
    assert 2 == RustlerInlineTest.Native.my_func(1)
  end

  test "my_func2" do
    assert 13 == RustlerInlineTest.Native.my_func_2(5, 8)
  end
end
