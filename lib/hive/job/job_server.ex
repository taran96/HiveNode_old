defmodule Hive.JobServer do 
  use GenServer, restart: :transient
  require Logger

  def start_link(opts \\ []) do
    pid = GenServer.start_link(__MODULE__, :ok, opts)
    Logger.info "Started " <> inspect(__MODULE__) <> " " <> inspect(pid)
    pid
  end


  def init(:ok) do
    pids = %{}
    {:ok, pids}
  end

  def run(server, job_name, args \\ []) when is_bitstring(job_name) do
    GenServer.call(server, {:run, job_name, args})  
  end


  def handle_call({:run, job_name, args}, _from, pids) do
    if Hive.Job.is_valid(job_name) do
      {:reply, Hive.Job.run(job_name, args), pids}
    else
      {:reply, {:error, :invalid_job}, pids}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, pids) do
    case reason do
      :normal -> Logger.info "Process " <> inspect(pid) <> " exited gracefully"
      _ -> Logger.error "Process " <> inspect(pid) <> " died: " <> inspect(reason)
    end
    {:noreply, pids}
  end

  def handle_info(msg, pids) do
    Logger.warn "Unhandled message: " <> inspect(msg)
    {:noreply, pids}
  end
end


