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
