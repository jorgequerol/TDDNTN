function key = getTimeResourceKey(timeResource)
%getTimeResourceKey Convert scheduler timeResource input to a stable scalar key.

[ok, value] = extractNumericScalar(timeResource);
if ok
    key = value;
    return;
end

if isstruct(timeResource)
    if isfield(timeResource, 'NFrame') && isfield(timeResource, 'NSlot')
        [okF, fVal] = extractNumericScalar(timeResource.NFrame);
        [okS, sVal] = extractNumericScalar(timeResource.NSlot);
        if okF && okS
            key = fVal*1e5 + sVal;
            return;
        end
    end

    preferredFields = {'SlotNumber','NSlot','nSlot','Timestamp','Slot','Time'};
    for i = 1:numel(preferredFields)
        f = preferredFields{i};
        if isfield(timeResource, f)
            [ok, val] = extractNumericScalar(timeResource.(f));
            if ok
                key = val;
                return;
            end
        end
    end

    % Generic struct search: first numeric-like scalar found in fields
    fns = fieldnames(timeResource);
    for i = 1:numel(fns)
        [ok, val] = extractNumericScalar(timeResource.(fns{i}));
        if ok
            key = val;
            return;
        end
    end

    % deterministic fallback
    try
        key = double(sum(uint8(jsonencode(timeResource))));
    catch
        key = double(numel(fns));
    end
    return;
end

if iscell(timeResource)
    parts = zeros(1, numel(timeResource));
    for i = 1:numel(timeResource)
        parts(i) = getTimeResourceKey(timeResource{i});
    end
    key = sum(parts .* (1:numel(parts)));
    return;
end

% final safe fallback
key = double(numel(timeResource));
end

function [ok, value] = extractNumericScalar(v)
ok = false;
value = NaN;

if isempty(v)
    return;
end

if isnumeric(v) || islogical(v)
    value = double(v(1));
    ok = true;
    return;
end

if isdatetime(v)
    value = posixtime(v(1));
    ok = true;
    return;
end

if isduration(v)
    value = seconds(v(1));
    ok = true;
    return;
end

if isstruct(v)
    fns = fieldnames(v);
    for i = 1:numel(fns)
        [ok, value] = extractNumericScalar(v(1).(fns{i}));
        if ok
            return;
        end
    end
end

if iscell(v) && ~isempty(v)
    [ok, value] = extractNumericScalar(v{1});
end
end
