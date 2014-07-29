defmodule CompileTest do

	use Sgs.Macro
	
	@timeout :timer.seconds(10)

	init_sgs do
		IO.puts "HELLO, WORLD!"
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

	# if you are not need this GS over, cleanup disk using function cleanup_sgs(key)


end