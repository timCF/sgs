Sgs
===

Just wrapper under ExActor.GenServer , it keep its state on HD (using ets, that saves to HD in some period). Now is one condition to successful using: DO NOT use pattern matching in opts of macros.

Example of good usage:

defmodule CompileTest do

	use Sgs.Macro
	
	@timeout :timer.seconds(10)

	init_sgs state: state do
		IO.puts "HELLO, WORLD!"
		IO.puts "Init state is #{inspect state}"
		IO.puts "If state not defined in DB, set it 0"
		{:ok , 0, @timeout}
	end

	cast_sgs reset_state do
		IO.puts "set state to 0"
		{:noreply, 0, @timeout}
	end

	call_sgs add_to_state(arg1), state: state do
		IO.puts "args are:"
		IO.inspect arg1
		IO.puts "state now is #{state+10}"
		{:reply, state+10, state+10, @timeout}
	end

	info_sgs :timeout, state: some_state do
		IO.puts "timeout!"
		IO.puts "auto increment of state: #{some_state+1}"
		{:noreply, some_state+1, @timeout}
	end

	terminate_sgs reason: reason, state: state do
		IO.puts "Terminating becouse of reason #{inspect reason}, when state was #{inspect state}"
	end

end

But NEVER write something like:

	terminate_sgs reason: reason, state: %{field1: 1, field2: some_else} do
		IO.puts "Terminating becouse of reason #{inspect reason}, when state was #{inspect state}"
	end