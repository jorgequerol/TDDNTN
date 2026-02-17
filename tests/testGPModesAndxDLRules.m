function tests = testGPModesAndxDLRules
tests = functiontests(localfunctions);
end

function testHalfRTTReuseRule(testCase)
verifyEqual(testCase, ntn.computeXDLReuseSlots(0, "halfRTT", true), 0);
verifyEqual(testCase, ntn.computeXDLReuseSlots(5, "halfRTT", true), 2);
verifyEqual(testCase, ntn.computeXDLReuseSlots(6, "halfRTT", true), 3);
verifyEqual(testCase, ntn.computeXDLReuseSlots(6, "halfRTT", false), 0);
end

function testThresholdGating(testCase)
sinr = [-2 0 1 4];
verifyEqual(testCase, ntn.isxDLEligible(sinr, "none"), [true true true true]);
verifyEqual(testCase, ntn.isxDLEligible(sinr, 0), [false true true true]);
verifyEqual(testCase, ntn.isxDLEligible(sinr, 3), [false false false true]);
end

function testGPModeSelection(testCase)
gpUE = [2 4 6];
verifyEqual(testCase, ntn.selectGPSlots(gpUE, "worst"), 6);
verifyEqual(testCase, ntn.selectGPSlots(gpUE, "min"), 2);
verifyEqual(testCase, ntn.selectGPSlots(gpUE, "perUE"), 6);
end

function testFrameOrderGPIdleThenxDL(testCase)
plan = ntn.buildFramePlan(20, 8, 6, 4, 2);
verifyEqual(testCase, plan.GPIdle, [9 10]);
verifyEqual(testCase, plan.xDL, [11 12]);
verifyEqual(testCase, numel(intersect(plan.GPIdle, plan.xDL)), 0);
end
