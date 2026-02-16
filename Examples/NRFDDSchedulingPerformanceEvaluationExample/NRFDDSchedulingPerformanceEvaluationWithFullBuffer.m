% Copyright 2023-2024 The MathWorks, Inc.

% Check if the Communications Toolbox Wireless Network Simulation Library
% support package is installed. If the support package is not installed,
% MATLAB® returns an error with a link to download and install the support
% package.
wirelessnetworkSupportPackageCheck
% Create a wireless network simulator.
rng("default") % Reset the random number generator
numFrameSimulation = 100; % Simulation time in terms of number of 10 ms frames
networkSimulator = wirelessNetworkSimulator.init;

% Create a gNB node by specifying its duplex mode, carrier frequency, channel
% bandwidth, subcarrier spacing, transmit power, and receive gain. Set the
% sounding reference signal (SRS) transmission periodicity to 40 slots for all
% UEs connecting to this gNB.
gNB = nrGNB(Position=[0 0 30], DuplexMode="FDD",CarrierFrequency=2.6e9,ChannelBandwidth=20e6, ...
    SubcarrierSpacing=15e3,TransmitPower=34,ReceiveGain=6,SRSPeriodicityUE=40);

% To set the scheduler parameters Scheduler, ResourceAllocationType, and
% MaxNumUsersPerTTI, use the configureScheduler function. Set the value of
% Scheduler parameter to "RoundRobin", ResourceAllocationType to 0, and
% MaxNumUsersPerTTI to 8. You can also set the value of Scheduler to
% "ProportionalFair" or "BestCQI", ResourceAllocationType to 1, and
% MaxNumUsersPerTTI to any positive integer.
scheduler = "RoundRobin";
configureScheduler(gNB,Scheduler=scheduler,ResourceAllocationType=0,MaxNumUsersPerTTI=8);

% Create 40 UE nodes. Specify the name, position and receive gain of each UE
% node.
numUEs = 40;
uePositions = [randi([0 750], numUEs, 2) 3*ones(numUEs,1)];
ueNames = "UE-" + (1:numUEs);
UEs = nrUE(Name=ueNames,Position=uePositions,ReceiveGain=6);

% Connect the UE nodes to gNB node. Set the buffer status report (BSR)
% periodicity to 5 (in number of subframes), set the DL channel status
% information (CSI) report periodicity to 40 (in number of slots), and configure
% full buffer traffic in the DL and UL directions
connectUE(gNB,UEs,BSRPeriodicity=5,CSIReportPeriodicity=40,FullBufferTraffic="on")

% Add gNB node and UE nodes to the network simulator
addNodes(networkSimulator,gNB)
addNodes(networkSimulator,UEs)

% Set the enable38901ChannelModel to true to configure the 3GPP TR 38.901
% channel model for all links. if the enable38901ChannelModel is set to false,
% this example applies a free space path loss (FSPL) model
enable38901ChannelModel = true;
if enable38901ChannelModel
    % Define scenario boundaries
    pos = reshape([gNB.Position UEs.Position],3,[]);
    minX = min(pos(1,:));          % x-coordinate of the left edge of the scenario in meters
    minY = min(pos(2,:));          % y-coordinate of the bottom edge of the scenario in meters
    width = max(pos(1,:)) - minX;  % Width (right edge of the 2D scenario) in meters, given as maxX - minX
    height = max(pos(2,:)) - minY; % Height (top edge of the 2D scenario) in meters, given as maxY - minY

    % Create the channel model
    channel = h38901Channel(Scenario="UMa",ScenarioExtents=[minX minY width height]);
    % Add the channel model to the simulator
    addChannelModel(networkSimulator,@channel.channelFunction);
    connectNodes(channel,networkSimulator);
end

% Set the enableTraces to true to log the traces. If the enableTraces is set to
% false, then traces are not logged in the simulation. To speed up the
% simulation, set the enableTraces to false
enableTraces = true;
% The cqiVisualization and rbVisualization parameters control the display of the
% CQI visualization and the RB assignment visualization respectively. By
% default, these plots are disabled. You can enable them by setting the
% respective flags to true
cqiVisualization = false;
rbVisualization = false;

% Set up scheduling logger and grid visualizer.
if enableTraces
    % Create an object for scheduler traces logging
    simSchedulingLogger = helperNRSchedulingLogger(numFrameSimulation,gNB,UEs);
    % Create an object for CQI and RB grid visualization
    gridVisualizer = helperNRGridVisualizer(numFrameSimulation,gNB,UEs,CQIGridVisualization=cqiVisualization, ...
        ResourceGridVisualization=rbVisualization,SchedulingLogger=simSchedulingLogger);
end

% The enableSchedulerMetricPlots and enableCDFMetricPlots parameters control the
% display of the MAC scheduler metrics visualization and the cumulative
% distribution function (CDF) visualization of block error rate (BLER) and
% throughput, respectively. By default, these plots are disabled. You can enable
% them by setting the respective flags to true
enableSchedulerMetricPlots = false;
enableCDFMetricPlots = false;

% Set the number of updates for the metrics plot per second, numMetricsSteps,
% during the simulation. The example periodically updates the metrics plots
numMetricsSteps = 20;
% Set up metric visualizer
metricsVisualizer = helperNRMetricsVisualizer(gNB,UEs,RefreshRate=numMetricsSteps, ...
   PlotSchedulerMetrics=enableSchedulerMetricPlots,PlotCDFMetrics=enableCDFMetricPlots);
% Write the logs to MAT-files. The example uses these logs for post-simulation
% analysis
simulationLogFile = "simulationLogs"; % For logging the simulation traces

% Calculate the simulation duration (in seconds)
simulationTime = numFrameSimulation*1e-2;
% Run the simulation
run(networkSimulator,simulationTime)

% Read per-node stats
gNBStats = statistics(gNB);
ueStats = statistics(UEs);
% At the end of the simulation, the achieved value for system performance
% indicators is compared to their theoretical peak values (considering zero
% overheads). Performance indicators displayed are achieved data rate (UL
% and DL) and achieved spectral efficiency (UL and DL). The peak values are
% calculated as per 3GPP TR 37.910
displayPerformanceIndicators(metricsVisualizer)

% Save the simulation logs in a MAT file.
if enableTraces
    simulationLogs = cell(1,1);
    if gNB.DuplexMode == "FDD"
        logInfo = struct("DLTimeStepLogs",[],"ULTimeStepLogs",[],"SchedulingAssignmentLogs",[]);
        [logInfo.DLTimeStepLogs,logInfo.ULTimeStepLogs] = getSchedulingLogs(simSchedulingLogger);
    else % TDD
        logInfo = struct("TimeStepLogs",[],"SchedulingAssignmentLogs",[]);
        logInfo.TimeStepLogs = getSchedulingLogs(simSchedulingLogger);
    end
    % Get the scheduling assignments log
    logInfo.SchedulingAssignmentLogs = getGrantLogs(simSchedulingLogger);
    % Save simulation logs in a MAT-file
    simulationLogs{1} = logInfo;
    save(simulationLogFile,"simulationLogs")
end