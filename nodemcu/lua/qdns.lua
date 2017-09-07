
local module = {}

local function mdns_make_query(service)
  -- header: transaction id, flags, qdcount, ancount, nscount, nrcount
  local data = '\000\000'..'\000\000'..'\000\001'..'\000\000'..'\000\000'..'\000\000'
  -- question section: qname, qtype, qclass
  for n in service:gfind('([^\.]+)') do
    data = data..string.char(#n)..n
  end
  return data..string.char(0)..'\000\012'..'\000\001'
end

function module.mdns_query()

  -- browse all services if no service name specified
  local browse = false
  if (not service) then
    service = '_services._dns-sd._udp'
    browse = true
  end

  -- append .local if needed
  if (service:sub(-6) ~= '.local') then
    service = service..'.local'
  end

  -- default timeout: 2 seconds
  local timeout = timeout or 2.0

  -- create IPv4 socket for multicast DNS
  --  local ip, port, udp = '224.0.0.251', 5353, socket.udp()

  local answers = { srv = {}, a = {}, aaaa = {}, ptr = {} }

  net.multicastJoin("any", '224.0.0.251')
  udpSocket = net.createUDPSocket()

  udpSocket:listen(5353)
  udpSocket:on("receive", function(s, data, port, ip)
    print(string.format("received from %s:%d -> %s", ip, port,data))
    print("Heap Available: -qdns " .. node.heap())
    pdns = require("pdns")
    print("Heap Available: -pdns " .. node.heap())
--    print("PreParse" ..service.."->".. data.."->" ..answers)
    pdns.mdns_parse(service, data, answers)
    pdns=nil
  end)
  port, ip = udpSocket:getaddr()
  print(string.format("local UDP socket address / port: %s:%d", ip, port))

  --  assert(udp:setoption('ip-add-membership', { interface = '*', multiaddr = ip }))
  --  assert(udp:settimeout(0.1))
  udpSocket:send(5353, '224.0.0.251', "echo: ")
  -- send query
  --assert(udp:sendto(mdns_make_query(service), ip, port))

  -- collect responses until timeout

  --  local start = os.time()
  --  while (os.time() - start < timeout) do
  --    local data, peeraddr, peerport = udp:receivefrom()
  --    if data and (peerport == port) then
  --      mdns_parse(service, data, answers)
  --      if (browse) then
  --        for _, ptr in ipairs(answers.ptr) do
  --          assert(udp:sendto(mdns_make_query(ptr), ip, port))
  --        end
  --        answers.ptr = {}
  --      end
  --    end
  --  end

  -- cleanup socket
  --  assert(udp:setoption("ip-drop-membership", { interface = "*", multiaddr = ip }))
  --  assert(udp:close())
  --  udp = nil
  return services
  -- extract target services from answers, resolve hostnames
  --local services = {}
  --for k, v in pairs(answers.srv) do
  --  local pos = k:find('%.')
  --  if (pos and (pos > 1) and (pos < #k)) then
  --    local name, svc = k:sub(1, pos - 1), k:sub(pos + 1)
  --    if (browse) or (svc == service) then
  --      if (v.target) then
  --        if (answers.a[v.target]) then
  --          v.ipv4 = answers.a[v.target]
  --        end
  --        if (answers.aaaa[v.target]) then
  --          v.ipv6 = answers.aaaa[v.target]
  --        end
  --        if (v.target:sub(-6) == '.local') then
  --          v.hostname = v.target:sub(1, #v.target - 6)
  --        end
  --        v.target = nil
  --      end
  --      v.service = svc
  --      v.name = name
  --      services[k] = v
  --    end
  --  end
  --end

  --return services
end

return module
