defmodule HiveNode.TCP.Agent do
  use Agent
  require Logger

  @moduledoc """
  This agent is responsible for keeping track of pids that manage a TCP
  connection. A string name will map the pids. A registry is not used
  because every process will require an atom to represent it. The number
  of processes is uncertain so we do not want to allocate space for atoms.
  """

  def start_link(opts \\ []) do
    Agent.start_link(fn -> %{} end, opts)
  end

  @doc """
  This endpoint adds a new connection to the Agent. It accepts the name and
  pid of the process being added. There is no way to tell that the only pids
  being added are TCP connections.
  """
  def add(pid, name, connection_pid) do
    Logger.debug "Adding #{inspect connection_pid} as #{name}"
    Agent.update(pid, &Map.put(&1, name, connection_pid))
  end

  @doc """
  This endpoint gets a pid of an HiveNode.TCP.Client instance based on the
  assigned name. If the name does not exist then :notfound will be returned.
  """
  def get(pid, name) do
    getter = fn map ->
      case Map.fetch(map, name) do
        {:ok, value} -> value
        :error -> :notfound
      end
    end
    Agent.get(pid, getter)
  end

end
