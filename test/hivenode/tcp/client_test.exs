defmodule HiveNodeTest.TCPTest.ClientTest do
  use ExUnit.Case
  alias HiveNode.TCP.{Client, Agent}

  @moduletag :echo_server_required

  setup do
    Agent.start_link([name: HiveNode.TCP.Agent])
    client_params = [
      name: "echo",
      host: Application.get_env(:hivenode, :echo_server_host),
      port: Application.get_env(:hivenode, :echo_server_port),
      mode: :binary,
      active: true,
    ]
    {:ok, pid} = Client.start_link(client_params)
    on_exit fn ->
      Process.exit(pid, :normal)
    end
    {:ok, %{client: pid}}
  end


  test "Check connection", %{client: pid} do
    assert "Hello" == Client.send_message(pid, "Hello")
  end

  test "Added to agent", %{client: pid} do
    assert pid == Agent.get(HiveNode.TCP.Agent, "echo")
  end

end

