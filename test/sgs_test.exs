defmodule SgsTest do
  use ExUnit.Case

	defmodule StorageTest do

		use Sgs.Macro
		
		@timeout :timer.seconds(10)

		init_sgs state: state = %{nameproc: name, state: num}, nameproc: name, cleanup_reasons: [:my_reason, :normal] do
			{:ok , state}
		end
		init_sgs state: :not_found, nameproc: :my_name, cleanup_reasons: [:my_reason, :normal] do
			{:ok , %{nameproc: :my_name, state: 1}}
		end
		init_sgs state: :not_found, nameproc: name, cleanup_reasons: [:my_reason, :normal] do
			{:ok , %{nameproc: name, state: 0}}
		end

		call_sgs kill(reason), state: state = %{} do
			{:stop, reason, true, state}
		end
		call_sgs get_state, state: state = %{} do
			{:reply, state, state}
		end

		def test do
			:supervisor.start_child Sgs.Supervisor, Supervisor.Spec.worker(Sgs.CompileTest, [:my_name], [id: :my_name,  restart: :transient])
			results = [Exdk.get(:my_name)==%{nameproc: :my_name, state: 0}]
			results = results++[Sgs.CompileTest.kill(:my_reason)]
		end
	end

	test "the truth" do
		:supervisor.start_child Sgs.Supervisor, Supervisor.Spec.worker(Sgs.CompileTest, [:my_name], [id: :my_name,  restart: :transient])
		assert :erlang.whereis(:my_name) != :undefined
	end
  
end