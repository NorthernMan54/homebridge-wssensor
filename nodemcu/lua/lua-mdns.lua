--[[

    Copyright (c) 2015 Frank Edelhaeuser

    This file is part of lua-mdns.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Usage:

        require('mdns')

        local res = mdns_resolve('_printer._tcp') -- find printers
        if (res) then
            for k,v in pairs(res) do
                print(k)
                for k1,v1 in pairs(v) do
                    print('  '..k1..': '..v1)
                end
            end
        else
            print('no result')
        end

]]--
-- local socket = require('socket')

local module = {}

local services

local function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

local function mdns_make_query(service)
  -- header: transaction id, flags, qdcount, ancount, nscount, nrcount
  local data = '\000\000'..'\000\000'..'\000\001'..'\000\000'..'\000\000'..'\000\000'
  -- question section: qname, qtype, qclass
  for n in service:gfind('([^\.]+)') do
    data = data..string.char(#n)..n
  end
  return data..string.char(0)..'\000\012'..'\000\001'
end


local function mdns_parse(service, data, answers)

  --- Helper function: parse DNS name field, supports pointers
  -- @param data     received datagram
  -- @param offset    offset within datagram (1-based)
  -- @return  parsed name
  -- @return  offset of first byte behind name (1-based)
  local function parse_name(data, offset)
    local n, d, l = '', '', data:byte(offset)
    while (l > 0) do
      if (l >= 192) then -- pointer
        local p = (l % 192) * 256 + data:byte(offset + 1)
        return n..d..parse_name(data, p + 1), offset + 2
      end
      n = n..d..data:sub(offset + 1, offset + l)
      offset = offset + l + 1
      l = data:byte(offset)
      d = '.'
    end
    return n, offset + 1
  end

  --- Helper function: check if a single bit is set in a number
  -- @param val       number
  -- @param mask      mask (single bit only)
  -- @return  true if bit is set, false if not
  local function bit_set(val, mask)
    return val % (mask + mask) >= mask
  end

  -- decode and check header
  if (not data) then
    return nil, 'no data'
  end
  local len = #data
  if (len < 12) then
    return nil, 'truncated'
  end

  local header = {
    id = data:byte(1) * 256 + data:byte(2),
    flags = data:byte(3) * 256 + data:byte(4),
    qdcount = data:byte(5) * 256 + data:byte(6),
    ancount = data:byte(7) * 256 + data:byte(8),
    nscount = data:byte(9) * 256 + data:byte(10),
    arcount = data:byte(11) * 256 + data:byte(12),
  }
  if (not bit_set(header.flags, 0x8000)) then
    return nil, 'not a reply'
  end
  if (bit_set(header.flags, 0x0200)) then
    return nil, 'TC bit is set'
  end
  if (header.ancount == 0) then
    return nil, 'no answer records'
  end

  -- skip question section
  local name
  local offset = 13
  if (header.qdcount > 0) then
    for i = 1, header.qdcount do
      if (offset > len) then
        return nil, 'truncated'
      end
      name, offset = parse_name(data, offset)
      offset = offset + 4
    end
  end

  -- evaluate answer section
  for i = 1, header.ancount do
    if (offset > len) then
      return nil, 'truncated'
    end

    name, offset = parse_name(data, offset)
    local type = data:byte(offset + 0) * 256 + data:byte(offset + 1)
    local rdlength = data:byte(offset + 8) * 256 + data:byte(offset + 9)
    local rdoffset = offset + 10

    -- A record (IPv4 address)
    if (type == 1) then
      if (rdlength ~= 4) then
        return nil, 'bad RDLENGTH with A record'
      end
      answers.a[name] = string.format('%d.%d.%d.%d', data:byte(rdoffset + 0), data:byte(rdoffset + 1), data:byte(rdoffset + 2), data:byte(rdoffset + 3))
    end

    -- PTR record (pointer)
    if (type == 12) then
      local target = parse_name(data, rdoffset)
      table.insert(answers.ptr, target)
    end

    -- AAAA record (IPv6 address)
    if (type == 28) then
      if (rdlength ~= 16) then
        return nil, 'bad RDLENGTH with AAAA record'
      end
      local offs = rdoffset
      local aaaa = string.format('%x', data:byte(offs) * 256 + data:byte(offs + 1))
      while (offs < rdoffset + 14) do
        offs = offs + 2
        aaaa = aaaa..':'..string.format('%x', data:byte(offs) * 256 + data:byte(offs + 1))
      end

      -- compress IPv6 address
      for _, s in ipairs({ ':0:0:0:0:0:0:0:', ':0:0:0:0:0:0:', ':0:0:0:0:0:', ':0:0:0:0:', ':0:0:0:', ':0:0:' }) do
        local r = aaaa:gsub(s, '::')
        if (r ~= aaaa) then
          aaaa = r
          break
        end
      end
      answers.aaaa[name] = aaaa
    end

    -- SRV record (service location)
    if (type == 33) then
      if (rdlength < 6) then
        return nil, 'bad RDLENGTH with SRV record'
      end
      answers.srv[name] = {
        target = parse_name(data, rdoffset + 6),
        port = data:byte(rdoffset + 4) * 256 + data:byte(rdoffset + 5)
      }
    end

    -- next answer record
    offset = offset + 10 + rdlength
  end

  return answers
end


--- Locate MDNS services in local network
--
-- @param service   MDNS service name to search for (e.g. _ipps._tcp). A .local postfix will
--                  be appended if needed. If this parameter is not specified, all services
--                  will be queried.
--
-- @param timeout   Number of seconds to wait for MDNS responses. The default timeout is 2
--                  seconds if this parameter is not specified.
--
-- @return          Table of MDNS services. Entry keys are service identifiers. Each entry
--                  is a table containing all or a subset of the following elements:
--
--                      name: MDNS service name (e.g. HP Laserjet 4L @ server.example.com)
--                      service: MDNS service type (e.g. _ipps._tcp.local)
--                      hostname: hostname
--                      port: port number
--                      ipv4: IPv4 address
--                      ipv6: IPv6 address
--
function module.mdns_query(service)

  print("mDNS Query"..service)
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
  local answers = { srv = {}, a = {}, aaaa = {}, ptr = {} }
  -- create IPv4 socket for multicast DNS
  --  local ip, port, udp = '224.0.0.251', 5353, socket.udp()

  net.multicastJoin("any", '224.0.0.251')
  local udpSocket = net.createUDPSocket()

  udpSocket:listen(5353)
  udpSocket:on("receive", function(s, data, port, ip)
    local response = { srv = {}, a = {}, aaaa = {}, ptr = {} }
    response, err = mdns_parse(service, data, response)
    if response then
      --print(string.format("mDNS Response Received from %s:%d", ip, port) ..dump(response))

      services = nil
      for k, v in pairs(response.srv) do
        local pos = k:find('%.')
        if (pos and (pos > 1) and (pos < #k)) then
          local name, svc = k:sub(1, pos - 1), k:sub(pos + 1)
          if (browse) or (svc == service) then
            --services = {}
            if (v.target) then
              if (response.a[v.target]) then
                v.ipv4 = response.a[v.target]
              end
              if (response.aaaa[v.target]) then
                v.ipv6 = response.aaaa[v.target]
              end
              if (v.target:sub(-6) == '.local') then
                v.hostname = v.target:sub(1, #v.target - 6)
              end
              v.target = nil
            end
            v.service = svc
            v.name = name
            services = v
            print("Service "..dump(services))
            udpSocket:close()
          end
        end
      end

      -- print("Service "..dump(services))

    end
  end)

  local sendcount = 3
  local querySend = tmr.create()
  querySend:register( 1500, 1, function(t)
    print("Sending mDNS Query"..service)
    if udpSocket then
      udpSocket:send(5353, '224.0.0.251', mdns_make_query(service))
    end
    sendcount = sendcount - 1
    if sendcount < 1 then
      t:unregister()
    end
  end)
  querySend:start()

end

function module.getServices()
  package.loaded['lua-mdns']=nil
  return services
end

return module
