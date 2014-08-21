

defmodule Sgs.Macro do

	#def priv_funcs_writer collected \\ (quote do end) do
	#	receive do
	#		%{ quoted_to_append: incoming } -> 	priv_funcs_writer( quote do  
	#														unquote(collected)
	#														unquote(incoming)
	#													end )
	#		%{ give_result_to: pid } -> send( pid, %{ quoted_result: collected } )
	#									:pg2.leave( "priv_funcs_writer", self )
	#	end
	#end

	defmacro __using__(_) do

		#:pg2.create "priv_funcs_writer"
		#
		#pid = spawn_link( Sgs.Macro, :priv_funcs_writer, [quote do end] )
		#:pg2.join( "priv_funcs_writer", pid )

		quote do 
			use ExActor.GenServer
			use Sgs
			import Sgs.Macro

			# init here
			defp init_return( {:ok, state}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.put(name, state)
				end
				{:ok, name}
			end
			defp init_return( {:ok, state, some}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.put(name, state)
				end
				{:ok, name, some}
			end
			defp init_return( some_else, _name ) do
				some_else
			end


			# cast and info here
			defp cast_info_return( {:noreply, state}, name ) do
				Exdk.put(name, state)
				{:noreply, name}
			end
			defp cast_info_return( {:noreply, state, some}, name ) do
				Exdk.put(name, state)
				{:noreply, name, some}
			end
			defp cast_info_return( {:stop, reason, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, name}
			end


			#call here
			defp call_return( {:reply, reply, state}, name ) do
				Exdk.put(name, state)
				{:reply, reply, name}
			end
			defp call_return( {:reply, reply, state, some}, name ) do
				Exdk.put(name, state)
				{:reply, reply, name, some}
			end
			defp call_return( {:noreply, state}, name ) do
				Exdk.put(name, state)
				{:noreply, name}
			end
			defp call_return( {:noreply, state, some}, name ) do
				Exdk.put(name, state)
				{:noreply, name, some}
			end
			defp call_return( {:stop, reason, reply, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, reply, name}
			end
			defp call_return( {:stop, reason, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, name}
			end

			terminate_sgs [] do end
			defoverridable [ terminate: 2 ]

		end
	end

	#
	# TODO : daemon to cleanup
	#

	defmacro init_sgs(opts \\ [], [do: body]) do

		__nameproc__ = opts[:nameproc]
		__state__ = opts[:state]
		__guard__ = opts[:when]
		__cleanup_delay__ = make_cleanup_delay( opts[:cleanup_delay] )
		__cleanup_reasons__ = make_cleanup_reasons( opts[:cleanup_reasons] )

		# here we get struct with some pre-compiled field values
		__sgsinfo__ = 	quote do
							%Sgs.SgsInfo{
							nameproc: nil,
							timestamp: 0,
							cleanup_delay: unquote(__cleanup_delay__), 
	              			cleanup_reasons: unquote(__cleanup_reasons__),
	              			terminate_was_called: false }
              			end

        priv_function_body = quote do
			defp definit_body( 	unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
								unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do
				:erlang.register(__nameproc__, self())
				# here do call - wait of cleanup if it's needed
				Sgs.CleanupDaemon.send_init_signal( __nameproc__ )
				# here do cast - just send some info
				Sgs.CleanupDaemon.send_info( HashUtils.set( unquote(__sgsinfo__), [nameproc: __nameproc__, timestamp: makestamp ] ) )
				# here we just do some work and init state if it necessary
				init_return( unquote(body), __nameproc__ )
			end
		end

        #send :pg2.get_members("priv_funcs_writer")
		#		|> List.first, %{quoted_to_append: priv_function_body}

		quote do
			# notice, GS is named, name !!is atom!! 
			definit name, when: is_atom(name), do: ( definit_body( name, Exdk.get(name)) )
			unquote(priv_function_body)
		end
	end

	defmacro cast_sgs(funcdef, opts \\ [], [do: body]) do


		__nameproc__ = opts[:nameproc]
		__state__ = opts[:state]
		__guard__ = opts[:when]

		priv_function_body = quote do
			defp defcast_body( 	unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
								unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do

				cast_info_return(unquote(body), __nameproc__) # cast and info return values are the same
			end
		end |> insert_user_args(funcdef)

		quoted_func_call = quote do defcast_body( name, Exdk.get(name)) end |> insert_user_args_fo_func_call(funcdef)

		quote do
			defcast	unquote(funcdef), state: name do
				unquote(quoted_func_call)
			end
			unquote(priv_function_body)
		end

	end

	defmacro call_sgs(funcdef, opts \\ [], [do: body]) do


		__nameproc__ = opts[:nameproc]
		__state__ = opts[:state]
		__guard__ = opts[:when]

		priv_function_body = quote do
			defp defcall_body( 	unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
								unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do
				call_return(unquote(body), __nameproc__)
			end
		end |> insert_user_args(funcdef)

		quoted_func_call = quote do defcall_body(name, Exdk.get(name)) end |> insert_user_args_fo_func_call(funcdef)

		quote do
			defcall	unquote(funcdef), state: name do
				unquote(quoted_func_call)
			end
			unquote(priv_function_body)
		end

	end

	defmacro info_sgs(some, opts \\ [], [do: body]) do

		__nameproc__ = opts[:nameproc]
		__state__ = opts[:state]
		__guard__ = opts[:when]

		priv_function_body = quote do
			defp definfo_body( 	unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
								unquote(do_pattern_matching( quote do __state__ end, __state__)),
								unquote(some)   ) when unquote(make_guard(__guard__)) do
				cast_info_return(unquote(body), __nameproc__) 
			end
		end

		quote do
			definfo	unquote(some), state: name do
				definfo_body(name, Exdk.get(name), unquote(some))
			end
			unquote(priv_function_body)
		end 

	end


	defmacro terminate_sgs opts \\ [], [do: body] do

		__nameproc__ = opts[:nameproc]
		__state__ = opts[:state]
		__guard__ = opts[:when]
		__reason__ = opts[:reason]

		priv_function_body = quote do
			defp terminate_body( 	unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
									unquote(do_pattern_matching( quote do __state__ end, __state__)),
									unquote(do_pattern_matching( quote do __reason__ end, __reason__))   ) when unquote(make_guard(__guard__)) do
				unquote(body)
				# call here, wait for cleanup if it need
				Sgs.CleanupDaemon.send_terminate_reason( __reason__, __nameproc__ )
			end
		end

		quote do
			def terminate( reason, nameproc ) do
				terminate_body( nameproc, Exdk.get(nameproc), reason )
			end
			unquote(priv_function_body)
		end
	end

	#defmacro end_compilation do
	#	send :pg2.get_members("priv_funcs_writer")
	#			|> List.first, %{ give_result_to: self }
	#	
	#	res = receive do
	#		%{ quoted_result: collected } -> :pg2.delete("priv_funcs_writer")
	#										 quote do unquote(collected) end
	#	end
	#
	#	IO.puts Macro.to_string(res)
	#
	#	res
	#
	#end

	def cleanup_sgs(name) do
		Exdk.delete(name)
	end

	###############
	#### priv #####
	###############

	defp do_pattern_matching( argname, nil ) do
		argname
	end
	defp do_pattern_matching( argname, val_to_match ) do
		quote do unquote(argname) = unquote(val_to_match) end
	end

	defp make_guard( nil ) do
		quote do true end
	end
	defp make_guard( expr ) do
		expr
	end

	defp make_cleanup_delay( nil ) do
		:infinity
	end
	defp make_cleanup_delay( num ) when is_integer(num) do
		num
	end

	defp make_cleanup_reasons( nil ) do
		[ :normal ]
	end
	defp make_cleanup_reasons( lst ) when is_list(lst) do
		lst
	end
	defp make_cleanup_reasons( some ) do
		[ some ]
	end

	defp insert_user_args(quoted_defcast_body, {_, _, nil }) do

		quoted_defcast_body

		{ inner_info1, inner_info2 ,
			[ {inner_info3, inner_info4, 
				[ {inner_info5, inner_info6, arglist} | rest2 ]} | rest1 ] } = quoted_defcast_body

	end
	defp insert_user_args(quoted_defcast_body, {_, _, user_args }) do

		{ inner_info1, inner_info2 ,
			[ {inner_info3, inner_info4, 
				[ {inner_info5, inner_info6, arglist} | rest2 ]} | rest1 ] } = quoted_defcast_body

		{ inner_info1, inner_info2 ,
			[ {inner_info3, inner_info4, 
				[ {inner_info5, inner_info6, arglist++user_args} | rest2 ]} | rest1 ] } 

	end

	defp insert_user_args_fo_func_call( func_call, {_, _, nil }) do
		func_call
	end

	defp insert_user_args_fo_func_call( {inner1, inner2, arglst}, {_, _, user_args }) do
		{inner1, inner2, arglst++user_args}
	end

end