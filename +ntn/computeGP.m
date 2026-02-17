function [gpSlots, rttSeconds] = computeGP(slantRangeMeters, slotDurationSeconds)
%computeGP Convert slant range to RTT and required guard-period slots.
%   [GPSLOTS, RTTSECONDS] = ntn.computeGP(SLANTRANGEMETERS, SLOTDURATIONSECONDS)
%   computes round-trip-time as 2*range/c and maps it to slot count using
%   ceil(RTT/slotDuration).

arguments
    slantRangeMeters (1,:) double {mustBeNonnegative}
    slotDurationSeconds (1,1) double {mustBePositive}
end

speedOfLight = 299792458; % m/s
rttSeconds = (2 .* slantRangeMeters) ./ speedOfLight;
gpSlots = ceil(rttSeconds ./ slotDurationSeconds);
end
