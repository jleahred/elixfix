defmodule  FSession.Support  do
@moduledoc """
Support pure functions to work with Sessions
"""

  @doc """
  It will return a set of tags for session message reject

  You have to provide:

  * Description
  * Original message
  * Reject code
      * 5 : Incorrect value
      * 6 : Incorrect data format for a tag value
      * 9 : CompID problem

  example:

      iex> original_message = %{:MsgType => "3", :MsgSeqNum => "101", :RefMsgType => "B"}
      iex> FSession.Support.reject_msg("Testing reject", original_message)
      %{
          :MsgType => "3",
          :RefMsgType => "B",
          :RefSeqNum => "101",
          :Text => "Testing reject"
      }
  """
  def  reject_msg(description, original_message)  do
      %{
          :MsgType => "3",
          :RefSeqNum => original_message[:MsgSeqNum],
          :Text => description,
          :RefMsgType => original_message[:RefMsgType]
      }
  end

  @doc """
  It will return a set of tags for RequestResend

  You have to provide:

  * BeginSeqNum
  * EndSeqNum

  example:

      iex> FSession.Support.request_resend("101", "314")
      %{:MsgType => "2",
        :BeginSeqNo => "101",
        :EndSeqNo => "314"}
  """
  def  request_resend(begin_seq_num, end_seq_num) do
    %{
        :BeginSeqNo => begin_seq_num,
        :EndSeqNo => end_seq_num,
        :MsgType => "2"
    }
  end


  def confirm_login_msg(heart_beat) do
    %{
        :EncryptMethod => "0",
        :HeartBtInt => heart_beat,
        :MsgType => "A"
    }
  end
end
