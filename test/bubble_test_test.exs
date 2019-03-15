defmodule BubbleTestTest do
  use BubbleTest.Case

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

    plug(:match)
    plug(:dispatch)

    get "/hello/:name" do
      send_resp(conn, 404, "Oops!")
    end
  end

  test_system "we can start mock webservers for system testing", mocks: [
                webserver: [port: 12345, mock: System1Mock, name: HTTP1],
                webserver: [port: 23456, mock: System2Mock, name: HTTP2]
              ] do
    HTTPoison.get("http://localhost:12345/hello/system1")
    assert_receive({:web_request, HTTP1, %{request_path: "/hello/system1"}}, 1000)

    HTTPoison.get("http://localhost:23456/hello/system2")
    assert_receive({:web_request, HTTP2, %{request_path: "/hello/system2"}}, 1000)
  end
end
