defmodule HiveNodeTest.MQTest.MessageHandlerTest do
  use ExUnit.Case

  setup do
    case Process.whereis(HiveNode.JobServer) do
      nil -> HiveNode.JobServerSupervisor.start_link(name: HiveNode.JobServerSupervisor)
      _ -> :ok
    end
    case Process.whereis(:job_supervisor) do
      nil -> Task.Supervisor.start_link(name: :job_supervisor)
      _ -> :ok
    end
    # All JSON strings
    os_version = case :os.version do
      {maj, min, _} -> "#{maj}.#{min}"
      version -> inspect version
    end
    os = case :os.type do
      {:unix, type} -> "#{type}"
      type -> inspect type
    end
    {:ok, hostname} = :inet.gethostname
    greet = %HiveNode.MQ.Message.Greet{
      routing_key: "hive,node." <> Application.get_env(:hivenode, :node_name),
      hostname: hostname,
      exchange: "hive_exchange",
      queue: "test_queue",
      os: os,
      os_version: os_version,
      purpose: Application.get_env(:hivenode, :purpose, "UNKNOWN"),
      reply: true
    }
 
    send_info = %HiveNode.MQ.Message.SendInfo{
      requested_type: "job_info",
      info: "echo/2 -  takes the strings and concatenates them with space",
      format: "plain_string"
    }

    request_info = %HiveNode.MQ.Message.RequestInfo{
      type: "job_info",
      subtype: "echo"
    }

    run_job = %HiveNode.MQ.Message.RunJob{
      name: "echo",
      args: ["Hello", "World"],
      send_return_value: true,
      id: "JOBID001"
    }

    job_return_value = %HiveNode.MQ.Message.JobReturnValue{
      status: "ok",
      return_value: "{:ok, \"Hello World\"}",
      id: "JOBID001"
    }

    greet_json = Poison.encode!(greet)
    send_info_json = Poison.encode!(send_info)
    request_info_json = Poison.encode!(request_info)
    run_job_json = Poison.encode!(run_job)
    job_return_value_json = Poison.encode!(job_return_value)
    %{greet: greet, greet_json: greet_json,
      send_info: send_info, send_info_json: send_info_json,
      request_info: request_info, request_info_json: request_info_json,
      run_job: run_job, run_job_json: run_job_json,
      job_return_value: job_return_value,
      job_return_value_json: job_return_value_json}
  end

  test "consume run_job, which gives job_return_value", 
  %{
    run_job: run_job,
    job_return_value: job_return_value
  } do
    status = case HiveNode.MQ.MessageHandler.consume({:run_job, run_job}, 0) do
      "job_return_value" <> json ->
        assert job_return_value == Poison.decode!(json, as: %HiveNode.MQ.Message.JobReturnValue{})
        true
      _-> false
    end
    assert status
  end

  test "invalid message format" do
    assert :ok == HiveNode.MQ.MessageHandler.consume("hello", :undefined, %{})
  end

  test "consume job_return_value", %{job_return_value: job_return_value} do
    assert :noreply == HiveNode.MQ.MessageHandler.consume({:job_return_value, job_return_value})
  end

  test "consume greet message", %{greet: greet} do
    assert "greet" <>  <<_ :: size(88)>> <> json = HiveNode.MQ.MessageHandler.consume({:greet, greet}, 0)
    {:ok, hostname} =  :inet.gethostname
    assert Poison.Parser.parse!(json, keys: :atoms!) == 
      HiveNode.MQ.NodeAgent.get(HiveNode.MQ.NodeAgent, hostname)
  end

  test "consume greet message with noreply", %{greet: greet} do
    assert :noreply =
      HiveNode.MQ.MessageHandler.consume({:greet, %{greet | reply: false}}, 0)
  end

  test "consume run_job json", %{run_job_json: json} do
    assert :ok == HiveNode.MQ.MessageHandler.consume("run_job+++++++++" <> json, :undefined, %{})
  end

  test "consume job_return_value json",  %{job_return_value_json: json} do
    assert :ok == HiveNode.MQ.MessageHandler.consume("job_return_value" <> json, :undefined, %{})
  end

  test "consume greet json", %{greet_json: json} do
    assert :ok == HiveNode.MQ.MessageHandler.consume("greet+++++++++++" <> json, :undefined, %{})
  end
end
