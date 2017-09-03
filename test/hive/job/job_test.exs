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

    invalid_job = %{job | job_name: invalid_func}
    assert {:error, _} = Hive.Job.run(invalid_job)
  end

  test "run job based on string name", %{simple_job: job} do
    %{job_name: job_name, args: args} = job
    assert Hive.Job.run(job) == Hive.Job.run(job_name, args)
  end

  test "decoding json job", %{simple_job: job} do
    json_string =
      ~s({"name": "Hello_World", "job_name": "echo", "args": ["Hello", "World"]})
    assert Hive.Job.from_json(json_string) == job
  end

  test "encoding json job", %{simple_job: job} do
    json_string = Hive.Job.to_json(job)
    assert Poison.decode!(json_string, as: %Hive.Job{}) == job
  end
end
