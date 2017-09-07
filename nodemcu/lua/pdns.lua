local module = {}

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

local function bit_set(val, mask)
  return val % (mask + mask) >= mask
end

function module.mdns_parse(service, data, answers)

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

return module
