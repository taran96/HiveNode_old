defmodule HiveNodeTest.JobServerTest do
  use ExUnit.Case
  setup do 
    {:ok, jobServer} = case Process.whereis(HiveNode.JobServer) do
      nil -> start_supervised(HiveNode.JobServer)
      _ -> 
        HiveNode.JobServerSupervisor.start_link(name: HiveNode.JobServerSupervisor)
        {:ok, Process.whereis(HiveNode.JobServer)}
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
    assert {:ok, _ } = HiveNode.JobServer.run(pid, "echo", ["hello", "world"])
  end

  test "run an invalid job", %{job_server: pid} do
    assert {:error, _ } = HiveNode.JobServer.run(pid, "HiveNode.JobServer")
  end

  test "test a crashing JobServer with supervisor", %{job_server: server_pid} do
    Process.exit(server_pid, :abnormal)
    refute Process.whereis(HiveNode.JobServer) == nil
  end

end
