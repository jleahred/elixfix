defmodule  FSessionProcessMsg  do
  @moduledoc """
  Process received message

  It will update status.seq_number and will process the session messages
  or will return not_session_msg:true
  """


  import FMsgMapSupport, only: [check_tag_value: 3]


  @doc """
  Process message and will return action to do

  * params
      * Session.Status
      * message_map
  * returns
      * new status
      * list of actions
          * []
          * disconnect: true
          * send_message: msg
          * not_session_msg: true
  """
  def process_message(status, msg_map) do
      status = %Session.Status{status |
                receptor_msg_seq_num: status.receptor_msg_seq_num + 1}
      {_, errors} = check_session_mandatory_tags(status, msg_map)
      if errors == []  do
          {status, get_func_proc_msg(msg_map[:MsgType]).(status, msg_map)}
      else
          {status,
           [send_message: FSS.reject_msg(
            "Logon on invalid state #{status.status}", msg_map)]}
      end
  end

  defp check_session_mandatory_tags(status, msg_map) do
      {msg_map, []}
      |>  check_tag_value(:BeginString,  status.fix_version)
      |>  check_tag_value(:SenderCompID, status.sender_comp_id)
      |>  check_tag_value(:TargetCompID, status.target_comp_id)
  end


  defp get_func_proc_msg(msg_type) do
      case msg_type do
          "A"   ->  &FSessionLogonMsg.process/2
          "5"   ->  &FSessionLogoutMsg.process/2
          "0"   ->  &heartbeat/2
          "1"   ->  &test_request/2
          "4"   ->  &sequence_reset/2
          "2"   ->  &resend_request/2
          "3"   ->  &session_level_reject/2
          _     ->  &not_session_message/2
      end
  end

  defp heartbeat(status, _msg_map)  do
      {status, []}
  end

  defp test_request(status, msg_map)  do
      {status, send_message:  %{
                :MsgType => "0",
                :TestReqID => msg_map[:TestReqID],
            }
}
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
