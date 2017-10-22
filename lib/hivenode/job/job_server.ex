defmodule HiveNode.JobServer do 
  @moduledoc """
  This module is responsible to handle any request to run a job
  """
  
  use GenServer, restart: :transient
  require Logger


  def start_link(opts \\ []) do
    Logger.info "Starting #{__MODULE__}"
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    pids = %{}
    {:ok, pids}
  end


  @doc """
  This function is used to run a job. It runs the job synchronously, so it will block the caller. The function also returns the value of the job.

  A job is executed as such:
      iex> {:ok, pid} = HiveNode.JobServer.start_link()
      iex> HiveNode.JobServer.run(pid, "echo", ["Hello", "World"])
      {:ok, {:ok, "Hello World"}} 
  """
  def run(server, job_name, args \\ []) when is_bitstring(job_name) do
    GenServer.call(server, {:run, job_name, args})  
  end


  @doc """
  This call handler runs the requested job and returns the return value of the function.
  """
  def handle_call({:run, job_name, args}, _from, pids) do
    if HiveNode.Job.is_valid(job_name) do
      job_pid = Task.Supervisor.async(
        :job_supervisor, 
        fn -> HiveNode.Job.run(job_name, args) end
      )
      {:reply, Task.await(job_pid), pids}
    else
      {:reply, {:error, :invalid_job}, pids}
    end
  end


  @doc """
  This info handler logs and handles a failed job
  """
  def handle_info({:DOWN, _ref, :process, pid, reason}, pids) do
    case reason do
      :normal -> Logger.info "Process " <> inspect(pid) <> " exited gracefully"
      _ -> Logger.error "Process " <> inspect(pid) <> " died: " <> inspect(reason)
    end
    {:noreply, pids}
  end


  @doc """
  This handler logs any message that is not caught by other handlers. Therefore it makes the message an unhandled message.
  """
  def handle_info(msg, pids) do
    Logger.warn "Unhandled message: " <> inspect(msg)
    {:noreply, pids}
  end
end


