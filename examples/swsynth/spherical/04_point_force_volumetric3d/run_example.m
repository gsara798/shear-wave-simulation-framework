%RUN_EXAMPLE Volumetric far-field shear radiation from 3 point forces.
root = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
addpath(fullfile(root,'src'));
cfg = jsondecode(fileread(fullfile(fileparts(mfilename('fullpath')),'config.json')));
result = swsynth.run3D(cfg);
U = result.wavefield.U_zyx;
fprintf('Volumetric point force U(z,y,x): [%s]\\n',num2str(size(U)));
figure;
imagesc(result.coordinates.x_m,result.coordinates.z_m, ...
    abs(squeeze(U(:,1,:))));
axis image; colorbar; xlabel('x (m)'); ylabel('z (m)');
title('Shear far-field point sources, y = 0');
