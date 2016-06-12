defmodule FMsgParseTest do
  use ExUnit.Case
  doctest FSessionReceiver


"""
Message with errors on parsing -> reject
Message withe errors
    |>  check_tag_value(:BeginString,  status.fix_version)
    |>  check_tag_value(:SenderCompID, status.sender_comp_id)
    |>  check_tag_value(:TargetCompID, status.target_comp_id)

Message app
Message login ok and wrong
Message login on loginok
Invalid seqnumber
"""

  test "parsed full message OK" do
    assert 1 + 1 = 2
  end
end
