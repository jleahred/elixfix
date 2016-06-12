defmodule  FMsgMapSupport do
  @moduledoc """
Support functions to deal with fix msg_map

    """




@doc """
Check if tag has value on msg_map

It will receive previous errors and will add current error to this list if
necessary.

    iex> msg_map = FMsgParse.parse_string_test(
    ...> "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|"<>
    ...> "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|"<>
    ...> "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
    ...> .parsed.msg_map
    iex> {_, errors} = FMsgMapSupport.check_tag_value({msg_map, []}, :BeginString, "FIX.4.4")
    iex> errors
    []

    iex> msg_map = FMsgParse.parse_string_test(
    ...> "8=FIX.4.1|9=122|35=D|34=215|49=CLIENT12|"<>
    ...> "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|"<>
    ...> "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
    ...> .parsed.msg_map
    iex> {_, errors} = FMsgMapSupport.check_tag_value({msg_map, []}, :BeginString, "FIX.4.4")
    iex> errors
    [" invalid tag value on: BeginString(8)  received: FIX.4.1, expected  FIX.4.4"]
"""
def check_tag_value({msg_map, errors}, tag, value) do
  if msg_map[tag] != value do
    {msg_map, errors ++ [" invalid tag value on: #{FTags.get_name(tag)}  " <>
                if tag == :RawData  or  tag == :Password do
                  ""
                else
                  "received: #{msg_map[tag]}, expected  #{value}"
                end
    ]}
  else
    {msg_map, errors}
  end
end


@doc """
Return int from tag

It will return

> { :ok, int_val }
>
> { :error, description }


    iex> msg_map = FMsgParse.parse_string_test(
    ...> "8=FIX.4.1|9=122|35=D|34=215|49=CLIENT12|"<>
    ...> "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|"<>
    ...> "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
    ...> .parsed.msg_map
    iex> FMsgMapSupport.get_tag_value_mandatory_int(:ClOrdID, msg_map)
    {:ok, 13346}
    iex> FMsgMapSupport.get_tag_value_mandatory_int(:TargetCompID, msg_map)
    {:error, "invalid val on tag TargetCompID(56)"}

"""
def get_tag_value_mandatory_int(tag, msg_map)  do
  try do  # better performance than  Integer.parse
    {:ok, String.to_integer(msg_map[tag])}
  rescue
    _  ->   {:error, "invalid val on tag #{FTags.get_name(tag)}"}
  end
end


@doc ~S"""
This will check if all tags exists in message parsed

    iex> msg_map = FMsgParse.parse_string_test(
    ...> "8=FIX.4.1|9=122|35=D|34=215|49=CLIENT12|"<>
    ...> "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|"<>
    ...> "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
    ...> .parsed.msg_map
    iex> {_,  errors} = FMsgMapSupport.check_mandatory_tags({msg_map, []},
    ...> [:BeginString, :BodyLength, :SenderCompID, :TargetCompID, :MsgSeqNum, :SendingTime, 999])
    iex> errors
    ["missing tag 999."]

"""
def check_mandatory_tags({msg_map, errors}, tags) do
    check_mand_tag = fn(tag, errs) ->
                        if(Map.has_key?(msg_map,  tag) == false) do
                            errs ++ ["missing tag #{FTags.get_name(tag)}."]
                        else
                            errs
                        end
                      end
    {msg_map, Enum.reduce(tags,
                 errors,
                 fn(tag, errs_acc) ->
                          check_mand_tag.(tag, errs_acc)  end)}
end


end
