# RustlerInline

Adds the ability to 'inline' rust in your elixir modules.
It just uses `Rustler` to do the heavy lifting.

## Examples

```elixir
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

```

You can include extra rust dependencies like:

```elixir
defmodule RustlerInlineTest.ExtraDeps do
  @moduledoc false
  use ExUnit.Case

  use RustlerInline,
    app: :rustler_inline,
    rust_deps: [
      serde_json: ~s["1.0"],
      serde: ~s|{version = "1.0", features = ["derive"]}|
    ]

  defmodule AddStruct do
    @moduledoc false
    defstruct lhs: 0, rhs: 0
  end

  rust """
  use serde::{Deserialize, Serialize};
  use rustler::NifStruct;

  #[derive(Debug, NifStruct, Deserialize, Serialize)]
  #[module = "RustlerInlineTest.ExtraDeps.AddStruct"]
  struct AddStruct {
    lhs: i32,
    rhs: i32,
  }

  #[rustler::nif]
  /// nif: json_keys/1
  fn json_keys(val: &str) -> rustler::NifResult<Vec<String>> {
    let object: serde_json::Map<String, serde_json::Value> = serde_json::from_str(val).unwrap();
    let mut keys: Vec<String> = object.keys().cloned().collect();
    keys.sort();
    Ok(keys)
  }

  #[rustler::nif]
  /// nif: struct_to_json/1
  fn struct_to_json(add_struct: AddStruct) -> String {
    serde_json::to_string(&add_struct).unwrap()
  }
  """

  describe "serde_json" do
    test "json_keys" do
      assert ["keys", "test"] == RustlerInlineTest.ExtraDeps.json_keys(~s[{"test": 1, "keys": 2}])
    end

    test "struct_to_json" do
      assert %{"lhs" => 12, "rhs" => 3} ==
               %RustlerInlineTest.ExtraDeps.AddStruct{
                 lhs: 12,
                 rhs: 3
               }
               |> RustlerInlineTest.ExtraDeps.struct_to_json()
               |> Jason.decode!()
    end
  end
end

```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rustler_inline` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rustler_inline, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/rustler_inline>.

