defmodule HiveNodeTest.JobServerTest do
  use ExUnit.Case
  setup do 
    HiveNode.JobServerSupervisor.start_link(name: HiveNode.JobServerSupervisor)
    jobServer = Process.whereis(HiveNode.JobServer)
    if Process.whereis(:job_supervisor) == nil do
      Task.Supervisor.start_link(name: :job_supervisor)
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
