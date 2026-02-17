function tests = testNTNCustomScheduler
tests = functiontests(localfunctions);
end

function testContextInitializationOrSkip(testCase)
if exist('nrScheduler', 'class') ~= 8
    assumeFail(testCase, 'nrScheduler (5G Toolbox) is unavailable in this environment.');
end

scheduler = NTNCustomScheduler('xDLThreshold_dB', 3, 'GPMode', "perUE", ...
    'EnablexDL', true, 'xDLReuseRule', "halfRTT", 'SlotDuration_s', 1e-3);
scheduler.addOrUpdateUEContext(1, 6e5, 5);
metrics = scheduler.exportMetrics();
verifyTrue(testCase, scheduler.EnablexDL);
verifyEqual(testCase, string(scheduler.xDLReuseRule), "halfRTT");
verifyEqual(testCase, string(scheduler.GPMode), "perUE");
verifyEqual(testCase, metrics.UEs, 1);
verifyGreaterThanOrEqual(testCase, metrics.GPOverheadSlots, 1);
end
