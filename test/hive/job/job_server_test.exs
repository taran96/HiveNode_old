defmodule HiveTest.JobServerTest do
  use ExUnit.Case
  setup do 
    {:ok, jobServer} = case Process.whereis(Hive.JobServer) do
      nil -> start_supervised(Hive.JobServer)
      _ -> 
        Hive.JobServerSupervisor.start_link(name: Hive.JobServerSupervisor)
        {:ok, Process.whereis(Hive.JobServer)}
    end
    if Process.whereis(:job_supervisor) == nil do
      Task.Supervisor.start_link(name: :job_supervisor)
    end
    if jobServer == nil do
      assert False, "job_server not started"
    end
    %{job_server: jobServer}
  end

  test "run a job", %{job_server: pid} do
    assert {:ok, _ } = Hive.JobServer.run(pid, "echo", ["hello", "world"])
  end

  test "run an invalid job", %{job_server: pid} do
    assert {:error, _ } = Hive.JobServer.run(pid, "Hive.JobServer")
  end

  test "test a crashing JobServer with supervisor", %{job_server: server_pid} do
    Process.exit(server_pid, :abnormal)
    refute Process.whereis(Hive.JobServer) == nil
  end

end
