defmodule RustlerInlineTest do
  use ExUnit.Case

  describe "simple" do
    test "my_func" do
      assert 2 == RustlerInlineTest.Simple.add_one(1)
    end

    test "my_func2" do
      assert 13 == RustlerInlineTest.Simple.sum_two(5, 8)
    end

    test "my_func_with_env" do
      assert "5" == RustlerInlineTest.Simple.to_string_with_env(5)
    end
  end
end
