

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
		
		#pid = spawn_link( Sgs.Macro, :priv_funcs_writer, [quote do end] )
		#:pg2.join( "priv_funcs_writer", pid )

		quote do 
			use ExActor.GenServer
			use Sgs
			import Sgs.Macro

			#
			# init here
			#

			defp init_return( {:ok, state}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.put(name, state |> __reserve_save_state__(name))
				end
				{:ok, name}
			end
			defp init_return( {:ok, state, some}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.put(name, state |> __reserve_save_state__(name))
				end
				{:ok, name, some}
			end

			#
			# TODO: fix it!!!
			#

			defp init_return( some_else, _name ) do
				some_else
			end
			# force init_here
			defp force_init_return( {:ok, state}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.putf(name, state |> __reserve_save_state__(name))
				end
				{:ok, name}
			end
			defp force_init_return( {:ok, state, some}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.putf(name, state |> __reserve_save_state__(name))
				end
				{:ok, name, some}
			end

			#
			# TODO : fix it!
			#


			defp force_init_return( some_else, _name ) do
				some_else
			end

			#
			# cast and info here
			#

			defp cast_info_return( {:noreply, state}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:noreply, name}
			end
			defp cast_info_return( {:noreply, state, some}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:noreply, name, some}
			end
			defp cast_info_return( {:stop, reason, state}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:stop, reason, name}
			end
			# force cast and info here
			defp force_cast_info_return( {:noreply, state}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:noreply, name}
			end
			defp force_cast_info_return( {:noreply, state, some}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:noreply, name, some}
			end
			defp force_cast_info_return( {:stop, reason, state}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:stop, reason, name}
			end

			#
			# call here
			#

			defp call_return( {:reply, reply, state}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:reply, reply, name}
			end
			defp call_return( {:reply, reply, state, some}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:reply, reply, name, some}
			end
			defp call_return( {:noreply, state}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:noreply, name}
			end
			defp call_return( {:noreply, state, some}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:noreply, name, some}
			end
			defp call_return( {:stop, reason, reply, state}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:stop, reason, reply, name}
			end
			defp call_return( {:stop, reason, state}, name ) do
				Exdk.put(name, state |> __reserve_save_state__(name))
				{:stop, reason, name}
			end
			# force call here
			defp force_call_return( {:reply, reply, state}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:reply, reply, name}
			end
			defp force_call_return( {:reply, reply, state, some}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:reply, reply, name, some}
			end
			defp force_call_return( {:noreply, state}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:noreply, name}
			end
			defp force_call_return( {:noreply, state, some}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:noreply, name, some}
			end
			defp force_call_return( {:stop, reason, reply, state}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:stop, reason, reply, name}
			end
			defp force_call_return( {:stop, reason, state}, name ) do
				Exdk.putf(name, state |> __reserve_save_state__(name))
				{:stop, reason, name}
			end

			# here we define terminator by default
			def terminate( reason, nameproc ) do
				terminate_body( nameproc, Exdk.get(nameproc), reason )
			end
			terminate_sgs [] do end

			# here we define reserve_save callback by default
			defp __reserve_save_state__( state, nameproc ) do
				reserve_save_state_body( state, nameproc )
			end
			defp reserve_save_state_body( state, nameproc ) do
				state
			end

		end
	end

	# I mean use it for reserve copy, but you can use it any way you want
	defmacro reserve_sgs(opts \\ [], [do: body]) do
		__nameproc__ = opts[:nameproc]
		__state__ = opts[:state]
		__guard__ = opts[:when]
		__change_state__ = case opts[:change_state] do
							true -> true
							false -> false
							nil -> false
						 end
		if (__nameproc__ == nil or __state__ == nil) do
			raise "You must define nameproc and state in reserve_sgs macro"
		end

		# maybe not body - here must be all func?
		case __change_state__ do
			true -> quote do
						defp reserve_state_body( unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
												unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do
							unquote(body)
						end
					end
			false -> quote do
						defp reserve_state_body( unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
												unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do
							unquote(body)
							__state__
						end
					end
		end

	end

	defmacro init_sgs(opts \\ [], [do: body]) do

		__nameproc__ = opts[:nameproc]
		__state__ = opts[:state]
		__guard__ = opts[:when]
		__cleanup_delay__ = case opts[:cleanup_delay] do
								nil -> :infinity
								num when is_integer(num) -> num
							end
		__cleanup_reasons__ = case opts[:cleanup_reasons] do
								nil -> []
								lst when is_list(lst) -> lst
								some -> [some]
							end
		__force_save__ = get_force_save_settings(opts[:force_save])


		# here we get struct with some pre-compiled field values
		__sgsinfo__ = 	quote do
							%Sgs.SgsInfo{
							nameproc: nil,
							timestamp: 0,
							cleanup_delay: unquote(__cleanup_delay__), 
	              			cleanup_reasons: unquote(__cleanup_reasons__),
	              			terminate_was_called: false }
              			end

        return_function = case __force_save__ do
        							true -> quote do 
												Sgs.CleanupDaemon.sync_send_info( HashUtils.set( unquote(__sgsinfo__), [nameproc: __nameproc__, timestamp: makestamp ] ) )
        										force_init_return( unquote(body), __nameproc__ ) end
        							false -> quote do 
        										Sgs.CleanupDaemon.send_info( HashUtils.set( unquote(__sgsinfo__), [nameproc: __nameproc__, timestamp: makestamp ] ) )
        										init_return( unquote(body), __nameproc__ )
        									end
        						end

        priv_function_body = quote do
			defp definit_body( 	unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
								unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do
				:erlang.register(__nameproc__, self())
				# here do call - wait of cleanup if it's needed
				Sgs.CleanupDaemon.send_init_signal( __nameproc__ )
				# here do call or cast to cleanup daemon in case of force option == true or false
				unquote(return_function)
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
		__force_save__ = get_force_save_settings(opts[:force_save])
		{__funcname__, _, _} = funcdef

		return_function = case __force_save__ do
							true -> quote do force_cast_info_return(unquote(body), __nameproc__) end
							false -> quote do cast_info_return(unquote(body), __nameproc__) end
						end

		priv_function_body = quote do
			defp defcast_body( 	unquote(__funcname__),
								unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
								unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do
				unquote(return_function)
			end
		end |> insert_user_args(funcdef)

		quoted_func_call = quote do defcast_body( unquote(__funcname__), name, Exdk.get(name)) end |> insert_user_args_fo_func_call(funcdef)

        #send :pg2.get_members("priv_funcs_writer")
		#		|> List.first, %{quoted_to_append: priv_function_body}

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
		__force_save__ = get_force_save_settings(opts[:force_save])
		{__funcname__, _, _} = funcdef

		return_function = case __force_save__ do
							true -> quote do force_call_return(unquote(body), __nameproc__) end
							false -> quote do call_return(unquote(body), __nameproc__) end
						end

		priv_function_body = quote do
			defp defcall_body( 	unquote(__funcname__),
								unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
								unquote(do_pattern_matching( quote do __state__ end, __state__)) ) when unquote(make_guard(__guard__)) do
				unquote(return_function)
			end
		end |> insert_user_args(funcdef)

		quoted_func_call = quote do defcall_body( unquote(__funcname__), name, Exdk.get(name)) end |> insert_user_args_fo_func_call(funcdef)
        
        #send :pg2.get_members("priv_funcs_writer")
		#		|> List.first, %{quoted_to_append: priv_function_body}

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
		__force_save__ = get_force_save_settings(opts[:force_save])

		return_function = case __force_save__ do
							true -> quote do force_cast_info_return(unquote(body), __nameproc__) end
							false -> quote do cast_info_return(unquote(body), __nameproc__) end
						end

		priv_function_body = quote do
			defp definfo_body( 	unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
								unquote(do_pattern_matching( quote do __state__ end, __state__)),
								unquote(some)   ) when unquote(make_guard(__guard__)) do
				unquote(return_function)
			end
		end

        #send :pg2.get_members("priv_funcs_writer")
		#		|> List.first, %{quoted_to_append: priv_function_body}

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
		__force_save__ = get_force_save_settings(opts[:force_save])

		call_to_daemon = case __force_save__ do
							true -> quote do Sgs.CleanupDaemon.send_terminate_reason_force( __reason__, __nameproc__ ) end
							false -> quote do Sgs.CleanupDaemon.send_terminate_reason( __reason__, __nameproc__ ) end
						end

		quote do
			defp terminate_body( 	unquote(do_pattern_matching( quote do __nameproc__ end, __nameproc__ )),
									unquote(do_pattern_matching( quote do __state__ end, __state__)),
									unquote(do_pattern_matching( quote do __reason__ end, __reason__))   ) when unquote(make_guard(__guard__)) do
				unquote(body)
				# call here, wait for cleanup if it need
				unquote(call_to_daemon)
			end
		end

        #send :pg2.get_members("priv_funcs_writer")
		#		|> List.first, %{quoted_to_append: priv_function_body}

	end

	#defmacro end_sgs do
	#	send :pg2.get_members("priv_funcs_writer")
	#			|> List.first, %{ give_result_to: self }
	#	
	#	res = receive do
	#		%{ quoted_result: collected } -> :pg2.delete("priv_funcs_writer")
	#										 quote do unquote(collected) end
	#	end
	#
	#	#IO.puts Macro.to_string(res)
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

	defp get_force_save_settings( nil ) do
		false
	end
	defp get_force_save_settings( some ) when is_boolean( some ) do
		some
	end

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