function kwave_root = locateKWave(explicit_path)
%LOCATEKWAVE Locate and add the pinned k-Wave 1.4.1 dependency.
%
% kwave_root = kwsim.common.locateKWave()
% kwave_root = kwsim.common.locateKWave(explicit_path)
%
% The repository-local toolbox is preferred. An explicit path exists for
% downstream projects that keep k-Wave elsewhere. Only the toolbox root is
% added; the archived project scripts are never added to the MATLAB path.

arguments
    explicit_path {mustBeTextScalar} = ""
end

candidates = strings(0, 1);
if strlength(string(explicit_path)) > 0
    candidates(end + 1, 1) = string(explicit_path);
end

environment_path = string(getenv('KWSIM_KWAVE_PATH'));
if strlength(environment_path) > 0
    candidates(end + 1, 1) = environment_path;
end

candidates(end + 1, 1) = fullfile( ...
    string(kwsim.common.projectRoot()), "k-wave-toolbox-version-1.4.1");

kwave_root = "";
for candidate = candidates.'
    required = ["kWaveGrid.m", "pstdElastic2D.m", "makeDisc.m"];
    present = arrayfun(@(name) isfile(fullfile(candidate, name)), required);
    if all(present)
        kwave_root = candidate;
        break;
    end
end

if strlength(kwave_root) == 0
    error('kwsim:KWaveNotFound', [ ...
        'Could not locate k-Wave 1.4.1. Keep the repository-local toolbox ', ...
        'or set KWSIM_KWAVE_PATH to a toolbox root.']);
end

addpath(char(kwave_root));

end
