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

function supports(feature)
    if ServVer == -1 then
        return true
    end

    if feature == "IP" then
        return ServVer >= 12
    end
end