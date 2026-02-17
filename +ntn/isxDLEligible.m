function tf = isxDLEligible(sinr_dB, threshold_dB)
%isxDLEligible Return true if xDL gating threshold is met.
%   TF = ntn.isxDLEligible(SINR_DB, THRESHOLD_DB)
%   THRESHOLD_DB can be numeric, "none", or "off".

if isstring(threshold_dB) || ischar(threshold_dB)
    thresholdText = lower(string(threshold_dB));
    if any(thresholdText == ["none", "off"])
        tf = true(size(sinr_dB));
        return;
    end
    threshold_dB = str2double(thresholdText);
end

if ~isnumeric(threshold_dB) || ~isscalar(threshold_dB)
    error('ntn:InvalidxDLThreshold', ...
        'xDL threshold must be scalar numeric or "none"/"off".');
end

if isinf(threshold_dB) && threshold_dB < 0
    tf = true(size(sinr_dB));
else
    tf = sinr_dB >= threshold_dB;
end
end
