defmodule RustlerInline.Compiler do
  defmacro __before_compile__(env) do
    fetch_elixir_function_header = fn {_, line_index}, lines, nif_prefix ->
      lines
      |> Enum.at(line_index)
      |> String.trim_leading(nif_prefix)
      |> String.trim()
    end

    parse_elixir_function_header = fn func ->
      case String.split(func, "/") do
        [function_name, arity] ->
          {String.to_atom(function_name), String.to_integer(arity)}

        _ ->
          raise "Invalid nif header"
      end
    end

    generate_elixir_function_placeholder = fn {function, arity}, out_module ->
      args = Macro.generate_arguments(arity, out_module)

      quote do
        def unquote(function)(unquote_splicing(args)) do
          :erlang.nif_error(:nif_not_loaded)
        end
      end
    end

    detect_rust_function_header = fn "fn " <> func ->
      case Regex.scan(~r{[[:alnum:]_]+}, func) do
        [function_name, _ | _rest] ->
          function_name

        _ ->
          raise "unsupported rust function"
      end
    end

    nif_prefix = "/// nif:"
    out_module = env.module
    app = Module.get_attribute(out_module, :ruster_inline_app)
    rustler_version = Module.get_attribute(out_module, :ruster_inline_rustler_version)
    priv_dir = "#{:code.priv_dir(:rustler_inline)}"
    out_dir = Path.join([System.tmp_dir!(), "rustler_inline", to_string(app)])

    File.mkdir_p!(out_dir)

    rust_code =
      case Module.get_attribute(out_module, :ruster_inline) do
        [] -> raise "No rust specified"
        other -> Enum.join(other, "\n")
      end

    lines = String.split(rust_code, ["\n", "\r\n"])

    function_marker_indexes =
      lines
      |> Enum.with_index()
      |> Enum.filter(&String.starts_with?(elem(&1, 0), nif_prefix))

    elixir_function_placeholders =
      function_marker_indexes
      |> Enum.map(&fetch_elixir_function_header.(&1, lines, nif_prefix))
      |> Enum.map(parse_elixir_function_header)
      |> Enum.map(&generate_elixir_function_placeholder.(&1, out_module))

    function_headers =
      function_marker_indexes
      |> Enum.map(&Enum.at(lines, elem(&1, 1) + 1))
      |> Enum.flat_map(detect_rust_function_header)

    cargo_toml =
      priv_dir
      |> Path.join("Cargo.toml.eex")
      |> EEx.eval_file(rustler_version: rustler_version)

    lib_rs =
      priv_dir
      |> Path.join("lib.rs.eex")
      |> EEx.eval_file(
        functions: rust_code,
        module: to_string(out_module),
        function_headers: function_headers
      )

    out_dir
    |> Path.join("Cargo.toml")
    |> File.write!(cargo_toml)

    out_dir
    |> Path.join("lib.rs")
    |> File.write!(lib_rs)

    quote do
      use Rustler, otp_app: unquote(app), crate: "tmp", path: unquote(out_dir)

      unquote(elixir_function_placeholders)
    end
  end
end
