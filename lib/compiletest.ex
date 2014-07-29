defmodule CompileTest do

	use Sgs.Macro
	
	@timeout :timer.seconds(10)

	init_sgs do
		IO.puts "HELLO, WORLD!"
		{:ok , 0, @timeout}
	end

	cast_sgs do_cast(arg1, arg2) do
		IO.puts "args are:"
		IO.inspect arg1
		IO.inspect arg2
		IO.puts "state is #{state}"
		{:noreply, state-10, @timeout}
	end

	call_sgs do_call(arg1) do
		IO.puts "args are:"
		IO.inspect arg1
		IO.puts "state is #{state}"
		{:reply, state+10, state+10, @timeout}
	end

	info_sgs :timeout do
		IO.puts "timeout!"
		IO.puts "state is #{state}"
		{:noreply, state-1, @timeout}
	end
end