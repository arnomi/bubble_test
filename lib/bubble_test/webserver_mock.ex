defmodule BubbleTest.WebserverMock do
  @moduledoc """

  """

  defmacro __using__(opts) do
    main_plug = Keyword.fetch!(opts, :plug)

    quote do
      use Plug.Builder

      plug(unquote(main_plug))

      def init(opts) do
        test_pid = Keyword.fetch!(opts, :test_pid)
        name = Keyword.fetch!(opts, :name)

        %{name: name, test_pid: test_pid}
      end

      def call(conn, opts) do
        %{test_pid: test_pid, name: name} = opts
        send(test_pid, {:web_request, name, conn})

        conn
        |> assign(:test_pid, test_pid)
        |> super(conn)
      end
    end
  end
end
