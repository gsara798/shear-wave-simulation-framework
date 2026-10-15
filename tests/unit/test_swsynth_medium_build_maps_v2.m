function tests=test_swsynth_medium_build_maps_v2
% V2 physical medium tests: independent analytical masks, no old defaults.
tests=functiontests(localfunctions);
end

function testHomogeneous2DIndependentOfFrequency(tc)
[g,m]=base2D();
a=swsynth.medium.buildMaps(g,m);
verifySize(tc,a.cs_map_zx,[21 31]);
verifyEqual(tc,a.cs_map_zx,2*ones(21,31));
verifyEqual(tc,a.material_id_zx,zeros(21,31,"uint16"));
verifyEmpty(tc,a.object_alpha_zx);
verifyFalse(tc,isfield(a,"k_map_zx"));
verifyFalse(tc,isfield(a,"frequency_hz"));
verifyEqual(tc,a.output_convention,"maps(z,x)");
end

function testCircleMatchesExactAnalyticalMask(tc)
[g,m]=base2D();
% A non-grid-aligned radius avoids roundoff ambiguity for points
% exactly on a circle boundary; geometric inclusion is still checked
% independently at every pixel.
radius=.00525;
m.objects={struct("type","circle","cs_m_s",4.5, ...
    "center_xz_m",[.015 .01],"radius_m",radius)};
a=swsynth.medium.buildMaps(g,m);
[X,Z]=meshgrid(g.x_m,g.z_m);
inside=(X-.015).^2+(Z-.01).^2<=radius^2;
verifyEqual(tc,a.cs_map_zx,2+2.5*double(inside));
verifyEqual(tc,a.material_id_zx,uint16(inside));
verifyEqual(tc,a.object_alpha_zx{1},double(inside));
end

function testSharpBilayerAndCircleOverlayPriority(tc)
[g,m]=base2D();
m.objects={ ...
    struct("type","bilayer","cs_m_s",3.5, ...
        "normal_angle_rad",pi/4,"offset_m",.018), ...
    struct("type","circle","cs_m_s",4, ...
        "center_xz_m",[.02 .01],"radius_m",.004)};
a=swsynth.medium.buildMaps(g,m);
[X,Z]=meshgrid(g.x_m,g.z_m);
b=(X+Z)/sqrt(2)>.018;
circle=(X-.02).^2+(Z-.01).^2<=.004^2;
expected=2*ones(size(X));
expected(b)=3.5;
expected(circle)=4;
ids=zeros(size(X),"uint16");
ids(b)=1;ids(circle)=2;
verifyEqual(tc,a.cs_map_zx,expected);
verifyEqual(tc,a.material_id_zx,ids);
end

function testCustomMaskAppliedInZXOrder(tc)
[g,m]=base2D();
mask=false(g.spatial_size);
mask(3,8)=true;
m.objects={struct("type","custom","cs_m_s",4,"mask_zx",mask)};
a=swsynth.medium.buildMaps(g,m);
verifyEqual(tc,a.cs_map_zx,2+2*double(mask));
verifyEqual(tc,a.material_id_zx,uint16(mask));
verifyEqual(tc,a.object_alpha_zx{1},double(mask));
end

function testCombineModesFollowIndependentSharpMaskReference(tc)
[g,base]=base2D();
base.objects={ ...
    struct("type","circle","cs_m_s",3, ...
        "center_xz_m",[.012 .01],"radius_m",.008), ...
    struct("type","circle","cs_m_s",4, ...
        "center_xz_m",[.02 .01],"radius_m",.008)};
