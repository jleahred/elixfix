defmodule  FSessionReceiver  do
@moduledoc """
Session receiver pure functions
"""
  import FMsgMapSupport, only: [check_tag_value: 3]

  defmodule Status do
    @moduledoc """
    Session receiver Status

    To see fields, click on source link

    """
    defstruct   state:            :waitting_login,   # :login_ok
                fix_version:      "",
                sender_comp_id:   "",
                target_comp_id:   "",
                password:         "",
                heartbeat_interv:  0,
                msg_seq_num:       1
  end






  @doc """
Process message and return new status and action

It will return the new status and action to be done (in a tuple)

>  { action, tuple }

Possible actions are:

    * nil
    * [reject_msg: description]
    * [reject_msg: description, disconnect: true]
    * [app_message: parsed_msg]
  """
  def process_message(status, msg_map) do
      {_, errors} =
        {msg_map, []}
        |>  check_tag_value(:BeginString,  status.fix_version)
        |>  check_tag_value(:SenderCompID, status.sender_comp_id)
        |>  check_tag_value(:TargetCompID, status.target_comp_id)

      if errors == []  do
          status = %Status{status |  msg_seq_num: status.msg_seq_num + 1}
          get_func_proc_msg(msg_map[:MsgType]).(status, msg_map)
      else
          {%Status {status |  msg_seq_num: status.msg_seq_num + 1},
             reject_msg: errors
          }
      end
  end


  defp get_func_proc_msg(msg_type) do
      case msg_type do
          "A"   ->  &logon/2
          "5"   ->  &logout/2
          "0"   ->  &heartbeat/2
          "1"   ->  &test_request/2
          "4"   ->  &sequence_reset/2
          "2"   ->  &resend_request/2
          "3"   ->  &session_level_reject/2
          _     ->  &not_session_message/2
      end
  end

  defp logon(status, msg_map)  do
    case status.state do
        :waitting_login   ->  Support.process_logon_on_waitlog(status, msg_map)
        :login_ok         ->
          {%Status {status | state: :waitting_login},
              reject_msg: "received rq login on login status. Disconecting..."
          }

    end
  end



  defp logout(_status, _msg_map)  do

  end

  defp heartbeat(_status, _msg_map)  do

  end

  defp test_request(_status, _msg_map)  do

  end

  defp sequence_reset(_status, _msg_map)  do

  end

  defp resend_request(_status, _msg_map)  do

  end

  defp session_level_reject(_status, _msg_map)  do

  end

  defp not_session_message(_status, _msg_map)  do

  end

end
