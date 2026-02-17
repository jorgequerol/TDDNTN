function tests = testComputeGP
tests = functiontests(localfunctions);
end

function testRTTAndSlots(testCase)
[gpSlots, rtt] = ntn.computeGP(3e5, 1e-3);
verifyEqual(testCase, gpSlots, 3);
verifyGreaterThan(testCase, rtt, 0);
end

function testVectorizedInput(testCase)
[gpSlots, ~] = ntn.computeGP([0 3e5 6e5], 1e-3);
verifyEqual(testCase, gpSlots, [0 3 5]);
end
