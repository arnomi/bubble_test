defmodule BubbleTest.Case do
  @moduledoc """
  Provides an `ExUnit` test case for "bubble" testing microservices. A test case
  allows to set up mocks for external systems the microservice expects. Currently
  available for mocking are

  - Webserver

  Following is an example test case which sets up two mock webservers. The webservers
  are controlled by mock implementations (in the case of webservers these should be plugs).

      defmodule System1Mock do
        use Plug.Router

        plug(:match)
        plug(:dispatch)

        get "/hello/:name" do
          send_resp(conn, 200, name)
        end
      end

      defmodule System2Mock do
        use Plug.Router
        # ...
      end

      test_system "we can start mock webservers for system testing", mocks: [
              webserver: [port: 12345, mock: System1Mock, name: HTTP1],
              webserver: [port: 23456, mock: System2Mock, name: HTTP2]
            ] do
          # interact with the microservice
      end

  Any request that is made to one of the mock servers is forwarded to the test case which
  can assert on it.

      assert_receive({:web_request, HTTP1, %{request_path: "/hello/system1"}}, 1000)
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
