defmodule BubbleTest.Supervisor do
  @moduledoc """

  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    {global_opts, system_opts} = Keyword.split(opts, [:test_pid])

    children = child_specs(global_opts, system_opts)
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp child_specs(global_opts, system_opts), do: child_specs([], global_opts, system_opts)

  defp child_specs(result, _global_opts, []), do: Enum.reverse(result)

  defp child_specs(result, global_opts, [config | remainder]) do
    child_specs([child_spec_for(config, global_opts) | result], global_opts, remainder)
  end

  defp child_spec_for({:webserver, opts}, global_opts) do
    mock = Keyword.fetch!(opts, :mock)
    name = Keyword.get(opts, :name, BubbleTest.Http)
    test_pid = Keyword.fetch!(global_opts, :test_pid)

    scheme = Keyword.get(opts, :scheme, :http)

    port = Keyword.fetch!(opts, :port)
    ip = Keyword.get(opts, :ip, {127, 0, 0, 1})

    server_opts = Keyword.take(opts, [:dispatch, :compress, :timeout, :protocol_options, :transport_options])

    Plug.Cowboy.child_spec(
      scheme: scheme,
      plug: {mock, [test_pid: test_pid, name: name]},
      options: [ref: name, port: port, ip: ip] ++ server_opts
    )
  end

  defp child_spec_for(unsupported_config, _global_opts) do
    raise ArgumentError,
      message: "Got an unsupported moccking config: #{inspect(unsupported_config)}"
  end
end
