defmodule HiveNode.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {HiveNode.MQ.NodeAgent, [name: HiveNode.MQ.NodeAgent]},
      {Task.Supervisor, [name: :job_supervisor]},
      {HiveNode.JobServerSupervisor, [name: HiveNode.JobServerSupervisor]},
      {HiveNode.MQ.ServerSupervisor, [name: HiveNode.MQ.ServerSupervisor]},
    ]

    opts = [strategy: :one_for_one, name: HiveNode.Application]
    Supervisor.start_link(children, opts)
  end
end
