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
    Module.register_attribute(__CALLER__.module, :ruster_inline, accumulate: true)
    Module.put_attribute(__CALLER__.module, :ruster_inline, code)
    Module.put_attribute(__CALLER__.module, :ruster_inline_rustler_version, "0.29.1")
  end

  defmacro sigil_i({:<<>>, _meta, [string]}, _options) when is_binary(string) do
    Module.register_attribute(__CALLER__.module, :ruster_inline, accumulate: true)
    Module.put_attribute(__CALLER__.module, :ruster_inline, string)
    Module.put_attribute(__CALLER__.module, :ruster_inline_rustler_version, "0.29.1")
  end
end
