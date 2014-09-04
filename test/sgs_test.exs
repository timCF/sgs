defmodule SgsTest do
  use ExUnit.Case

	@daemon :__sgs_cleanup_daemon_state__

	test "init, cleanup and no-cleanup cases, some pattern matching" do
		:supervisor.start_child Sgs.Supervisor, Supervisor.Spec.worker(GS1, [:my_name], [id: :my_name,  restart: :temporary])
		assert :erlang.whereis(:my_name) != :undefined
		assert Exdk.get(:my_name) == %{nameproc: :my_name, state: 1}
		assert GS1.get_state(:my_name) == %{nameproc: :my_name, state: 1}
		:timer.sleep(2000) # here we wait because force_save flag == false in this gs
		assert (Exdk.get(@daemon) |> HashUtils.get(:my_name) |> HashUtils.set(:timestamp, 0)) == %Sgs.SgsInfo{nameproc: :my_name,cleanup_delay: :infinity, cleanup_reasons: [:my_reason, :normal] }
		assert is_integer(Exdk.get(@daemon) |> HashUtils.get([:my_name, :timestamp]))
		assert GS1.kill(:my_name, :normal)
		:timer.sleep(2000)
		assert Exdk.get(:my_name) == :not_found
		assert :erlang.whereis(:my_name) == :undefined
		assert (Exdk.get(@daemon) |> HashUtils.get(:my_name)) == nil

		:supervisor.start_child Sgs.Supervisor, Supervisor.Spec.worker(GS1, [:my_name], [id: :my_name,  restart: :temporary])
		assert :erlang.whereis(:my_name) != :undefined
		assert GS1.kill(:my_name, :my_reason)
		:timer.sleep(2000)
		assert Exdk.get(:my_name) == :not_found
		assert :erlang.whereis(:my_name) == :undefined

		:supervisor.start_child Sgs.Supervisor, Supervisor.Spec.worker(GS1, [:some_other_name], [id: :some_other_name,  restart: :temporary])
		assert :erlang.whereis(:some_other_name) != :undefined
		assert GS1.kill(:some_other_name, :some_other_reason)
		:timer.sleep(2000)
		assert Exdk.get(:some_other_name) == %{nameproc: :some_other_name, state: 2}
		assert :erlang.whereis(:some_other_name) == :undefined
		Exdk.delete(:some_other_name)
		assert (Exdk.get(@daemon) |> HashUtils.get(:some_other_name) |> HashUtils.set([timestamp: 0])) == %Sgs.SgsInfo{nameproc: :some_other_name, cleanup_delay: :infinity, cleanup_reasons: [:my_reason, :normal], terminate_was_called: true}
	end


end