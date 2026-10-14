function provenance = getFrameworkProvenance()
%GETFRAMEWORKPROVENANCE Record exact source provenance independent of pwd.
% A git SHA only exactly identifies code when git_dirty is false.
repositoryRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
provenance = struct();
provenance.name = "shear-wave-simulation-framework";
provenance.version = "2.0.0-dev";
provenance.git_commit = gitValue(repositoryRoot,"rev-parse HEAD");
provenance.git_branch = gitValue(repositoryRoot,"symbolic-ref --quiet --short HEAD");
provenance.git_tag = gitValue(repositoryRoot,"describe --tags --exact-match");
[status, dirtyOutput] = gitCommand(repositoryRoot, ...
    "status --porcelain --untracked-files=normal");
provenance.git_dirty = status ~= 0 || strlength(strtrim(dirtyOutput)) > 0;
provenance.matlab_version = string(version);
provenance.captured_at = string(datetime("now", ...
    "Format","yyyy-MM-dd'T'HH:mm:ssXXX"));
end

function output = gitValue(root, argumentsText)
[status, value] = gitCommand(root,argumentsText);
if status == 0 && strlength(strtrim(value)) > 0
    output = strtrim(value);
else
    output = "unknown";
end
end

function [status, output] = gitCommand(root, argumentsText)
% Fixed internal Git arguments: do not accept command strings from configs.
command = "git -C " + char(34) + string(root) + char(34) + ...
    " " + argumentsText;
[status, raw] = system(char(command));
output = string(raw);
end
