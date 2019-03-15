defmodule BubbleTest.Case do
  @moduledoc """

  """

  defmacro __using__(_opts \\ []) do
    quote do
      use ExUnit.Case
      import BubbleTest.Case
    end
  end

  defmacro test_system(test_description, config, code_block) do
    mocks =
      config
      |> Macro.expand(__CALLER__)
      |> Keyword.get(:mocks, [])

    webserver_mocks =
      mocks
      |> Enum.filter(fn {k, _} -> k == :webserver end)
      |> Enum.map(fn {_k, v} -> Keyword.fetch!(v, :mock) end)
      |> Enum.map(fn module -> Macro.expand(module, __CALLER__) end)
      |> Enum.uniq()

    mocks =
      mocks
      |> Enum.map(fn {k, v} ->
        if k == :webserver do
          mock = Keyword.fetch!(v, :mock) |>  Macro.expand(__CALLER__)
          {k, Keyword.put(v, :mock, String.to_atom(Atom.to_string(mock) <> "Mock"))}
        else
          {k, v}
        end
      end)

    mock_modules =
      webserver_mocks
      |> Enum.map(fn module ->
        quote do
          defmodule :"#{unquote(module)}Mock" do
            use BubbleTest.WebserverMock, plug: unquote(module)
          end
        end
      end)

    test =
      quote do
        test unquote(test_description) do
          {:ok, pid} =
            start_supervised({
              BubbleTest.Supervisor,
              Keyword.merge(
                unquote(mocks),
                test_pid: self()
              )
            })

          unquote(code_block)
        end
      end

    [mock_modules, test]
  end
end
