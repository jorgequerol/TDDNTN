function framePlan = buildFramePlan(TframeSlots, dlSlots, ulSlots, gpSlots, xdlSlots)
%buildFramePlan Build DL/GPIdle/xDL/UL slot indices for a simple TDD frame.
%   xDL is placed at the end of GP to realize DL -> GPIdle -> xDL -> UL.

arguments
    TframeSlots (1,1) double {mustBeInteger,mustBePositive}
    dlSlots (1,1) double {mustBeInteger,mustBeNonnegative}
    ulSlots (1,1) double {mustBeInteger,mustBeNonnegative}
    gpSlots (1,1) double {mustBeInteger,mustBeNonnegative}
    xdlSlots (1,1) double {mustBeInteger,mustBeNonnegative} = 0
end

if dlSlots + gpSlots + ulSlots > TframeSlots
    error('ntn:InvalidFramePlan', ...
        'DL + GP + UL slots must be <= total frame slots.');
end

framePlan = struct();
framePlan.TframeSlots = TframeSlots;
framePlan.DL = 1:dlSlots;
framePlan.GP = (dlSlots + 1):(dlSlots + gpSlots);
framePlan.UL = (dlSlots + gpSlots + 1):(dlSlots + gpSlots + ulSlots);
framePlan.Unused = (dlSlots + gpSlots + ulSlots + 1):TframeSlots;

xdlSlots = min(xdlSlots, numel(framePlan.GP));
if xdlSlots > 0
    framePlan.xDL = framePlan.GP((end - xdlSlots + 1):end);
else
    framePlan.xDL = [];
end
framePlan.GPIdle = setdiff(framePlan.GP, framePlan.xDL, 'stable');
end
