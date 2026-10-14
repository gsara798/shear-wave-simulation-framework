function tests = test_swsynth_framework_provenance
%TEST_SWSYNTH_FRAMEWORK_PROVENANCE Check reproducibility metadata.
tests = functiontests(localfunctions);
end

function testFieldsAndCommit(testCase)
p = swsynth.io.getFrameworkProvenance();
verifyEqual(testCase,p.name,"shear-wave-simulation-framework");
verifyEqual(testCase,p.version,"2.0.0-dev");
verifyTrue(testCase,isfield(p,"git_commit"));
verifyTrue(testCase,isfield(p,"git_branch"));
verifyTrue(testCase,isfield(p,"git_dirty"));
verifyClass(testCase,p.git_dirty,"logical");
verifyTrue(testCase,isfield(p,"matlab_version"));
verifyTrue(testCase,isfield(p,"captured_at"));
end

function testDoesNotDependOnCurrentDirectory(testCase)
original = pwd;
cleanup = onCleanup(@() cd(original)); %#ok<NASGU>
first = swsynth.io.getFrameworkProvenance();
cd(tempdir);
second = swsynth.io.getFrameworkProvenance();
verifyEqual(testCase,first.git_commit,second.git_commit);
verifyEqual(testCase,first.git_branch,second.git_branch);
end
