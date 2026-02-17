% reproduce_ppt_results Reproduce Milestone 2-style KPI sweeps.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repoRoot));
addpath(fullfile(repoRoot, 'Examples', 'NRPlugCustomSchedulerExample'));

outDir = fullfile(repoRoot, 'results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

Tframe_ms = [10 20 30 40 182];
GPModes = ["worst", "min", "perUE"];
enablexDLList = [false true];
thresholdList = ["none", "0", "3"];

slotDuration_s = 1e-3;
slantRange_m = [6e5 8.5e5 1.1e6 1.4e6];
sinr_dB = [9 4 1 -2];
[gpUE, rtt_s] = ntn.computeGP(slantRange_m, slotDuration_s);

row = 0;
records = struct([]);
for t = 1:numel(Tframe_ms)
    tSlots = max(1, round(Tframe_ms(t)/1));
    dlSlots = max(1, floor(0.5 * tSlots));
    ulSlots = max(1, floor(0.3 * tSlots));

    for g = 1:numel(GPModes)
        gpSelected = ntn.selectGPSlots(gpUE, GPModes(g));
        gpSelected = min(gpSelected, max(0, tSlots - dlSlots - ulSlots));
        for ex = 1:numel(enablexDLList)
            enablexDL = enablexDLList(ex);
            xdlSlots = ntn.computeXDLReuseSlots(gpSelected, "halfRTT", enablexDL);
            plan = ntn.buildFramePlan(tSlots, dlSlots, ulSlots, gpSelected, xdlSlots);

            for th = 1:numel(thresholdList)
                thrText = thresholdList(th);
                eligible = ntn.isxDLEligible(sinr_dB, thrText);
                xdlFactor = mean(double(eligible));

                frameEfficiency = (numel(plan.DL) + numel(plan.xDL)) / tSlots;
                idleGPOverhead = numel(plan.GPIdle) / tSlots;

                rbPerSlot = 20;
                spectralUnit = 1e3;
                sumRate = (numel(plan.DL) + xdlFactor*numel(plan.xDL) + numel(plan.UL)) * rbPerSlot * spectralUnit / (Tframe_ms(t)*1e-3);
                avgRate = sumRate / numel(slantRange_m);
                throughput = sumRate * frameEfficiency;

                row = row + 1;
                records(row).Tframe_ms = Tframe_ms(t); %#ok<SAGROW>
                records(row).GPMode = char(GPModes(g));
                records(row).EnablexDL = enablexDL;
                records(row).xDLThreshold_dB = char(thrText);
                records(row).FrameEfficiency = frameEfficiency;
                records(row).IdleGPOverhead = idleGPOverhead;
                records(row).SumRate = sumRate;
                records(row).AvgRate = avgRate;
                records(row).Throughput = throughput;
                records(row).GPSelectedSlots = gpSelected;
                records(row).xDLReuseSlots = xdlSlots;
            end
        end
    end
end

resultsTable = struct2table(records);
gpVsRange = table(slantRange_m(:), rtt_s(:), gpUE(:), 'VariableNames', ...
    {'SlantRange_m','RTT_s','GPSlots'});

% Stable output files
csvPath = fullfile(outDir, 'ppt_reproduction_metrics.csv');
matPath = fullfile(outDir, 'ppt_reproduction_metrics.mat');
fig1Path = fullfile(outDir, 'ppt_frame_efficiency_vs_tframe.png');
fig2Path = fullfile(outDir, 'ppt_gp_vs_slant_range.png');

writetable(resultsTable, csvPath);
save(matPath, 'resultsTable', 'gpVsRange');

% Figure: Frame efficiency across frame durations
fig1 = figure('Visible', 'off');
groups = findgroups(resultsTable.GPMode, resultsTable.EnablexDL, resultsTable.xDLThreshold_dB);
summaryTbl = splitapply(@mean, resultsTable.FrameEfficiency, groups);
% quick aggregated line per Tframe using all sweeps
effByT = varfun(@mean, resultsTable, 'InputVariables','FrameEfficiency', 'GroupingVariables','Tframe_ms');
plot(effByT.Tframe_ms, effByT.mean_FrameEfficiency, '-o', 'LineWidth', 1.5);
xlabel('Tframe (ms)'); ylabel('Frame Efficiency'); grid on;
title('Frame Efficiency vs Tframe (aggregated sweeps)');
saveas(fig1, fig1Path);
close(fig1);

% Figure: GP slots vs slant range
fig2 = figure('Visible', 'off');
plot(gpVsRange.SlantRange_m/1e3, gpVsRange.GPSlots, '-s', 'LineWidth', 1.5);
xlabel('Slant Range (km)'); ylabel('GP Slots'); grid on;
title('Per-UE GP vs Slant Range');
saveas(fig2, fig2Path);
close(fig2);

pptResults = struct();
pptResults.ResultsTable = resultsTable;
pptResults.GPvsRange = gpVsRange;
pptResults.OutputFiles = struct('csv', csvPath, 'mat', matPath, ...
    'frameEfficiencyFigure', fig1Path, 'gpVsRangeFigure', fig2Path);
assignin('base', 'pptResults', pptResults);

disp('PPT reproduction sweep complete. Results in results/.');
disp(pptResults.OutputFiles);
