defmodule HiveTest.JobServerTest do
  use ExUnit.Case
  doctest Hive.JobServer
  setup do 
    {:ok, jobServer} = start_supervised(Hive.JobServer)
    %{job_server: jobServer}
  end

  test "run a job", %{job_server: pid} do
    assert {:ok, _ } = Hive.JobServer.run(pid, "echo", ["hello", "world"])
  end

  test "run an invalid job", %{job_server: pid} do
    assert {:error, _ } = Hive.JobServer.run(pid, "Hive.JobServer")
  end

  test "test a crashing JobServer with supervisor" do
    Process.whereis(Hive.Application)
      |> Supervisor.stop
    Hive.JobServerSupervisor.start_link()
    server_pid = Process.whereis(Hive.JobServer)
    Process.exit(server_pid, :abnormal)
    Process.sleep(1000)
    refute Process.whereis(Hive.JobServer) == nil
  end

end
