function xdlReuseSlots = computeXDLReuseSlots(gpSelected, xDLReuseRule, enablexDL)
%computeXDLReuseSlots Compute xDL slots reused from GP.

arguments
    gpSelected (1,1) double {mustBeInteger,mustBeNonnegative}
    xDLReuseRule {mustBeTextScalar} = "halfRTT"
    enablexDL (1,1) logical = true
end

if ~enablexDL || gpSelected == 0
    xdlReuseSlots = 0;
    return;
end

rule = lower(string(xDLReuseRule));
switch rule
    case "halfrtt"
        xdlReuseSlots = floor(gpSelected/2);
    otherwise
        error('ntn:InvalidxDLReuseRule', 'xDLReuseRule must be "halfRTT".');
end

xdlReuseSlots = min(xdlReuseSlots, max(gpSelected - 1, 0));
end
