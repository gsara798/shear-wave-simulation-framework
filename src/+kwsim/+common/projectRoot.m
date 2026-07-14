function root = projectRoot()
%PROJECTROOT Return the absolute root directory of this repository.
%
% The calculation is based on this file's location, not on the current
% working directory. This makes examples and downstream callers independent
% of where MATLAB was launched.

common_dir = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(fileparts(common_dir)));

end
