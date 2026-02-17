function tests = testTimeResourceKey
tests = functiontests(localfunctions);
end

function testNumericKey(testCase)
verifyEqual(testCase, ntn.getTimeResourceKey(42), 42);
end

function testStructNestedSlot(testCase)
tr = struct('NSlot', struct('Value', 17));
verifyEqual(testCase, ntn.getTimeResourceKey(tr), 17);
end

function testStructFrameSlot(testCase)
tr = struct('NFrame', 2, 'NSlot', 5);
verifyEqual(testCase, ntn.getTimeResourceKey(tr), 200005);
end

function testCellKey(testCase)
tr = {3, struct('Timestamp', 10)};
verifyEqual(testCase, ntn.getTimeResourceKey(tr), 23);
end
