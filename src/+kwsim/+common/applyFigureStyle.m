function varargout = applyFigureStyle(varargin)
%APPLYFIGURESTYLE Compatibility wrapper for kwsim.viz.applyFigureStyle.
%
% New code should call kwsim.viz.applyFigureStyle directly.

if nargout == 0
    kwsim.viz.applyFigureStyle(varargin{:});
else
    [varargout{1:nargout}] = kwsim.viz.applyFigureStyle(varargin{:});
end

end
