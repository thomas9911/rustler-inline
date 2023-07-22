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

  defmacro rust(code, _options \\ []) when is_binary(code) do
    rustler_version =
      case Application.spec(:rustler, :vsn) do
        nil -> raise "rustler not found"
        version -> version |> to_string() |> Version.parse!() |> Map.put(:patch, 0) |> to_string()
      end

    Module.register_attribute(__CALLER__.module, :ruster_inline, accumulate: true)
    Module.put_attribute(__CALLER__.module, :ruster_inline, code)
    Module.put_attribute(__CALLER__.module, :ruster_inline_rustler_version, rustler_version)
  end
end