[X,Z]=meshgrid(g.x_m,g.z_m);
a1=double((X-.012).^2+(Z-.01).^2<=.008^2);
a2=double((X-.02).^2+(Z-.01).^2<=.008^2);
for mode=["overlay","blend","min","max"]
    m=base;m.combine_mode=mode;
    actual=swsynth.medium.buildMaps(g,m);
    switch mode
        case "overlay"
            expected=2+1*a1;
            expected(a2>0)=4;
        case "blend"
            amount=a1+a2;
            mix=(3*a1+4*a2)./max(amount,eps);
            total=min(amount,1);
            expected=2*(1-total)+total.*mix;
        case "max"
            expected=max(max(2*ones(size(a1)),2+a1),2+2*a2);
        case "min"
            expected=2*ones(size(a1));
    end
    verifyEqual(tc,actual.cs_map_zx,expected,"AbsTol",1e-13);
    verifyEqual(tc,actual.object_alpha_zx{1},a1);
    verifyEqual(tc,actual.object_alpha_zx{2},a2);
end
end

function testSmoothCircleBoundedAndCoherentWhenToolboxAvailable(tc)
if exist("imgaussfilt","file")~=2;return;end
[g,m]=base2D();
m.objects={struct("type","circle","cs_m_s",4, ...
    "center_xz_m",[.015 .01],"radius_m",.006, ...
    "edge_sigma_m",.001)};
a=swsynth.medium.buildMaps(g,m);
alpha=a.object_alpha_zx{1};
verifyGreaterThanOrEqual(tc,min(alpha(:)),0);
verifyLessThanOrEqual(tc,max(alpha(:)),1+1e-12);
verifyEqual(tc,a.cs_map_zx,2+2*alpha,"AbsTol",1e-13);
verifyGreaterThan(tc,max(alpha(:)),.9);
end

function testHomogeneous3DMaterialAxesAndIDs(tc)
[g,m]=base3D();
a=swsynth.medium.buildMaps(g,m);
verifySize(tc,a.cs_map_zyx,[5 4 6]);
verifyEqual(tc,a.cs_map_zyx,2*ones(5,4,6));
verifyEqual(tc,a.material_id_zyx,zeros(5,4,6,"uint16"));
verifyEmpty(tc,a.object_alpha_zyx);
verifyEqual(tc,a.output_convention,"maps(z,y,x)");
verifyFalse(tc,isfield(a,"k_map_zyx"));
end

function testVolumetricSphereExactMask(tc)
[g,m]=base3D();
m.objects={struct("type","sphere","center_xyz_m",[.003 .002 .002], ...
    "radius_m",.0011,"cs_m_s",3)};
a=swsynth.medium.buildMaps(g,m);
[Z,Y,X]=ndgrid(g.z_m,g.y_m,g.x_m);
mask=(X-.003).^2+(Y-.002).^2+(Z-.002).^2<=.0011^2;
verifyEqual(tc,a.cs_map_zyx,2+double(mask));
verifyEqual(tc,a.material_id_zyx,uint16(mask));
verifyEqual(tc,a.object_alpha_zyx{1},double(mask));
end

function testVolumetricBoxAndSlabOverlay(tc)
[g,m]=base3D();
m.objects={ ...
    struct("type","box","center_xyz_m",[.003 .002 .002], ...
        "size_xyz_m",[.002 .002 .002],"cs_m_s",3), ...
    struct("type","slab","normal_xyz",[0 0 1], ...
        "offset_m",.003,"cs_m_s",4)};
a=swsynth.medium.buildMaps(g,m);
[Z,Y,X]=ndgrid(g.z_m,g.y_m,g.x_m);
box=abs(X-.003)<=.001 & abs(Y-.002)<=.001 & abs(Z-.002)<=.001;
slab=Z>=.003;
expected=2*ones(g.spatial_size);
expected(box)=3;expected(slab)=4;
ids=zeros(g.spatial_size,"uint16");
ids(box)=1;ids(slab)=2;
verifyEqual(tc,a.cs_map_zyx,expected);
verifyEqual(tc,a.material_id_zyx,ids);
end

function testVolumetricCustomMaskInZYX(tc)
[g,m]=base3D();
mask=false(g.spatial_size);mask(3,2,4)=true;
m.objects={struct("type","custom","mask_zyx",mask,"cs_m_s",4)};
a=swsynth.medium.buildMaps(g,m);
verifyEqual(tc,a.cs_map_zyx,2+2*double(mask));
verifyEqual(tc,a.material_id_zyx,uint16(mask));
verifyEqual(tc,a.object_alpha_zyx{1},double(mask));
end

