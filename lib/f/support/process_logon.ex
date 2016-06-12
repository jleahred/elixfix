defmodule  FSessionLogonMsg  do
    @moduledoc """
    Process Logon message
    """

    import FMsgMapSupport, only: [check_tag_value: 3,
                                  get_tag_value_mandatory_int: 2,
                                  check_mandatory_tags: 2]
    alias FSession.Support, as: FSS


    defp try({status, msg_map, actions, true}, function)  do
        function.({status, msg_map, actions, true})
    end

    defp try({status, msg_map, actions, false}, _function)  do
        {status, msg_map, actions, false}
    end

    @doc """
    Process logon message

    * params
        * Session.Status
        * message_map
    * returns
        * new status
        * list of actions
            * []
            * disconnect: true
            * send_message: msg
    """
    def process(status, msg_map) do
        case status.connect_role  do
            :acceptor ->
                case status.status do
                    :waitting_login  ->  process_waitting_logon(status, msg_map)
                    _                ->
                        {%Session.Status{status | status: :logout},
                          [send_message: FSS.reject_msg(
                              "Logon on invalid state #{status.status}", msg_map)]
                         ++ [disconnect: true]}
                end
            :initiator ->
                case status.status do
                    :waitting_login  ->  {%Session.Status{status |
                                          status: :login_ok}, []}
                    _                ->
                        {%Session.Status{status | status: :logout},
                          [send_message: FSS.reject_msg(
                              "Logon on invalid state #{status.status}", msg_map)]
                         ++ [disconnect: true]}
                end
        end
    end

    def process_waitting_logon(status, msg_map) do
        {_, errors} =
          {msg_map, []}
          |>  check_mandatory_tags([:Password, :EncryptMethod, :HeartBtInt])
          |>  check_tag_value(:Password,      status.password)
          |>  check_tag_value(:EncryptMethod, "0")

          {err_actions, continue} =  if errors == []  do
                                    {[], true}
                                else
                                    {[send_message: FSS.reject_msg(
                                          List.to_string(errors), msg_map)]
                                     ++ [disconnect: true], false}
                                end

          {fstatus, _, facctions, _} =
              {status, msg_map, err_actions, continue}
              |> try(&process_heart_beat/1)
              |> try(&process_reset_sequence/1)
              |> try(&generate_logon/1)
          {fstatus, facctions}
    end

    defp generate_logon({status, msg_map, actions, true})  do
        {%Session.Status{status | status: :login_ok},
         msg_map,
         actions ++
            [send_message: FSS.confirm_login_msg(status.heartbeat_interv)],
         true}
    end

    #@lint {~r/Refactor/, false}
    defp process_reset_sequence({status, msg_map, actions, true})  do
        rec_seq_num = msg_map[:MsgSeqNum]
        case Map.get(msg_map, :ResetSeqNumFlag, nil)  do
            "N" -> {status, msg_map, actions, true}
            nil -> {status, msg_map, actions, true}
            "Y" ->
              case rec_seq_num  do
                  1 ->  {reset_seq_nums(status),
                         msg_map, [], true
                        }
                  _ ->  {status, msg_map,
                         actions ++
                              [send_message: FSS.reject_msg(
                                                "Requested reset seq but" <>
                                                " received seq_num!=1",
                                                msg_map)] ++
                              [disconnect: true],
                         false
                        }
              end
        end
    end

    defp reset_seq_nums(status)  do
        %Session.Status{
            status |
            receptor_msg_seq_num:   1,
            sender_msg_seq_num:     1
        }
    end

    #@lint {~r/Refactor/, false}
    defp process_heart_beat({status, msg_map, actions, true})  do
        case get_tag_value_mandatory_int(:HeartBtInt, msg_map)  do
            {:ok,    val}   ->
                if val == status.heartbeat_interv  do
                      {status, msg_map, [], true}
                else
                      {status, msg_map,
                        actions ++
                              [send_message: FSS.reject_msg(
                                    "Invalid HeartBtInt " <>
                                    "#{val} " <>
                                    "expected #{status.heartbeat_interv}",
                                    msg_map)] ++
                              [disconnect: true],
                       false
                      }
                end

            {:error, desc}  ->   {status,
                                  msg_map,
                                  actions ++
                                    [send_message: FSS.reject_msg(
                                      "Invalid value on tag " <>
                                      "#{FTags.get_name(:HeartBtInt)}  #{desc}",
                                      msg_map)] ++
                                    [disconnect: true],
                                   false
                                  }
        end
    end

end
