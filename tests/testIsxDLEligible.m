function tests = testIsxDLEligible
tests = functiontests(localfunctions);
end

function testNumericThreshold(testCase)
tf = ntn.isxDLEligible([5 1], 3);
verifyEqual(testCase, tf, [true false]);
end

function testNoneAndNegativeInfinity(testCase)
verifyTrue(testCase, all(ntn.isxDLEligible([-10 0], 'none')));
verifyTrue(testCase, all(ntn.isxDLEligible([-10 0], -Inf)));
end
