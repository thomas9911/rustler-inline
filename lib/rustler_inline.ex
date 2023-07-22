defmodule RustlerInline do
  @moduledoc false
  defmacro __using__(options) do
    app = Access.fetch!(options, :app)

    quote bind_quoted: [options: options, app: app] do
      import RustlerInline

      rustler_version =
        case Application.spec(:rustler, :vsn) do
          nil ->
            raise "rustler not found"

          version ->
            version
            |> to_string()
            |> Version.parse!()
            |> Map.put(:patch, 0)
            |> to_string()
        end

      rust_deps =
        options
        |> Access.get(:rust_deps, [])
        |> Enum.concat([{:rustler, "\"#{rustler_version}\""}])

      Module.put_attribute(__MODULE__, :ruster_inline_app, app)
      Module.put_attribute(__MODULE__, :ruster_inline_rust_deps, rust_deps)

      @before_compile RustlerInline.Compiler
      @before_compile Rustler

      :ok
    end
  end

  defmacro rust(code, _ \\ []) when is_binary(code) do
    Module.register_attribute(__CALLER__.module, :ruster_inline, accumulate: true)
    Module.put_attribute(__CALLER__.module, :ruster_inline, code)
  end
end
