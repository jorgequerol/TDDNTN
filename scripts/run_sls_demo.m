% run_sls_demo Minimal SLS-oriented demo using NTNCustomScheduler.
% Requires 5G Toolbox + Wireless Network Simulation support package.
% Returns a struct in base workspace as slsDemoMetrics.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repoRoot));

slsDemoMetrics = struct();
slsDemoMetrics.ToolboxAvailable = false;
slsDemoMetrics.RanSimulation = false;

if exist('nrGNB', 'class') ~= 8 || exist('wirelessNetworkSimulator', 'class') ~= 8
    warning('run_sls_demo:MissingToolbox', ...
        '5G Toolbox / Wireless Network Simulation not available. Returning empty metrics.');
    assignin('base', 'slsDemoMetrics', slsDemoMetrics);
    disp(slsDemoMetrics);
    return;
end

wirelessnetworkSupportPackageCheck;
rng('default');

% Minimal setup based on MathWorks SLS examples.
numUEs = 3;
slotDuration_s = 1e-3;
slantRange_m = [6e5 8.5e5 1.1e6];
sinr_dB = [8 5 0];

networkSimulator = wirelessNetworkSimulator.init;
gNB = nrGNB(Position=[0 0 30], DuplexMode="TDD", CarrierFrequency=2e9, ...
    ChannelBandwidth=10e6, SubcarrierSpacing=15e3, TransmitPower=30, ReceiveGain=6);

scheduler = NTNCustomScheduler('xDLThreshold_dB', 3, ...
    'GPMode', "perUE", ...
    'EnablexDL', true, ...
    'xDLReuseRule', "halfRTT", ...
    'SlotDuration_s', slotDuration_s, ...
    'TframeSlots', 10, ...
    'DLSlots', 5, ...
    'ULSlots', 3);
configureScheduler(gNB, Scheduler=scheduler, ResourceAllocationType=0, MaxNumUsersPerTTI=2);

ueNames = "UE-" + (1:numUEs);
uePos = [100 0 1.5; 250 100 1.5; 400 -100 1.5];
UEs = nrUE(Name=ueNames, Position=uePos, ReceiveGain=6);
connectUE(gNB, UEs, BSRPeriodicity=5, CSIReportPeriodicity=20, FullBufferTraffic="on");

% Attach per-UE NTN context placeholders.
for ue = 1:numUEs
    scheduler.addOrUpdateUEContext(ue, slantRange_m(ue), sinr_dB(ue));
end

addNodes(networkSimulator, gNB);
addNodes(networkSimulator, UEs);

simTime_s = 0.02; % short runtime smoke/demo
run(networkSimulator, simTime_s);

slsDemoMetrics.ToolboxAvailable = true;
slsDemoMetrics.RanSimulation = true;
slsDemoMetrics.SimTime_s = simTime_s;
slsDemoMetrics.Input = struct('slantRange_m', slantRange_m, ...
    'sinr_dB', sinr_dB, 'slotDuration_s', slotDuration_s, ...
    'xDLThreshold_dB', scheduler.xDLThreshold_dB, ...
    'GPMode', char(scheduler.GPMode), ...
    'EnablexDL', scheduler.EnablexDL, ...
    'xDLReuseRule', char(scheduler.xDLReuseRule));
slsDemoMetrics.SchedulerMetrics = scheduler.exportMetrics();

assignin('base', 'slsDemoMetrics', slsDemoMetrics);
disp('SLS demo complete. Metrics available as "slsDemoMetrics".');
disp(slsDemoMetrics);
