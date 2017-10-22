defmodule HiveNodeTest.JobTest do
  use ExUnit.Case
  setup do
    default_job = %HiveNode.Job{}
    %{simple_job: default_job}
  end

  test "running a job", %{simple_job: job} do
    assert{:ok, _} = HiveNode.Job.run(job)
  end

  test "attempt to run invalid job", %{simple_job: job} do
    invalid_func = quote do: HiveNode.JobList.doesNotExist_test()

    invalid_job = %{job | job_name: invalid_func}
    assert {:error, _} = HiveNode.Job.run(invalid_job)
  end

  test "run job based on string name", %{simple_job: job} do
    %{job_name: job_name, args: args} = job
    assert HiveNode.Job.run(job) == HiveNode.Job.run(job_name, args)
  end

  test "decoding json job", %{simple_job: job} do
    json_string =
      ~s({"name": "Hello_World", "job_name": "echo", "args": ["Hello", "World"]})
    assert HiveNode.Job.from_json(json_string) == job
  end

  test "encoding json job", %{simple_job: job} do
    json_string = HiveNode.Job.to_json(job)
    assert Poison.decode!(json_string, as: %HiveNode.Job{}) == job
  end

  test "decoding json job with extra attributes", %{simple_job: job} do
    json_string = 
      ~s({"name": "Hello_World", "job_name": "echo", "args": ["Hello", "World"],
          "extra_field": 4})
    assert HiveNode.Job.from_json(json_string) == job
  end

  test "decoding json job with missing attributes", %{simple_job: job} do
    json_string =
      ~s({"job_name": "echo", "args": ["Hello", "World"]})
    assert HiveNode.Job.from_json(json_string) == job
  end
end
