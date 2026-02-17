% run_tests Execute matlab.unittest test suite.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repoRoot));

suite = testsuite(fullfile(repoRoot, 'tests'));
results = run(suite);
disp(results);

assert(all([results.Passed]), 'One or more tests failed.');
