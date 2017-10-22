defmodule HiveNodeTest.MQTest.NodeAgentTest do
  use ExUnit.Case


  setup do
    agent = case Process.whereis(HiveNode.MQ.NodeAgent) do
      nil ->
        {:ok, pid} = HiveNode.MQ.NodeAgent.start_link(name: HiveNode.MQ.NodeAgent)
        pid
      pid -> pid
    end
    %{agent: agent}
  end

  test "adding node", %{agent: agent} do
    assert :ok == HiveNode.MQ.NodeAgent.add(agent, %HiveNode.MQ.Message.Greet{})
  end

  test "getting node", %{agent: agent} do
    {:ok, hostname} = :inet.gethostname
    old = struct(HiveNode.MQ.Message.Greet, HiveNode.MQ.NodeAgent.get(agent, hostname))
    assert :ok == HiveNode.MQ.NodeAgent.add(agent, old)
    refute old == HiveNode.MQ.NodeAgent.get(agent, hostname)
  end

  test "registering self", %{agent: agent} do
    assert :ok == HiveNode.MQ.NodeAgent.registerSelf(
      agent, "hive_exchange", "test_queue", "hive.node.test_node")
    refute :notfound == HiveNode.MQ.NodeAgent.getSelf(agent)
  end

  test "getting non existing object", %{agent: agent} do
    assert :notfound == HiveNode.MQ.NodeAgent.get(agent, :doesnotexist)
  end

  test "updating an entry", %{agent: agent} do
    {:ok, hostname} = :inet.gethostname
    old = struct(HiveNode.MQ.Message.Greet, HiveNode.MQ.NodeAgent.get(agent, hostname))
    assert :ok == HiveNode.MQ.NodeAgent.add(agent, %{old | ip_address: "CHANGED"})
    refute old == HiveNode.MQ.NodeAgent.get(agent, hostname)
  end

end
