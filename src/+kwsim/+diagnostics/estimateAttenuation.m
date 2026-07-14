function varargout = estimateAttenuation(varargin)
%estimateAttenuation Compatibility wrapper for kwsim.analysis.estimateAttenuation.
%
% This wrapper preserves the original API during the v2 architecture
% migration. New code should call kwsim.analysis.estimateAttenuation directly.

if nargout == 0
    kwsim.analysis.estimateAttenuation(varargin{:});
else
    [varargout{1:nargout}] = kwsim.analysis.estimateAttenuation(varargin{:});
end

end
