--SAFETRIM


print("Last failure",node.bootreason());
DEBUG=true
tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()
  require "luaOTA.check"
end)
