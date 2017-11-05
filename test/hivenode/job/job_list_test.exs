defmodule HiveNodeTest.JobListTest do
  use ExUnit.Case

  test "echo test" do
    assert {:ok, "Hello World"} == HiveNode.JobList.echo("Hello", "World")
  end

  @tag :serial_device_required
  test "write to TTY" do
    tty = case Nerves.UART.enumerate |> Map.to_list do
      [{tty, _} | _tail ] -> tty
      [] -> assert false, "There are no TTY devices to test with"
    end
    assert :ok == HiveNode.JobList.write_to_tty(tty, "Hello")
  end

  test "write to non existing TTY" do
    assert {:error, :enoent} == HiveNode.JobList.write_to_tty("Doesnotexist", "Hello")
  end

  test "write to non device but existing TTY" do
    assert {:error, :einval} == HiveNode.JobList.write_to_tty("/dev/tty", "hello")
  end

  @tag :echo_server_required
  test "connect to new server" do
    {:ok, agent_pid} = HiveNode.TCP.Agent.start_link(name: HiveNode.TCP.Agent)
    assert :ok == HiveNode.JobList.connect_to_server(
      "echo",
      Application.get_env(:hivenode, :echo_server_host),
      Application.get_env(:hivenode, :echo_server_port)
    )
    Process.exit(agent_pid, :normal)
  end

  @tag :echo_server_required
  test "check for server" do
    start_echo_server()
    assert true == HiveNode.JobList.check_for_server("echo")
    Process.whereis(HiveNode.TCP.Agent) |> Process.exit(:normal)
  end

  @tag :echo_server_required
  test "sending a message to existing server" do
    start_echo_server()
    assert "hello" == HiveNode.JobList.send_to_server("echo", "hello")
    Process.whereis(HiveNode.TCP.Agent) |> Process.exit(:normal)
  end

  defp start_echo_server do
    case Process.whereis(HiveNode.TCP.Agent) do
      :nil -> HiveNode.TCP.Agent.start_link(name: HiveNode.TCP.Agent)
      pid -> pid
    end
    HiveNode.TCP.Client.start_link(
      [
        name: "echo",
        host: Application.get_env(:hivenode, :echo_server_host),
        port: Application.get_env(:hivenode, :echo_server_port),
        active: true,
        mode: :binary
      ]
    )
  end
end
