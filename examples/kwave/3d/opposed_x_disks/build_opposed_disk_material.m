function [medium,truth,cpMaximum]=build_opposed_disk_material(C,N,z,roi_ix,roi_iz)
%BUILD_OPPOSED_DISK_MATERIAL Material map for the SAME opposed-disk solver.
% The source masks, drive waveforms and observation geometry are controlled
% exclusively by run_opposed_x_disks_3d; this function changes none of them.
% Bilayer convention: negative z = soft, positive z = hard (configurable).
arguments
    C (1,1) struct
    N (1,3) double {mustBeInteger,mustBePositive}
    z (1,:) double
    roi_ix (1,:) double {mustBeInteger,mustBePositive}
    roi_iz (1,:) double {mustBeInteger,mustBePositive}
end
assert(numel(z)==N(3) && all(roi_ix<=N(1)) && all(roi_iz<=N(3)), ...
    "OpposedDisks:MaterialAxes","Invalid 3D/material observation axes.");
factor=double(C.compressional_speed_factor);
rho=double(C.density_kg_m3);
assert(isfinite(factor) && factor>1 && isfinite(rho) && rho>0, ...
    "OpposedDisks:MaterialParameters","Invalid compressional ratio or density.");

isBilayer=isfield(C,"bilayer") && isstruct(C.bilayer) && ...
    isfield(C.bilayer,"enabled") && logical(C.bilayer.enabled);
if isBilayer
    assert(string(C.experiment)=="opposed_x_disks_bilayer_3d", ...
        "OpposedDisks:BilayerIdentity","Bilayer config must identify its experiment.");
    B=C.bilayer;
    required=["interface_z_m","negative_z_cs_m_s","positive_z_cs_m_s"];
    assert(all(isfield(B,cellstr(required))), ...
        "OpposedDisks:BilayerFields","Missing bilayer geometry or speed.");
    interface=double(B.interface_z_m);
    negative=double(B.negative_z_cs_m_s);
    positive=double(B.positive_z_cs_m_s);
    assert(all(isfinite([interface negative positive])) && ...
        negative>0 && positive>0 && abs(negative-positive)>eps, ...
        "OpposedDisks:BilayerParameters","Invalid bilayer interface/speeds.");
    assert(any(z(roi_iz)<interface) && any(z(roi_iz)>=interface), ...
        "OpposedDisks:BilayerOutsideROI", ...
        "Both layers must be represented inside the observation FOV.");
    % C.cs_m_s is retained as the legacy reference speed for config
    % compatibility; it must agree with the negative-z layer.
    assert(abs(double(C.cs_m_s)-negative)<1e-10, ...
        "OpposedDisks:LegacyCsMismatch","Reference cs must match negative-z layer.");
    csZ=negative*ones(1,N(3));
    csZ(z>=interface)=positive;
    idZ=uint8(2)*ones(1,N(3),"uint8");
    idZ(z>=interface)=uint8(3);
    truth=struct("cs_m_s_zx",repmat(csZ(roi_iz).',1,numel(roi_ix)), ...
        "material_id_zx",repmat(idZ(roi_iz).',1,numel(roi_ix)), ...
        "interface_z_m",interface, ...
        "negative_z_cs_m_s",negative,"positive_z_cs_m_s",positive);
else
    assert(string(C.experiment)=="opposed_x_disks_3d", ...
        "OpposedDisks:HomogeneousIdentity","Unexpected homogeneous experiment.");
    cs=double(C.cs_m_s);
    assert(isfinite(cs) && cs>0,"OpposedDisks:HomogeneousCs", ...
        "Invalid homogeneous shear speed.");
    csZ=cs*ones(1,N(3));
    truth=struct("cs_m_s_zx",cs*ones(numel(roi_iz),numel(roi_ix)));
end
csVolume=repmat(reshape(single(csZ),1,1,N(3)),N(1),N(2),1);
medium=struct();
medium.sound_speed_shear=csVolume;
medium.sound_speed_compression=single(factor).*csVolume;
medium.density=single(rho)*ones(N(1),N(2),N(3),"single");
cpMaximum=max(csZ)*factor;
end
