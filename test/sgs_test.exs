defmodule SgsTest do
  use ExUnit.Case

	@daemon :__sgs_cleanup_daemon_state__

	test "init, cleanup" do
		:supervisor.start_child Sgs.Supervisor, Supervisor.Spec.worker(GS1, [:my_name], [id: :my_name,  restart: :transient])
		assert :erlang.whereis(:my_name) != :undefined
		assert Exdk.get(:my_name) == %{nameproc: :my_name, state: 1}
		assert GS1.get_state(:my_name) == %{nameproc: :my_name, state: 1}
		:timer.sleep(2000) # here we wait because force_save flag == false in this gs
		%{my_name: %Sgs.SgsInfo{nameproc: :my_name,timestamp: timestamp,cleanup_delay: :infinity }} = Exdk.get(@daemon)
		assert is_integer(timestamp)
		assert GS1.kill(:my_name, :normal)
		:timer.sleep(2000)
		assert Exdk.get(:my_name) == :not_found
		assert :erlang.whereis(:my_name) == :undefined
		assert Exdk.get(@daemon) == %{}

		:supervisor.restart_child Sgs.Supervisor, :my_name
		assert :erlang.whereis(:my_name) != :undefined
		assert GS1.kill(:my_name, :my_reason)
		:timer.sleep(2000)
		assert Exdk.get(:my_name) == :not_found
		assert :erlang.whereis(:my_name) == :undefined
	end


end