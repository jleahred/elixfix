defmodule FMsgParse do
@moduledoc """
Pure functions to parse FIX messages

  In this module we have the functions (quite pure) to parse FIX messages.

  The main is  add_char(status, char)

  It will return the new status


  """


  defprotocol Status do
    @moduledoc """
On protocol Status. It will run commom operations for all status
(over Parsed struct).

For example, adding char to orig_msg or increasing possition
    """
    def process_char_chunkparsed(status, char)
  end

  #######################################################3
  defmodule Parsed do
  @moduledoc """
  Struct with parsed info

  It contains the info parsed till now

  click on source link to see the definition
  """
    defstruct   msg_map:    %{},
                body_length:  0,
                check_sum:    0,
                num_tags:     0,
                orig_msg:    "",
                errors:      [],  #{pos, description}
                position:     0
  end



  @doc false
  def process_char_chunkparsed(parsed, char) do
    ch = if char == 1, do: "^", else: <<char>>
    %Parsed{parsed |
            position: parsed.position + 1,
            orig_msg: parsed.orig_msg <> ch
    }
  end

  #######################################################3
  # the message has been successfully parsed
  defmodule StFullMessage do
    @moduledoc false
    defstruct parsed: %Parsed{}
  end

  defimpl Status, for: StFullMessage do
    def process_char_chunkparsed(status, char) do
      %StFullMessage {
          status  |
          parsed: FMsgParse.process_char_chunkparsed(status.parsed, char)
      }
    end
  end

  #######################################################3
  # receiving a tag
  # on chunk, we will add chars to tag
  defmodule StPartTag do
    @moduledoc false
    defstruct parsed: %Parsed{}, chunk: ""
  end

  defimpl Status, for: StPartTag do
    def process_char_chunkparsed(status, char) do
      %StPartTag {
          status  |
          parsed: FMsgParse.process_char_chunkparsed(status.parsed, char)
      }
    end
  end

  #######################################################3
  #  receiving a value (right to =)
  # on chunk, we will ad chars to val
  # and we have the current tag on tag field
  defmodule StPartVal do
    @moduledoc false
    defstruct parsed: %Parsed{}, tag: 0, chunk: ""
  end

  defimpl Status, for: StPartVal do
    def process_char_chunkparsed(status, char) do
      %StPartVal {
          status  |
          parsed: FMsgParse.process_char_chunkparsed(status.parsed, char)
      }
    end
  end




  defp add_error_list(error_list, {pos, new_error_desc})  do
    if new_error_desc != "" do
        cond  do
          Enum.count(error_list) <  3 ->   error_list ++ [{pos, new_error_desc}]
          Enum.count(error_list) == 3 ->   error_list ++ [{pos, new_error_desc}]
                                                      ++ [{pos, "too may errors"}]
          true                        ->   error_list
        end
    else
        error_list
    end
  end

  defmacrop add_err_st(error_desc) do
    if error_desc != "" do
      quote do
          add_error_list(var!(parsed).errors,
                          {var!(parsed).position,
                           unquote(error_desc)
                          })
      end
    else
        quote do
          var!(parsed).errors
        end
    end
  end



  @doc ~S"""
Add a new char msg to already received chunk

First parameter is status, the second one is the character to be added.

It will return the new status


Status could be...

* StPartTag -> reading a tag
* StPartVal -> reading a value (after =)
* StFullMessage -> a message has been completed
* All status has the field parsed of type Parsed with the parsed info



##  Examples

    iex> msg =  "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|"
    iex> msg_list = String.to_char_list(String.replace(msg, "|", <<1>>))
    iex> msg_list |> Enum.reduce(%FMsgParse.StFullMessage{}, &(FMsgParse.add_char(&2, &1)))
    %FMsgParse.StFullMessage{parsed: %FMsgParse.Parsed{body_length: 122,
      check_sum: 72, errors: [],
      msg_map: %{:Account => "Marcel", :BeginString => "FIX.4.4", :BodyLength => "122",
               :CheckSum => "072", :ClOrdID => "13346", :HandlInst => "1", :MsgSeqNum => 215,
               :MsgType => "D", :OrdType => "2", :Price => "5", :SenderCompID => "CLIENT12",
               :SendingTime => "20100225-19:41:57.316", :Side => "1", :TargetCompID => "B",
               :TimeInForce => "0", :TransactTime => "20100225-19:39:52.020"}, num_tags: 15,
             orig_msg: "8=FIX.4.4^9=122^35=D^34=215^49=CLIENT12^52=20100225-19:41:57.316^56=B^1=Marcel^11=13346^21=1^40=2^44=5^54=1^59=0^60=20100225-19:39:52.020^10=072^",
             position: 145}}

    iex> FMsgParse.add_char(%FMsgParse.StFullMessage{}, ?8)
    %FMsgParse.StPartTag{chunk: "8",
     parsed: %FMsgParse.Parsed{body_length: 1, check_sum: 56, errors: [],
      msg_map: %{}, num_tags: 0, orig_msg: "8", position: 1}}

"""

  def add_char(status, char) do
    _add_char(
            Status.process_char_chunkparsed(status, char),
            char)
  end


  defp _add_char(%StFullMessage{parsed: parsed}, 1)  do
    %StFullMessage{
      parsed: %Parsed
               {parsed  |
                errors: add_err_st("Invalid SOH after full message recieved")
              }
    }
  end

  defp _add_char(%StFullMessage{parsed: _parsed}, ch)  do
      add_char(%StPartTag{}, ch)
  end

  defp _add_char(%StPartTag{parsed: parsed, chunk: chunk}, ?=)  do
      try do  # better performance than  Integer.parse
        tag = String.to_integer(chunk)
        body_length = if tag == FTags.get_num(:CheckSum)
                          or tag == FTags.get_num(:BeginString)
                          or tag == FTags.get_num(:BodyLength)    do
                       parsed.body_length - String.length(chunk)
                     else
                       parsed.body_length + 1
                     end
        check_sum = rem(
                     if tag == FTags.get_num(:CheckSum) do
                       parsed.check_sum + 256 + 256 - ?1 -?0
                     else
                       parsed.check_sum + ?=
                      end,
                    256)

        %StPartVal {
          parsed: %Parsed
                    {parsed  |
                     body_length:  body_length,
                     check_sum:    check_sum,
                     errors:
                          if(chunk == "")  do
                              add_err_st("Ending empty tag")
                          else parsed.errors
                          end
                    },
          tag: FTags.get_atom(tag),
          chunk: ""
        }
      rescue
        _ ->
          %StPartVal {
            parsed: %Parsed
                       {parsed  |
                        errors:      add_err_st("invalid tag value #{chunk}")
                       },
            tag: 0,
            chunk: ""
          }
      end
  end


  defp _add_char(%StPartTag{parsed: parsed, chunk: chunk}, 1)  do
      %StPartTag {
        parsed: %Parsed
                     {parsed |
                      errors:    add_err_st(
                                    "Invalid SOH on #{chunk} waiting for tag")#,
                     },
        chunk: ""
      }
  end

  defp _add_char(%StPartTag{parsed: parsed, chunk: chunk}, ch)  do
      %StPartTag {
        parsed: %Parsed
                      {parsed |
                       body_length: parsed.body_length + 1,
                       check_sum: rem(parsed.check_sum + ch, 256)
                      },
        chunk: chunk <> <<ch>>
      }
  end


  defp _add_char(%StPartVal{parsed: parsed, tag: :CheckSum, chunk: chunk}, 1)  do
      bl =  string2integer(parsed.msg_map[:BodyLength])
      check_sum = string2integer(chunk)
      error = cond do
          parsed.body_length != bl       ->
                "Incorrect body length  calculated: #{parsed.body_length} received #{bl}"
          check_sum == -1    ->
                "Error parsing checksum chs: #{chunk}"
          parsed.check_sum  != check_sum ->
                "Incorrect checksum calculated: #{parsed.check_sum} received #{check_sum}  chunk:#{chunk}"
          true  -> ""
      end
      error = error <> "#{check_full_message(parsed)}"
      %StFullMessage {
          parsed: %Parsed {parsed |
                           msg_map: Map.put(parsed.msg_map, :CheckSum, chunk),
                           errors:  add_err_st(error)
                          }
      }
  end

  defp _add_char(%StPartVal{parsed: parsed, tag: tag, chunk: chunk}, 1)  do
    error = cond do
        tag != :BeginString and parsed.num_tags == 0  ->  "First tag has to be BeginString"
        tag != :BodyLength and parsed.num_tags == 1  ->  "Second tag has to be BodyLength"
        tag == :BeginString and parsed.num_tags != 0  ->  "Tag BeginString has to be on position 1"
        tag == :BodyLength and parsed.num_tags != 1  ->  "Tag BodyLength has to be on position 2"
        true                               ->  ""
    end
    add_body_length = if tag == :BeginString  or tag == :BodyLength, do: 0, else: 1
    value = if tag != :MsgSeqNum  do
                chunk
            else
                try do  # better performance than  Integer.parse
                    value = String.to_integer(chunk)
                rescue
                  _  ->   "Error:#{chunk}"
                end
            end

    %StPartTag {
      parsed: %Parsed
                  {parsed |
                   body_length: parsed.body_length + add_body_length,
                   check_sum: rem(parsed.check_sum + 1, 256),
                   msg_map: Map.put(parsed.msg_map, tag, value),
                   num_tags:  parsed.num_tags + 1,
                   errors:    add_err_st(error)
                  },
      chunk: ""
    }
  end

  defp _add_char(%StPartVal{parsed: parsed, tag: tag, chunk: chunk}, ch)  do
    bl = if(tag == :BeginString or tag == :BodyLength or tag == :CheckSum, do: 0, else: 1)
    check_sum = if(tag != :CheckSum, do: rem(parsed.check_sum + ch, 256), else: parsed.check_sum)
    %StPartVal {
      parsed: %Parsed{parsed |
                      body_length: parsed.body_length + bl,
                      check_sum: check_sum
                      },
      tag: FTags.get_atom(tag),
      chunk: chunk <> <<ch>>
    }
  end







  def test_parse_string do
      msg = "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|"
      msg_list = String.to_char_list(String.replace(msg, "|", <<1>>))

      msg_list |> Enum.reduce(%StFullMessage{}, &(_add_char(&2, &1)))
  end

  def test_parse_string_perf do
      msg = "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|"
      msg_list = String.to_char_list(String.replace(msg, "|", <<1>>))

      num_msg = 100_000

      funt = fn -> Enum.each(1..num_msg,
          fn(_) -> msg_list |> Enum.reduce(%StFullMessage{}, &(_add_char(&2, &1))) end)
        end

      secs = funt
              |> :timer.tc
              |>  elem(0)
              |>  Kernel./(1_000_000)

      IO.puts "total time #{secs} sec"
      IO.puts "#{num_msg/secs} msg/sec"
  end

  defp check_full_message(parsed) do
      {_, errors} =
        {parsed.msg_map, []}
        |>  FMsgMapSupport.check_mandatory_tags([:BeginString,
                                                 :BodyLength,
                                                 :SenderCompID,
                                                 :TargetCompID,
                                                 :MsgSeqNum,
                                                 :SendingTime])
      Enum.join(errors, ", ")
  end


  @doc """
  Convert a string to a fix msg_map struct

  It is for testing support


  """
  def parse_string_test(string, sep\\"|") do
    list = String.to_char_list(String.replace(string, sep, <<1>>))
    list |> Enum.reduce(%FMsgParse.StFullMessage{},
                                      &(FMsgParse.add_char(&2, &1)))
  end

  defp  string2integer(string)   do
    try do
        String.to_integer(string)
    rescue
      _  ->  -1
    end
  end

end
