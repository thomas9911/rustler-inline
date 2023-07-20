defmodule RustlerInline.Compiler do
  defmacro __before_compile__(env) do
    out_module = env.module
    app = Module.get_attribute(out_module, :ruster_inline_app)

    # IO.inspect(:code.priv_dir(:rustler_inline))
    priv_dir = :code.priv_dir(:rustler_inline) |> List.to_string()

    tmp_dir = System.tmp_dir!()
    out_dir = Path.join([tmp_dir, "rustler_inline", to_string(app)])

    File.mkdir_p!(out_dir)

    IO.inspect(out_dir)

    string =
      case Module.get_attribute(out_module, :ruster_inline) do
        [] -> raise "No rust specified"
        other -> Enum.join(other, "\n")
      end

    lines = string |> String.split(["\n", "\r\n"])

    function_marker_indexes =
      lines |> Enum.with_index() |> Enum.filter(&String.starts_with?(elem(&1, 0), "/// nif:"))

    function_hints =
      function_marker_indexes
      |> Enum.map(
        &(Enum.at(lines, &1 |> elem(1))
          |> String.trim_leading("/// nif:")
          |> String.trim())
      )

    raw_function_headers = function_marker_indexes |> Enum.map(&Enum.at(lines, elem(&1, 1) + 1))

    contents =
      function_hints
      |> Enum.map(fn func ->
        case String.split(func, "/") do
          [function_name, arity] ->
            {String.to_atom(function_name), String.to_integer(arity)}

          _ ->
            raise "Invalid nif header"
        end
      end)
      |> Enum.map(fn {function, arity} ->
        args = Macro.generate_arguments(arity, out_module)

        quote do
          def unquote(function)(unquote_splicing(args)) do
            :erlang.nif_error(:nif_not_loaded)
          end
        end
      end)

    main_module =
      quote do
        use Rustler, otp_app: unquote(app), crate: "tmp", path: unquote(out_dir)

        unquote(contents)
      end

    function_headers =
      raw_function_headers
      |> Enum.flat_map(fn "fn " <> func ->
        case Regex.scan(~r{[[:alnum:]_]+}, func) do
          [function_name, _ | _rest] ->
            function_name

          _ ->
            raise "unsupported rust function"
        end
      end)

    cargo_toml =
      EEx.eval_file(priv_dir <> "/Cargo.toml.eex", rustler_version: "0.29.1")

    lib_rs =
      EEx.eval_file(priv_dir <> "/lib.rs.eex",
        functions: string,
        module: to_string(out_module),
        function_headers: function_headers
      )

    out_dir
    |> Path.join("Cargo.toml")
    |> File.write!(cargo_toml)

    out_dir
    |> Path.join("lib.rs")
    |> File.write!(lib_rs)

    main_module
  end
end
