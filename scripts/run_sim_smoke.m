% run_sim_smoke Short smoke simulation for NTN custom scheduler behavior.
% Returns a metrics struct in base workspace as smokeMetrics.

addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));

numUEs = 3;
slantRanges_m = [6e5 8e5 1.1e6];
sinr_dB = [8 4 -1];
slotDuration_s = 1e-3;

[gpSlots, rtt_s] = ntn.computeGP(slantRanges_m, slotDuration_s);
gpSelected = ntn.selectGPSlots(gpSlots, "perUE");
xdlSlots = ntn.computeXDLReuseSlots(gpSelected, "halfRTT", true);
framePlan = ntn.buildFramePlan(10, 5, 3, gpSelected, xdlSlots);

metrics = struct();
metrics.Input = struct('slantRanges_m', slantRanges_m, 'sinr_dB', sinr_dB, ...
    'slotDuration_s', slotDuration_s, 'xDLThreshold_dB', 3, 'EnablexDL', true);
metrics.PerUE = struct('RNTI', num2cell(1:numUEs), ...
    'RTT_s', num2cell(rtt_s), ...
    'GPSlots', num2cell(gpSlots), ...
    'DLRBs', num2cell(zeros(1,numUEs)), ...
    'xDLRBs', num2cell(zeros(1,numUEs)), ...
    'ULRBs', num2cell(zeros(1,numUEs)), ...
    'GPOverheadSlots', num2cell(gpSlots), ...
    'BytesScheduled', num2cell(zeros(1,numUEs)));
metrics.FramePlan = framePlan;

for ue = 1:numUEs
    if ntn.isxDLEligible(sinr_dB(ue), metrics.Input.xDLThreshold_dB)
        metrics.PerUE(ue).xDLRBs = 4;
    end
    metrics.PerUE(ue).DLRBs = 8;
    metrics.PerUE(ue).ULRBs = max(0, 6 - gpSlots(ue));
    metrics.PerUE(ue).BytesScheduled = 12 * ...
        (metrics.PerUE(ue).DLRBs + metrics.PerUE(ue).xDLRBs + metrics.PerUE(ue).ULRBs);
end

% Try to initialize scheduler class when 5G Toolbox is available.
metrics.SchedulerInstantiated = false;
if exist('nrScheduler', 'class') == 8
    try
        s = NTNCustomScheduler('xDLThreshold_dB', metrics.Input.xDLThreshold_dB, ...
            'EnablexDL', metrics.Input.EnablexDL, ...
            'SlotDuration_s', slotDuration_s);
        for ue = 1:numUEs
            s.addOrUpdateUEContext(ue, slantRanges_m(ue), sinr_dB(ue));
        end
        metrics.SchedulerInstantiated = true;
        metrics.SchedulerMetrics = s.exportMetrics();
    catch schedulerErr
        metrics.SchedulerError = schedulerErr.message;
    end
end

assignin('base', 'smokeMetrics', metrics);
disp('Smoke simulation completed. Metrics available as variable "smokeMetrics".');
disp(metrics);
