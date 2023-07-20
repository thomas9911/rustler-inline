defmodule RustlerInline do
  defmacro __using__(opts) do
    app = Access.fetch!(opts, :app)

    quote do
      import RustlerInline
      Module.put_attribute(__MODULE__, :ruster_inline_app, unquote(app))

      @before_compile RustlerInline.Compiler
      @before_compile Rustler

      :ok
    end
  end

  defmacro sigil_i({:<<>>, _meta, [string]}, options) when is_binary(string) do
    Module.register_attribute(__CALLER__.module, :ruster_inline, accumulate: true)
    Module.put_attribute(__CALLER__.module, :ruster_inline, string)

    # IO.inspect(string |> String.split(["\n", "\r\n"]))

    # out_module = Module.concat(__CALLER__.module, Native)

    # lines = string |> String.split(["\n", "\r\n"])

    # function_marker_indexes = lines |> Enum.with_index() |> Enum.filter(&String.starts_with?(elem(&1, 0), "/// nif:"))

    # function_hints = function_marker_indexes |> Enum.map(& Enum.at(lines, &1 |> elem(1)) |> String.trim_leading("/// nif:") |> String.trim())
    # function_headers = function_marker_indexes |> Enum.map(& Enum.at(lines, elem(&1, 1) + 1))

    # contents =  function_hints
    # |> Enum.map(fn func ->
    #   case String.split(func, "/") do
    #     [function_name, arity] ->
    #       {String.to_atom(function_name), String.to_integer(arity)}
    #     _ -> raise "Invalid nif header"
    #   end
    # end)
    # |> Enum.map(fn {function, arity} ->
    #     args = Macro.generate_arguments(arity, out_module)
    #     quote do
    #       def unquote(function)(unquote_splicing(args)) do
    #         :ok
    #       end
    #     end
    # end)
    # # |> Macro.to_string()
    # # |> IO.inspect()
    # main_module = quote do
    #   use Agent

    #   unquote(contents)

    # end

    # out_module
    # |> Module.create(main_module, Macro.Env.location(__CALLER__))
    # |> IO.inspect()

    # # IO.inspect(function_headers)
    # function_headers
    # |> Enum.flat_map(fn "fn " <> func ->
    #   case Regex.scan(~r{[[:alnum:]_]+}, func) do
    #     [function_name, _ | _rest]  ->
    #       function_name
    #     _ ->
    #       raise "unsupported rust function"
    #   end
    # end)
    # |> IO.inspect()

    :ok
  end
end
