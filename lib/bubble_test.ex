defmodule BubbleTest do
  def mock_world(opts) do
    BubbleTest.Supervisor.start_link(opts)
  end
end
