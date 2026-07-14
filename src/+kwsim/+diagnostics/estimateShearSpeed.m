function varargout = estimateShearSpeed(varargin)
%estimateShearSpeed Compatibility wrapper for kwsim.analysis.estimateShearSpeed.
%
% This wrapper preserves the original API during the v2 architecture
% migration. New code should call kwsim.analysis.estimateShearSpeed directly.

if nargout == 0
    kwsim.analysis.estimateShearSpeed(varargin{:});
else
    [varargout{1:nargout}] = kwsim.analysis.estimateShearSpeed(varargin{:});
end

end
