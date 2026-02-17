function gpSelected = selectGPSlots(gpSlotsPerUE, gpMode)
%selectGPSlots Select frame GP slots based on GPMode.
%   GPMode: "worst" | "min" | "perUE"

arguments
    gpSlotsPerUE (1,:) double {mustBeInteger,mustBeNonnegative}
    gpMode {mustBeTextScalar}
end

mode = lower(string(gpMode));
if isempty(gpSlotsPerUE)
    gpSelected = 0;
    return;
end

switch mode
    case "worst"
        gpSelected = max(gpSlotsPerUE);
    case "min"
        gpSelected = min(gpSlotsPerUE);
    case "perue"
        % Frame-level GP reserves worst-case while UL eligibility stays per-UE.
        gpSelected = max(gpSlotsPerUE);
    otherwise
        error('ntn:InvalidGPMode', 'GPMode must be "worst", "min", or "perUE".');
end
end
