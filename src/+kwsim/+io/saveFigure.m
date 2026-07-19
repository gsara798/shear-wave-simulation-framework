function saved_paths = saveFigure( ...
    figure_handle, figures_directory, base_name, options)
%SAVEFIGURE Save a MATLAB figure as PNG and optionally as FIG.
%
% The destination directory may be either a figures directory or the paths
% structure returned by kwsim.io.createRunDirectory.

arguments
    figure_handle (1,1)
    figures_directory
    base_name (1,1) string
    options.ResolutionDpi (1,1) double ...
        {mustBeFinite, mustBePositive} = 180
    options.SaveMatlabFigure (1,1) logical = true
    options.Overwrite (1,1) logical = false
end

if ~isgraphics(figure_handle, "figure")
    error("kwsim:InvalidFigureHandle", ...
        "figure_handle must be a valid MATLAB figure.");
end

if isstruct(figures_directory)
    if ~isfield(figures_directory, "figures")
        error("kwsim:InvalidOutputPaths", ...
            "Output paths structure is missing the figures field.");
    end

    figures_directory = figures_directory.figures;
end

figures_directory = string(figures_directory);

if ~isfolder(figures_directory)
    mkdir(figures_directory);
end

base_name = sanitizeBaseName(base_name);

png_path = fullfile( ...
    figures_directory, ...
    base_name + ".png");

fig_path = fullfile( ...
    figures_directory, ...
    base_name + ".fig");

assertWritable(png_path, options.Overwrite);

exportgraphics( ...
    figure_handle, ...
    png_path, ...
    Resolution=options.ResolutionDpi);

saved_paths = struct();
saved_paths.png = string(png_path);
saved_paths.fig = "";

if options.SaveMatlabFigure
    assertWritable(fig_path, options.Overwrite);

    savefig(figure_handle, fig_path);
    saved_paths.fig = string(fig_path);
end

end


function name = sanitizeBaseName(name)

name = strtrim(string(name));
name = regexprep(name, '[^a-zA-Z0-9_-]+', '_');
name = regexprep(name, '_+', '_');
name = regexprep(name, '^[_-]+|[_-]+$', '');

if strlength(name) == 0
    error("kwsim:InvalidFigureName", ...
        "base_name cannot be empty.");
end

end


function assertWritable(path, overwrite)

if isfile(path) && ~overwrite
    error("kwsim:OutputFileExists", ...
        "Output file already exists: %s", path);
end

end
