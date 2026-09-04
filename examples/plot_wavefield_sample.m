function figure_handle = plot_wavefield_sample(sample, title_text)
%PLOT_WAVEFIELD_SAMPLE Visualize truth and complex harmonic wavefield.

arguments
    sample (1,1) struct
    title_text {mustBeTextScalar} = "Wavefield sample"
end

wavefield.validateSample(sample);

if sample.spatial_dimension ~= 2
    error("examples:Expected2DSample", ...
        "plot_wavefield_sample currently supports 2D samples only.");
end

x_mm = 1e3 * double(sample.coordinates.x_m(:).');
z_mm = 1e3 * double(sample.coordinates.z_m(:));
U = sample.wavefield.data_zx;
cs = sample.truth.cs_map_zx;

figure_handle = figure("Name", char(title_text));
tiledlayout(1,3, "TileSpacing","compact", "Padding","compact");

nexttile;
imagesc(x_mm, z_mm, cs);
axis image;
set(gca,"YDir","normal");
colorbar;
xlabel("x [mm]");
ylabel("z [mm]");
title("Ground-truth SWS [m/s]");

nexttile;
imagesc(x_mm, z_mm, real(U));
axis image;
set(gca,"YDir","normal");
colorbar;
xlabel("x [mm]");
ylabel("z [mm]");
title("Real(U)");

nexttile;
imagesc(x_mm, z_mm, abs(U));
axis image;
set(gca,"YDir","normal");
colorbar;
xlabel("x [mm]");
ylabel("z [mm]");
title("|U|");

sgtitle(title_text, "Interpreter","none");
end
