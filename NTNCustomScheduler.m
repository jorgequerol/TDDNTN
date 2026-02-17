classdef NTNCustomScheduler < nrScheduler
    %NTNCustomScheduler Scheduler with GP modes and optional xDL reuse.

    properties
        % xDL SINR threshold in dB. Use -Inf or "none" to always allow xDL.
        xDLThreshold_dB = -Inf

        % GP selection behavior: "worst" | "min" | "perUE"
        GPMode {mustBeTextScalar} = "perUE"

        % Enable/disable xDL reuse over GP region
        EnablexDL (1,1) logical = true

        % xDL reuse rule (Milestone 2): "halfRTT"
        xDLReuseRule {mustBeTextScalar} = "halfRTT"

        % Frame plan parameters for smoke/demo use
        TframeSlots (1,1) double {mustBeInteger,mustBePositive} = 10
        DLSlots (1,1) double {mustBeInteger,mustBeNonnegative} = 5
        ULSlots (1,1) double {mustBeInteger,mustBeNonnegative} = 3

        % Default slot duration (s) used for gpSlots = ceil(RTT/slotDuration)
        SlotDuration_s (1,1) double {mustBePositive} = 1e-3
    end

    properties (Access = private)
        GlobalSlotCounter = 0
        LastPlan
        LastTimeResource = NaN
    end

    methods
        function obj = NTNCustomScheduler(varargin)
            if mod(nargin, 2) ~= 0
                error('NTNCustomScheduler:InvalidPairs', 'Use name-value pairs.');
            end
            for i = 1:2:nargin
                obj.(varargin{i}) = varargin{i+1};
            end
        end

        function addOrUpdateUEContext(obj, rnti, slantRangeMeters, sinr_dB)
            [gpSlots, rttSeconds] = ntn.computeGP(slantRangeMeters, obj.SlotDuration_s);
            custom = struct( ...
                'RTT_s', rttSeconds, ...
                'SlantRange_m', slantRangeMeters, ...
                'GPSlots', gpSlots, ...
                'SINR_dB', sinr_dB, ...
                'DLRBs', 0, ...
                'xDLRBs', 0, ...
                'ULRBs', 0, ...
                'ScheduledBytesDL', 0, ...
                'ScheduledBytesxDL', 0, ...
                'ScheduledBytesUL', 0, ...
                'GPOverheadSlots', gpSlots);

            if numel(obj.UEContext) < rnti || isempty(obj.UEContext(rnti))
                obj.UEContext(rnti).RNTI = rnti;
            end
            obj.UEContext(rnti).CustomContext = custom;
        end

        function metrics = exportMetrics(obj)
            ueIDs = find(~arrayfun(@isempty, obj.UEContext));
            n = numel(ueIDs);
            metrics = struct();
            metrics.UEs = ueIDs;
            metrics.DLRBs = zeros(1, n);
            metrics.xDLRBs = zeros(1, n);
            metrics.ULRBs = zeros(1, n);
            metrics.GPOverheadSlots = zeros(1, n);
            metrics.BytesDL = zeros(1, n);
            metrics.BytesxDL = zeros(1, n);
            metrics.BytesUL = zeros(1, n);
            for idx = 1:n
                rnti = ueIDs(idx);
                c = obj.UEContext(rnti).CustomContext;
                metrics.DLRBs(idx) = c.DLRBs;
                metrics.xDLRBs(idx) = c.xDLRBs;
                metrics.ULRBs(idx) = c.ULRBs;
                metrics.GPOverheadSlots(idx) = c.GPOverheadSlots;
                metrics.BytesDL(idx) = c.ScheduledBytesDL;
                metrics.BytesxDL(idx) = c.ScheduledBytesxDL;
                metrics.BytesUL(idx) = c.ScheduledBytesUL;
            end
            metrics.LastFramePlan = obj.LastPlan;
        end
    end

    methods (Access = protected)
        function dlAssignments = scheduleNewTransmissionsDL(obj, timeResource, frequencyResource, schedulingInfo)
            eligibleUEs = schedulingInfo.EligibleUEs;
            assignStruct = struct('RNTI',[],'FrequencyAllocation',[], ...
                'MCSIndex',[],'NumLayers',[],'TPMI',[]);
            dlAssignments = repmat(assignStruct, numel(eligibleUEs), 1);
            if isempty(eligibleUEs)
                return;
            end

            framePlan = obj.getFramePlanForSlot(timeResource);
            inDL = ismember(framePlan.slotInFrame, framePlan.DL);
            inXDL = ismember(framePlan.slotInFrame, framePlan.xDL);
            if ~(inDL || inXDL)
                return;
            end

            firstFreeRB = find(frequencyResource == 0, 1) - 1;
            if isempty(firstFreeRB)
                return;
            end
            numRBs = obj.CellConfig.NumResourceBlocks;
            availableRBs = numRBs - firstFreeRB;
            if availableRBs <= 0
                return;
            end

            selectedUE = eligibleUEs(1);
            isxDLSlotForUE = false;
            if inXDL
                sinr_dB = obj.getxDLSINR(selectedUE, schedulingInfo);
                isxDLSlotForUE = ntn.isxDLEligible(sinr_dB, obj.xDLThreshold_dB);
                if ~isxDLSlotForUE
                    return;
                end
            end

            dlAssignments(1).RNTI = selectedUE;
            dlAssignments(1).FrequencyAllocation = [firstFreeRB availableRBs];
            dlAssignments(1).MCSIndex = 10;
            dlAssignments(1).NumLayers = 1;
            dlAssignments(1).TPMI = 0;

            obj.updateDLStats(selectedUE, availableRBs, isxDLSlotForUE);
        end

        function ulGrants = scheduleNewTransmissionsUL(obj, timeResource, frequencyResource, schedulingInfo)
            eligibleUEs = schedulingInfo.EligibleUEs;
            grantStruct = struct('RNTI',[],'FrequencyAllocation',[], ...
                'MCSIndex',[],'NumLayers',[],'TPMI',[]);
            ulGrants = repmat(grantStruct, numel(eligibleUEs), 1);
            if isempty(eligibleUEs)
                return;
            end

            framePlan = obj.getFramePlanForSlot(timeResource);
            if ~ismember(framePlan.slotInFrame, framePlan.UL)
                return;
            end

            firstFreeRB = find(frequencyResource == 0, 1) - 1;
            if isempty(firstFreeRB)
                return;
            end
            numRBs = obj.CellConfig.NumResourceBlocks;
            availableRBs = numRBs - firstFreeRB;
            if availableRBs <= 0
                return;
            end

            grantCount = 0;
            for i = 1:numel(eligibleUEs)
                ue = eligibleUEs(i);
                if ~obj.hasStructuralGPBudget(ue, framePlan)
                    continue;
                end
                grantCount = grantCount + 1;
                ulGrants(grantCount).RNTI = ue;
                ulGrants(grantCount).FrequencyAllocation = [firstFreeRB availableRBs];
                ulGrants(grantCount).MCSIndex = 10;
                ulGrants(grantCount).NumLayers = 1;
                ulGrants(grantCount).TPMI = 0;
                obj.updateULStats(ue, availableRBs);
                break;
            end
            ulGrants = ulGrants(1:grantCount);
        end

        function sinr_dB = getxDLSINR(obj, rnti, ~)
            %getxDLSINR Hook for future PHY/MAC SINR integration.
            sinr_dB = obj.UEContext(rnti).CustomContext.SINR_dB;
        end
    end

    methods (Access = private)
        function framePlan = getFramePlanForSlot(obj, timeResource)
            if nargin < 2 || isempty(timeResource)
                obj.GlobalSlotCounter = obj.GlobalSlotCounter + 1;
            else
                thisTime = double(timeResource(1));
                if ~isequaln(thisTime, obj.LastTimeResource)
                    obj.GlobalSlotCounter = obj.GlobalSlotCounter + 1;
                    obj.LastTimeResource = thisTime;
                end
            end

            gpPerUE = obj.getGPSlotsPerUE();
            gpSelected = ntn.selectGPSlots(gpPerUE, obj.GPMode);
            gpSelected = min(gpSelected, max(0, obj.TframeSlots - obj.DLSlots - obj.ULSlots));

            xdlSlots = ntn.computeXDLReuseSlots(gpSelected, obj.xDLReuseRule, obj.EnablexDL);
            framePlan = ntn.buildFramePlan(obj.TframeSlots, obj.DLSlots, obj.ULSlots, gpSelected, xdlSlots);
            framePlan.slotInFrame = mod(obj.GlobalSlotCounter - 1, obj.TframeSlots) + 1;
            framePlan.GPSelected = gpSelected;
            framePlan.GPMode = string(obj.GPMode);
            framePlan.EnablexDL = obj.EnablexDL;
            framePlan.xDLReuseSlots = xdlSlots;
            obj.LastPlan = framePlan;
        end

        function gpPerUE = getGPSlotsPerUE(obj)
            gpPerUE = 0;
            if isempty(obj.UEContext)
                return;
            end
            hasContext = arrayfun(@(u) ~isempty(u) && isfield(u, 'CustomContext') && ...
                ~isempty(u.CustomContext), obj.UEContext);
            if any(hasContext)
                gpPerUE = arrayfun(@(u) u.CustomContext.GPSlots, obj.UEContext(hasContext));
            end
        end

        function tf = hasStructuralGPBudget(obj, ue, framePlan)
            c = obj.UEContext(ue).CustomContext;
            switch lower(string(obj.GPMode))
                case "worst"
                    tf = framePlan.GPSelected <= numel(framePlan.GPIdle);
                case "min"
                    tf = framePlan.GPSelected <= numel(framePlan.GPIdle);
                case "perue"
                    tf = c.GPSlots <= numel(framePlan.GPIdle);
                otherwise
                    tf = false;
            end
        end

        function updateDLStats(obj, ue, rbCount, isxDL)
            c = obj.UEContext(ue).CustomContext;
            if isxDL
                c.xDLRBs = c.xDLRBs + rbCount;
                c.ScheduledBytesxDL = c.ScheduledBytesxDL + 12 * rbCount;
            else
                c.DLRBs = c.DLRBs + rbCount;
                c.ScheduledBytesDL = c.ScheduledBytesDL + 12 * rbCount;
            end
            obj.UEContext(ue).CustomContext = c;
        end

        function updateULStats(obj, ue, rbCount)
            c = obj.UEContext(ue).CustomContext;
            c.ULRBs = c.ULRBs + rbCount;
            c.ScheduledBytesUL = c.ScheduledBytesUL + 12 * rbCount;
            obj.UEContext(ue).CustomContext = c;
        end
    end
end
