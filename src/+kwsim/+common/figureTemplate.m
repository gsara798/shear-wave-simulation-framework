function varargout = figureTemplate(varargin)
%FIGURETEMPLATE Compatibility wrapper for kwsim.viz.figureTemplate.
%
% New code should call kwsim.viz.figureTemplate directly.

if nargout == 0
    kwsim.viz.figureTemplate(varargin{:});
else
    [varargout{1:nargout}] = kwsim.viz.figureTemplate(varargin{:});
end

end
