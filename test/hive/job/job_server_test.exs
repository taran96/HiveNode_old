defmodule HiveTest.JobServerTest do
  use ExUnit.Case

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

end