function testExplicitShiftedGridStillCorrect(tc)
g=swsynth.domain.buildGrid(struct("geometry","2d", ...
    "x_m",[-.02 -.01 0],"z_m",[.01 .02 .03]));
m=struct("cs_m_s",2);
m.objects={struct("type","circle","center_xz_m",[-.01 .02], ...
    "radius_m",.001,"cs_m_s",3)};
a=swsynth.medium.buildMaps(g,m);
verifyEqual(tc,a.cs_map_zx(2,2),3);
verifyEqual(tc,a.cs_map_zx(1,1),2);
verifyEqual(tc,a.x_m,g.x_m);
end

function testDensityIsMetadataNotShearSpeed(tc)
[g,m]=base2D();
a=swsynth.medium.buildMaps(g,m);
m.density_kg_m3=1000;
b=swsynth.medium.buildMaps(g,m);
verifyEqual(tc,b.cs_map_zx,a.cs_map_zx);
verifyEqual(tc,b.density_kg_m3,1000);
end

function testRejectFrequencyInMedium(tc)
[g,m]=base2D();m.frequency_hz=500;
verifyError(tc,@() swsynth.medium.buildMaps(g,m), ...
    "swsynth:MediumCannotOwnFrequency");
end

function testRejectUnsupportedConstitutiveModel(tc)
[g,m]=base2D();m.model="kelvin_voigt";
verifyError(tc,@() swsynth.medium.buildMaps(g,m), ...
    "swsynth:UnsupportedMediumModel");
end

function testRejectUnsupportedMediumProperty(tc)
[g,m]=base2D();m.viscosity_pa_s=1;
verifyError(tc,@() swsynth.medium.buildMaps(g,m), ...
    "swsynth:UnsupportedMediumProperty");
end

function testMapsFeedAnalyticalPhaseWithoutFrequencyInMedium(tc)
[g,m]=base2D();m.cs_m_s=2.5;
maps=swsynth.medium.buildMaps(g,m);
phase=swsynth.phase.compute(struct( ...
    "model","plane_wave","method","analytical", ...
    "geometry","2d","direction_xyz",[1 0 0], ...
    "reference_cs_m_s",2.5, ...
    "x_m",g.x_m,"z_m",g.z_m, ...
    "cs_map_zx",maps.cs_map_zx));
[X,~]=meshgrid(g.x_m,g.z_m);
verifyEqual(tc,phase.travel_time_s,X/2.5,"AbsTol",1e-14);
end

function testRejectInvalidShearSpeed(tc)
[g,m]=base2D();m.cs_m_s=-2;
verifyError(tc,@() swsynth.medium.buildMaps(g,m), ...
    "swsynth:InvalidMediumSpeed");
end

function testRejectCustomMaskSize(tc)
[g,m]=base2D();
m.objects={struct("type","custom","cs_m_s",3,"mask_zx",true(2,2))};
verifyError(tc,@() swsynth.medium.buildMaps(g,m), ...
    "swsynth:CustomMaskSizeMismatch");
end

function testReject3DNonOverlayCombineMode(tc)
[g,m]=base3D();m.combine_mode="blend";
verifyError(tc,@() swsynth.medium.buildMaps(g,m), ...
    "swsynth:InvalidMediumCombineMode");
end

function [grid,medium]=base2D()
grid=swsynth.domain.buildGrid(struct("geometry","2d", ...
    "Lx_m",.03,"Lz_m",.02,"dx_m",.001,"dz_m",.001));
medium=struct("cs_m_s",2);
end

function [grid,medium]=base3D()
grid=swsynth.domain.buildGrid(struct("geometry","volumetric3d", ...
    "Lx_m",.005,"Ly_m",.003,"Lz_m",.004, ...
    "dx_m",.001,"dy_m",.001,"dz_m",.001));
medium=struct("cs_m_s",2);
end
