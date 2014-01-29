local base64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start)) == Start
end

function string.ends(String,End)
    return End == '' or string.sub(String,-string.len(End)) == End
end

function string.split(String, delimiter)
    result = {}
    for match in (String..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end

    return result
end

function string.trim(s)
    return s:match'^%s*(.*%S)' or ''
end

function toboolean(v)
    return (type(v) == "string" and v == "true") or (type(v) == "number" and v ~= 0) or (type(v) == "boolean" and v)
end

function base64enc(data)
    return ((data:gsub('.', 
        function(x) 
            local r,base64='', x:byte()
            for i=8,1,-1 do
                r = r..(base64 % 2^i - base64 % 2^(i-1) > 0 and '1' or '0')
            end

            return r
        end
    )..'0000'):gsub('%d%d%d?%d?%d?%d?', 
        function(x)
            if (#x < 6) then
                return ''
            end

            local c = 0
            for i = 1,6 do
                c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0)
            end

            return base64:sub(c+1,c+1)
        end
    )..({'', '==', '='})[#data % 3+1])
end

function supports(feature)
    if ServVer == -1 then
        return true
    end

    if feature == "IP" then
        return ServVer >= 12
    end
end