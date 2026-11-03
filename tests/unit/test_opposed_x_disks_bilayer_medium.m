function tests=test_opposed_x_disks_bilayer_medium
% No solver required; validate material orientation and homogeneous parity.
tests=functiontests(localfunctions);
end

function setupOnce(testCase)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
runnerDir=fullfile(root,"examples","kwave","3d","opposed_x_disks");
addpath(runnerDir);
testCase.TestData.runnerDir=runnerDir;
end

function testHomogeneousUnchanged(testCase)
C=jsondecode(fileread(fullfile(testCase.TestData.runnerDir,"config.json")));
N=[5 3 7];z=(-3:3)*0.0005;ix=2:4;iz=2:6;
[m,t,cp]=build_opposed_disk_material(C,N,z,ix,iz);
verifyEqual(testCase,size(m.sound_speed_shear),N);
verifyEqual(testCase,unique(m.sound_speed_shear),single(C.cs_m_s));
verifyEqual(testCase,unique(m.sound_speed_compression), ...
    single(C.cs_m_s*C.compressional_speed_factor));
verifyEqual(testCase,t.cs_m_s_zx,C.cs_m_s*ones(numel(iz),numel(ix)));
verifyEqual(testCase,cp,C.cs_m_s*C.compressional_speed_factor);
end

function testBilayerInterfaceAndTruth(testCase)
C=jsondecode(fileread(fullfile(testCase.TestData.runnerDir,"config.json")));
C.experiment="opposed_x_disks_bilayer_3d";
C.cs_m_s=1.8;
C.bilayer=struct("enabled",true,"interface_z_m",0, ...
    "negative_z_cs_m_s",1.8,"positive_z_cs_m_s",3.0);
N=[5 3 7];z=(-3:3)*0.0005;ix=2:4;iz=2:6;
[m,t,cp]=build_opposed_disk_material(C,N,z,ix,iz);
verifyEqual(testCase,reshape(m.sound_speed_shear(1,1,:),1,[]), ...
    single([1.8 1.8 1.8 3 3 3 3]));
verifyEqual(testCase,t.cs_m_s_zx(:,1),[1.8;1.8;3;3;3],"AbsTol",1e-12);
verifyEqual(testCase,t.material_id_zx(:,1),uint8([2;2;3;3;3]));
verifyEqual(testCase,cp,30,"AbsTol",1e-12);
verifyEqual(testCase,unique(m.density),single(1000));
end

function testRejectUnobservedInterface(testCase)
C=jsondecode(fileread(fullfile(testCase.TestData.runnerDir,"config.json")));
C.experiment="opposed_x_disks_bilayer_3d";
C.cs_m_s=1.8;
C.bilayer=struct("enabled",true,"interface_z_m",0.01, ...
    "negative_z_cs_m_s",1.8,"positive_z_cs_m_s",3.0);
verifyError(testCase,@()build_opposed_disk_material(C,[5 3 7], ...
    (-3:3)*0.0005,2:4,2:6),"OpposedDisks:BilayerOutsideROI");
end
