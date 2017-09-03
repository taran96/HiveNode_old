defmodule HiveTest.JobTest do
  use ExUnit.Case
  setup do
    default_job = %Hive.Job{}
    %{simple_job: default_job}
  end

  test "running a job", %{simple_job: job} do
    assert{:ok, _} = Hive.Job.run(job)
  end

  test "attempt to run invalid job", %{simple_job: job} do
    invalid_func = quote do: Hive.JobList.doesNotExist_test()

    invalid_job = %{job | function: invalid_func}
    assert {:error, _} = Hive.Job.run(invalid_job)
  end
end
