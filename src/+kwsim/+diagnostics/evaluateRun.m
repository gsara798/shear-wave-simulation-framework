function varargout = evaluateRun(varargin)
%EVALUATERUN Compatibility wrapper for kwsim.validation.evaluateRun.
%
% This wrapper preserves the original API during the v2 architecture
% migration. New code should call kwsim.validation.evaluateRun directly.

if nargout == 0
    kwsim.validation.evaluateRun(varargin{:});
else
    [varargout{1:nargout}] = kwsim.validation.evaluateRun(varargin{:});
end

end
