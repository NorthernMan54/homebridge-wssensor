--SAFETRIM
require "luaOTA.check"

tmr.create():alarm(30000, tmr.ALARM_SINGLE, function()
  dofile("main.lc")
end)
