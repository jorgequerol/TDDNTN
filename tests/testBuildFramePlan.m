function tests = testBuildFramePlan
tests = functiontests(localfunctions);
end

function testIndices(testCase)
plan = ntn.buildFramePlan(10, 5, 3, 2, 1);
verifyEqual(testCase, plan.DL, 1:5);
verifyEqual(testCase, plan.GP, 6:7);
verifyEqual(testCase, plan.GPIdle, 6);
verifyEqual(testCase, plan.xDL, 7);
verifyEqual(testCase, plan.UL, 8:10);
end

function testxDLSubsetOfGP(testCase)
plan = ntn.buildFramePlan(12, 4, 4, 3, 2);
verifyTrue(testCase, all(ismember(plan.xDL, plan.GP)));
verifyEqual(testCase, numel(intersect(plan.xDL, plan.GPIdle)), 0);
verifyLessThan(testCase, max(plan.GPIdle), min(plan.xDL));
end

function testInvalidPlanThrows(testCase)
verifyError(testCase, @() ntn.buildFramePlan(5, 3, 3, 1), 'ntn:InvalidFramePlan');
end
