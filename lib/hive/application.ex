defmodule Hive.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Hive.MQ.NodeAgent, [name: Hive.MQ.NodeAgent]},
      {Task.Supervisor, [name: :job_supervisor]},
      {Hive.JobServerSupervisor, [name: Hive.JobServerSupervisor]},
      {Hive.MQ.ServerSupervisor, [name: Hive.MQ.ServerSupervisor]},
    ]

    opts = [strategy: :one_for_one, name: Hive.Application]
    Supervisor.start_link(children, opts)
  end
end
