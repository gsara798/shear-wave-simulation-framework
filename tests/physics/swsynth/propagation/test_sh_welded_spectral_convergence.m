function tests=test_sh_welded_spectral_convergence
% Diagnostic only: spectral-step/truncation, exact matched-medium Green
% reference and welded displacement/traction continuity.
tests=functiontests(localfunctions);
end

function testSpectralSamplingAndBoundary(tc)
addSourcePath();
p=setupRequest();
% Small receiver grid: isolate angular quadrature from image resolution.
% Keep spectral cutoff approximately fixed while halving dk.
steps=[4 2 1];
fields=cell(numel(steps),1);
for i=1:numel(steps)
    p.spectral_step_rad_m=steps(i);
    p.spectral_count=round(7000/steps(i));
    fields{i}=swsynth.propagation.interface.lineSHWeldedInterface(p);
end
for i=1:2
    A=fields{i};B=fields{i+1};
    eR=norm(A.reflected_uy_zx(:)-B.reflected_uy_zx(:))/ ...
        max(norm(B.reflected_uy_zx(:)),eps);
    eT=norm(A.transmitted_uy_zx(:)-B.transmitted_uy_zx(:))/ ...
        max(norm(B.transmitted_uy_zx(:)),eps);
    fprintf("dk %.3g -> %.3g: reflected relL2 %.6g transmitted relL2 %.6g\n", ...
        steps(i),steps(i+1),eR,eT);
    verifyTrue(tc,all(isfinite([eR eT])));
end
% Across-interface finite difference using points at -h,0,+h.
% Compare extrapolated left displacement and right boundary displacement.
h=2e-5;
p.x_m=[-2*h,-h,0,h,2*h];
p.spectral_step_rad_m=1;
p.spectral_count=7000;
A=swsynth.propagation.interface.lineSHWeldedInterface(p);
uL=2*A.total_uy_zx(:,2)-A.total_uy_zx(:,1);
uR=A.total_uy_zx(:,3);
displacementError=norm(uL-uR)/max(norm(uR),eps);
mu1=p.rho1_kg_m3*p.cs1_m_s^2;
mu2=p.rho2_kg_m3*p.cs2_m_s^2;
dL=(3*A.total_uy_zx(:,2)-4*A.total_uy_zx(:,1)+ ...
    A.total_uy_zx(:,1)); %#ok<NASGU>
% Second-order left derivative at x=0 from left values requires x=0.
% Obtain the left limit by extrapolating derivative samples from x<0.
dLeft=(A.total_uy_zx(:,2)-A.total_uy_zx(:,1))/h;
dRight=(-3*A.total_uy_zx(:,3)+4*A.total_uy_zx(:,4)- ...
    A.total_uy_zx(:,5))/(2*h);
tractionError=norm(mu1*dLeft-mu2*dRight)/ ...
    max(norm(mu2*dRight),eps);
fprintf("near-boundary displacement relL2 %.6g, traction relL2 %.6g (h=%.3g m)\n", ...
    displacementError,tractionError,h);
verifyTrue(tc,all(isfinite([displacementError tractionError])));
% Diagnostic only. Once converged establish physically useful tolerances.
end

function testTruncationAndMatchedMedium(tc)
addSourcePath();
p=setupRequest();
p.cs2_m_s=p.cs1_m_s;
p.rho2_kg_m3=p.rho1_kg_m3;
p.spectral_step_rad_m=1;
for cutoff=[3000 6000 9000]
    p.spectral_count=cutoff;
    a=swsynth.propagation.interface.lineSHWeldedInterface(p);
    right=p.x_m>=0;
    e=norm(a.transmitted_uy_zx(:,right)-a.incident_uy_zx(:,right),"fro")/ ...
        norm(a.incident_uy_zx(:,right),"fro");
    fprintf("matched-medium cutoff=%g rad/m: transmission vs Hankel relL2 %.6g\n",cutoff,e);
    verifyTrue(tc,isfinite(e));
end
end

function p=setupRequest()
p=struct("x_m",[-.025 -.015 -.005 .001 .005 .015 .025], ...
    "z_m",(-.02:.004:.02).', ...
    "source_xz_m",[-.035 .00013],"interface_x_m",0, ...
    "frequency_hz",300,"cs1_m_s",2,"cs2_m_s",3, ...
    "rho1_kg_m3",1000,"rho2_kg_m3",1000, ...
    "interface_enabled",true);
end

function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
