function kwave_root = locate_kwave_toolbox(varargin)
%LOCATE_KWAVE_TOOLBOX Locate and add a local k-Wave toolbox installation.
%
% Usage:
%   kwave_root = adaptive_req.kwave.locate_kwave_toolbox()
%   kwave_root = adaptive_req.kwave.locate_kwave_toolbox('/path/to/k-wave')
%
% The lookup order is:
%   1. Explicit path argument.
%   2. ADAPTIVE_REQ_KWAVE_PATH environment variable.
%   3. Common local paths used in this project.
%
% This function does not move or copy the toolbox. It only validates that
% the installation contains the core files needed by the controlled
% simulations and then adds the toolbox root to the MATLAB path.

p = inputParser;
p.FunctionName = 'adaptive_req.kwave.locate_kwave_toolbox';
addOptional(p, 'kwave_root', "", @(x) ischar(x) || isstring(x));
addParameter(p, 'AddPath', true, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});

candidate = string(p.Results.kwave_root);
if strlength(candidate) == 0
    candidate = string(getenv('ADAPTIVE_REQ_KWAVE_PATH'));
end

candidates = strings(0, 1);
if strlength(candidate) > 0
    candidates(end + 1, 1) = candidate; %#ok<AGROW>
end

home_dir = string(char(java.lang.System.getProperty('user.home')));
candidates = [candidates; ...
    home_dir + "/Documents/k-wave-toolbox-version-1.4.1"; ...
    home_dir + "/MATLAB/k-wave-toolbox-version-1.4.1"; ...
    home_dir + "/Documents/MATLAB/k-wave-toolbox-version-1.4.1"];

kwave_root = "";
for i = 1:numel(candidates)
    path_i = char(candidates(i));
    if exist(fullfile(path_i, 'kWaveGrid.m'), 'file') == 2 && ...
            exist(fullfile(path_i, 'pstdElastic2D.m'), 'file') == 2
        kwave_root = string(path_i);
        break;
    end
end

if strlength(kwave_root) == 0
    error(['Could not locate k-Wave. Set ADAPTIVE_REQ_KWAVE_PATH to the ', ...
        'toolbox root, for example: ', ...
        '/Users/sara/Documents/k-wave-toolbox-version-1.4.1']);
end

if logical(p.Results.AddPath)
    addpath(char(kwave_root));
end

required_files = ["kWaveGrid.m", "pstdElastic2D.m", "makeDisc.m"];
missing = strings(0, 1);
for i = 1:numel(required_files)
    if exist(fullfile(char(kwave_root), char(required_files(i))), 'file') ~= 2
        missing(end + 1, 1) = required_files(i); %#ok<AGROW>
    end
end

if ~isempty(missing)
    error('k-Wave root found at %s but missing: %s', ...
        kwave_root, strjoin(missing, ', '));
end

end
