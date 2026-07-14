function varargout = angularSpectrum2D(varargin)
%angularSpectrum2D Compatibility wrapper for kwsim.analysis.angularSpectrum2D.
%
% This wrapper preserves the original API during the v2 architecture
% migration. New code should call kwsim.analysis.angularSpectrum2D directly.

if nargout == 0
    kwsim.analysis.angularSpectrum2D(varargin{:});
else
    [varargout{1:nargout}] = kwsim.analysis.angularSpectrum2D(varargin{:});
end

end
