function kwave_root = locateKWave(explicit_path)
%LOCATEKWAVE Locate and add the external k-Wave 1.4.1 dependency.
%
% kwave_root = kwsim.io.locateKWave()
% kwave_root = kwsim.io.locateKWave(explicit_path)
%
% k-Wave is an external dependency and is not vendored in this repository.
% Supply the toolbox root explicitly or set the KWSIM_KWAVE_PATH environment
% variable. Only the toolbox root is added to the MATLAB path.

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
        'Could not locate k-Wave 1.4.1. Set KWSIM_KWAVE_PATH to the ', ...
        'k-Wave toolbox root or pass the toolbox path explicitly.']);
end

addpath(char(kwave_root));

end
