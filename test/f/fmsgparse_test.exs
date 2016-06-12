defmodule FMsgParseTest do
  use ExUnit.Case
  doctest FMsgParse


  test "parsed full message OK" do
    result = FMsgParse.parse_string_test(
          "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|" <>
          "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|" <>
          "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")

    assert result.parsed.check_sum == 72
    assert result.parsed.body_length == 122
    assert result.parsed.errors == []
    assert result.parsed.msg_map[:TargetCompID] == "B"
  end

  test "parsed full message tag 8 not first" do
    result = FMsgParse.parse_string_test(
          "9=122|8=FIX.4.4|35=D|34=215|49=CLIENT12|" <>
          "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|" <>
          "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
    #IO.inspect result

    assert result.parsed.check_sum == 72
    assert result.parsed.body_length == 122
    assert result.parsed.errors == [{6,  "First tag has to be BeginString"},
                                    {16, "Second tag has to be BodyLength"}]
    assert result.parsed.msg_map[:TargetCompID] == "B"
  end


  test "parsed full message tag 9 not second" do
    result = FMsgParse.parse_string_test(
          "8=FIX.4.4|35=D|34=215|49=CLIENT12|9=122|" <>
          "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|" <>
          "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
    #IO.inspect result

    assert result.parsed.check_sum == 72
    assert result.parsed.body_length == 122
    assert result.parsed.errors == [{15, "Second tag has to be BodyLength"},
                                    {40, "Tag BodyLength has to be on position 2"}
                                   ]
    assert result.parsed.msg_map[:TargetCompID] == "B"
  end

  test "parsed full message incorrect checksum" do
    result = FMsgParse.parse_string_test(
          "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|" <>
          "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|" <>
          "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=071|")
    #IO.inspect result

    assert result.parsed.check_sum == 72
    assert result.parsed.body_length == 122
    assert result.parsed.errors == [{145,
          "Incorrect checksum calculated: 72 received 71  chunk:071"}]
    assert result.parsed.msg_map[:TargetCompID] == "B"
  end

  test "parsed full message incorrect bodylength" do
    result = FMsgParse.parse_string_test(
          "8=FIX.4.4|9=121|35=D|34=215|49=CLIENT12|" <>
          "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|" <>
          "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
    #IO.inspect result

    assert result.parsed.check_sum == 71
    assert result.parsed.body_length == 122
    assert result.parsed.errors == [{145,
                  "Incorrect body length  calculated: 122 received 121"}]
    assert result.parsed.msg_map[:TargetCompID] == "B"
  end

  test "partial val" do
    result = FMsgParse.parse_string_test("8=FIX.4.4|9=12")
    #IO.inspect result

    assert result ==
        %FMsgParse.StPartVal{chunk: "12",
          parsed: %FMsgParse.Parsed{body_length: 0, check_sum: 250, errors: [],
          msg_map: %{:BeginString => "FIX.4.4"}, num_tags: 1, orig_msg: "8=FIX.4.4^9=12",
          position: 14}, tag: :BodyLength}
  end

  test "partial tag" do
    result = FMsgParse.parse_string_test(
          "8=FIX.4.4|9=121|35=D|34=215|49=CLIENT12|" <>
          "52=20100225-19:41:57.316|5")
    #IO.inspect result

    assert result ==
      %FMsgParse.StPartTag{chunk: "5",
       parsed: %FMsgParse.Parsed{body_length: 50, check_sum: 42, errors: [],
        msg_map: %{:BeginString => "FIX.4.4", :BodyLength => "121", :MsgSeqNum => 215, :MsgType => "D",
          :SenderCompID => "CLIENT12", :SendingTime => "20100225-19:41:57.316"}, num_tags: 6,
        orig_msg: "8=FIX.4.4^9=121^35=D^34=215^49=CLIENT12^52=20100225-19:41:57.316^5",
        position: 66}}
  end

  test "partial field =" do
    result = FMsgParse.parse_string_test("8=FIX.4.4|9=121|35=D|34=")
    #IO.inspect result

    assert result ==
      %FMsgParse.StPartVal{chunk: "",
       parsed: %FMsgParse.Parsed{body_length: 8, check_sum: 186, errors: [],
        msg_map: %{:BeginString => "FIX.4.4", :BodyLength => "121", :MsgType => "D"}, num_tags: 3,
        orig_msg: "8=FIX.4.4^9=121^35=D^34=", position: 24}, tag: :MsgSeqNum}
    end


    test "invalid tag" do
      result = FMsgParse.parse_string_test(
            "8=FIX.4.4|9=121|35=D|34=215|49=CLIENT12|" <>
            "52=20100225-19:41:57.316|56a=B|1=Marcel|11=13346|" <>
            "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
      #IO.inspect result

      assert List.first(result.parsed.errors) ==
          {69, "invalid tag value 56a"}
    end


    test "emtpy tag" do
      result = FMsgParse.parse_string_test(
            "8=FIX.4.4|9=121|35=D|34=215|49=CLIENT12|" <>
            "52=20100225-19:41:57.316|=B|1=Marcel|11=13346|" <>
            "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072|")
      #IO.inspect result

      assert List.first(result.parsed.errors) ==
          {66, "invalid tag value "}
          "52=20100225-19:41:57.316^"
    end

    test "emtpy value" do
      result = FMsgParse.parse_string_test(
            "8=FIX.4.4|9=121|35=D|34=215|49=CLIENT12|" <>
            "52=20100225-19:41:57.316|56=|1=Marcel|11=13346|" <>
            "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=005|")
      #IO.inspect result

      assert result.parsed.check_sum == 5
      assert result.parsed.body_length == 121
      assert result.parsed.errors == []

    end


    test "SOH after full message" do
      result = FMsgParse.parse_string_test(
            "8=FIX.4.4|9=122|35=D|34=215|49=CLIENT12|" <>
            "52=20100225-19:41:57.316|56=B|1=Marcel|11=13346|" <>
            "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=072||")
      #IO.inspect result

      assert result.parsed.errors == [
                                  {146,
                                   "Invalid SOH after full message recieved"}]
    end

    test "missing mandatory tag" do
      result = FMsgParse.parse_string_test(
            "8=FIX.4.4|9=117|35=D|34=215|49=CLIENT12|" <>
            "52=20100225-19:41:57.316|1=Marcel|11=13346|" <>
            "21=1|40=2|44=5|54=1|59=0|60=20100225-19:39:52.020|10=097|")

      #IO.inspect result
      assert result.parsed.check_sum == 97
      assert result.parsed.body_length == 117
      assert result.parsed.errors == [{140, "missing tag TargetCompID(56)."}]
    end

end
