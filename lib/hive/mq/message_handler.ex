defmodule Hive.MQ.MessageHandler do
  require Logger

  @moduledoc """
  This module is responsible for handling all messages received by rabbitmq
  """


  defp addType(json, type) do
    case type do
      :run_job ->           "run_job+++++++++" <> json
      :job_return_value ->  "job_return_value" <> json
      :greet ->             "greet+++++++++++" <> json
      :send_info ->         "send_info+++++++" <> json
      :request_info ->      "request_info++++" <> json
      _ -> {:error, :typedne, json}
    end
  end


  @doc """
  This is where every message goes through. If the message structure is
  recognized, then they will go to another function that specializes the
  specific format. Those functions are responsible for returning the reply
  messages or `:noreply` for no replies.
  """
  def consume(payload, routing_key, state) do
    reply = case payload do
      "run_job" <> << _::size(72) >> <> msg when is_bitstring(payload) ->
        job = Poison.decode!(msg, as: %Hive.MQ.Message.RunJob{})
        consume({:run_job, job}, 0)
      "job_return_value" <> msg when is_bitstring(payload) ->
        msg 
        |> Poison.decode!(as: %Hive.MQ.Message.JobReturnValue{})
        |> (&consume({:job_return_value, &1})).()
      "greet" <> << _::size(88) >> <> msg when is_bitstring(payload) ->
        msg
        |> Poison.decode!(as: %Hive.MQ.Message.Greet{})
        |> (&consume({:greet, &1}, 0)).()
      _ -> 
        Logger.warn "Unknown message format: #{payload}"
        :noreply
    end

    if reply != :noreply && routing_key != :undefined do
      AMQP.Basic.publish(
        Map.get(state, :channel),
        "hive_exchange",
        routing_key,
        inspect(reply),
        reply_to: "hive.node." <> Map.get(state, :node_name))
    end
    :ok
  end

  @doc """
  This function handles the `run_job` message type. It runs the job using
  the `Hive.JobServer`. If requested it returns the function's return
  value. The return value is in the json of a `job_return_value` message.
  If no return is requested then the return value is `:noreply`.
  """ 
  def consume({:run_job, job}, count) do
    case Process.whereis(Hive.JobServer) do
      nil when count < 5 -> 
        Process.sleep(1000)
        consume({:run_job, job}, count + 1)
      _ -> 
        {status, return_val} = Hive.JobServer.run(Hive.JobServer, job.name, job.args)
        cond do
          status == :ok && job.send_return_value -> 
            %Hive.MQ.Message.JobReturnValue{status: status, return_value: inspect(return_val), id: job.id}
            |> Poison.encode!()
            |> addType(:job_return_value)

          status == :error && job.send_return_value -> {:error, return_val}
          !job.send_return_value -> :noreply
        end
    end
  end


  @doc """
  This function is used to handle greet messages. If the greet message
  requests a greet back then a greet message in json format is returned.
  If no reply is needed, then `:noreply` is returned.
  """
  def consume({:greet, greeting}, count) do
    if Process.whereis(Hive.MQ.NodeAgent) == nil && count < 5 do  
      Process.sleep(1000)
      consume({:greet, greeting}, count + 1)
    else 
      Hive.MQ.NodeAgent.add(Hive.MQ.NodeAgent, greeting)
      {:ok, hostname} = :inet.gethostname
      if greeting.reply do
        case Hive.MQ.NodeAgent.get(Hive.MQ.NodeAgent, hostname) do
          :notfound -> :noreply
          greet -> 
            greet
            |> Poison.encode!()                               
            |> addType(:greet)
        end
      else
        :noreply
      end        
    end
  end


  @doc """
  This function handles the `job_return_val` messages. As of now the
  messages are acknowledged and thrown out. It always returns `:noreply`.
  """
  def consume({:job_return_value, _return_val}) do
    :noreply
  end

end

