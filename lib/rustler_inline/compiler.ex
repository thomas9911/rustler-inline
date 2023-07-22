defmodule RustlerInline.Compiler do
  @moduledoc false
  defp get_rust_code(out_module) do
    case Module.get_attribute(out_module, :ruster_inline) do
      [] -> raise "No rust specified"
      rust_parts -> Enum.join(rust_parts, "\n")
    end
  end

  defp generate_elixir_function_placeholders(
         function_marker_indexes,
         lines,
         nif_prefix,
         out_module
       ) do
    function_marker_indexes
    |> Enum.map(&fetch_elixir_function_header(&1, lines, nif_prefix))
    |> Enum.map(&parse_elixir_function_header/1)
    |> Enum.map(&generate_elixir_function_placeholder(&1, out_module))
  end

  defp fetch_elixir_function_header({_, line_index}, lines, nif_prefix) do
    lines
    |> Enum.at(line_index)
    |> String.trim_leading(nif_prefix)
    |> String.trim()
  end

  defp parse_elixir_function_header(func) do
    case String.split(func, "/") do
      [function_name, arity] ->
        {String.to_atom(function_name), String.to_integer(arity)}

      _ ->
        raise "Invalid nif header"
    end
  end

  defp generate_elixir_function_placeholder({function, arity}, out_module) do
    args = Macro.generate_arguments(arity, out_module)

    quote do
      def unquote(function)(unquote_splicing(args)) do
        :erlang.nif_error(:nif_not_loaded)
      end
    end
  end

  defp generate_rust_function_headers(function_marker_indexes, lines) do
    function_marker_indexes
    |> Enum.map(&Enum.at(lines, elem(&1, 1) + 1))
    |> Enum.flat_map(&detect_rust_function_header/1)
  end

  defp detect_rust_function_header("fn " <> func) do
    case Regex.scan(~r{[[:alnum:]_]+}, func) do
      [function_name, _ | _rest] ->
        function_name

      _ ->
        raise "unsupported rust function"
    end
  end

  defp priv_dir, do: "#{:code.priv_dir(:rustler_inline)}"

  defp out_dir(app) do
    Path.join([System.tmp_dir!(), "rustler_inline", to_string(app)])
  end

  defmacro __before_compile__(env) do
    nif_prefix = "/// nif:"
    crate_name = "tmp"
    out_module = env.module
    app = Module.get_attribute(out_module, :ruster_inline_app)
    rust_deps = Module.get_attribute(out_module, :ruster_inline_rust_deps)
    out_dir = out_dir(app)

    File.mkdir_p!(out_dir)

    rust_code = get_rust_code(out_module)

    lines = String.split(rust_code, ["\n", "\r\n"])

    function_marker_indexes =
      lines
      |> Enum.with_index()
      |> Enum.filter(&String.starts_with?(elem(&1, 0), nif_prefix))

    elixir_function_placeholders =
      generate_elixir_function_placeholders(
        function_marker_indexes,
        lines,
        nif_prefix,
        out_module
      )

    function_headers = generate_rust_function_headers(function_marker_indexes, lines)

    cargo_toml =
      priv_dir()
      |> Path.join("Cargo.toml.eex")
      |> EEx.eval_file(dependencies: rust_deps, crate_name: crate_name)

    lib_rs =
      priv_dir()
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
      use Rustler, otp_app: unquote(app), crate: unquote(crate_name), path: unquote(out_dir)

      unquote(elixir_function_placeholders)
    end
  end
end
