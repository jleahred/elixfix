defmodule FMsgMapSupportTest do
  use ExUnit.Case
  doctest FMsgMapSupport


  @msg_map2test FMsgParse.parse_string_test(
        "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|" <>
        "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|" <>
        "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
        .parsed.msg_map


  test "check tag value OK" do
    {_,  errs} = FMsgMapSupport.check_tag_value({@msg_map2test, []}, :BeginString, "FIX.4.4")
    assert errs == []
  end

  test "check tag value wrong" do
    {_,  errs} = FMsgMapSupport.check_tag_value({@msg_map2test, []}, :BeginString, "FIX.4.2")
    assert errs == [" invalid tag value on: BeginString(8)  received: FIX.4.4, expected  FIX.4.2"]
  end

  test "check tag value OK prev errors" do
    {_,  errs} = FMsgMapSupport.check_tag_value({@msg_map2test, ["prev error"]},
                                                  :BeginString, "FIX.4.4")
    assert errs ==  ["prev error"]
  end

  test "check tag value wrong prev errors" do
    {_,  errs} = FMsgMapSupport.check_tag_value({@msg_map2test, ["prev error"]},
                                                  :BeginString, "FIX.4.1")
    assert errs == ["prev error",
            " invalid tag value on: BeginString(8)  received: FIX.4.4, expected  FIX.4.1"]
  end

  test "get integer value OK" do
    assert {:ok, 13346} == FMsgMapSupport.get_tag_value_mandatory_int(:ClOrdID, @msg_map2test)
  end

  test "get integer value string field" do
    assert {:error, "invalid val on tag TargetCompID(56)"} ==
              FMsgMapSupport.get_tag_value_mandatory_int(:TargetCompID, @msg_map2test)
  end

  test "check mandatory tags OK" do
    {_,  errs} = FMsgMapSupport.check_mandatory_tags({@msg_map2test, []},
                                                  [:BeginString,
                                                   :BodyLength,
                                                   :SenderCompID,
                                                   :TargetCompID,
                                                   :MsgSeqNum,
                                                   :SendingTime])
    assert errs == []
  end

  test "check mandatory tags missing 999" do
    {_,  errs} = FMsgMapSupport.check_mandatory_tags({@msg_map2test, []},
                                                  [:BeginString,
                                                   :BodyLength,
                                                   :SenderCompID,
                                                   :TargetCompID,
                                                   :MsgSeqNum,
                                                   :SendingTime,
                                                   999])
    assert errs == ["missing tag 999."]
  end

  test "check mandatory tags missing 999 && 998" do
    {_,  errs} = FMsgMapSupport.check_mandatory_tags({@msg_map2test, []},
                                                  [:BeginString,
                                                   :BodyLength,
                                                   :SenderCompID,
                                                   :TargetCompID,
                                                   :MsgSeqNum,
                                                   999,
                                                   998])
    assert errs == ["missing tag 999.", "missing tag 998."]
  end

  test "check mandatory tags OK, prev error" do
    {_,  errs} = FMsgMapSupport.check_mandatory_tags({@msg_map2test, ["prev"]},
                                                [:BeginString,
                                                 :BodyLength,
                                                 :SenderCompID,
                                                 :TargetCompID,
                                                 :MsgSeqNum,
                                                 :SendingTime])
    assert errs == ["prev"]
  end

  test "check mandatory tags missing 999 prev err" do
    {_,  errs} = FMsgMapSupport.check_mandatory_tags({@msg_map2test, ["prev"]},
                                                [:BeginString,
                                                 :BodyLength,
                                                 :SenderCompID,
                                                 :TargetCompID,
                                                 :MsgSeqNum,
                                                 :SendingTime,
                                                 999])
    assert errs == ["prev", "missing tag 999."]
  end

end
