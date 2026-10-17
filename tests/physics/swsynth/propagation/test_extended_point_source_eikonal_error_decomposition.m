function tests=test_extended_point_source_eikonal_error_decomposition
% Decompose 3D Eikonal numerical error from slice interpolation error.
tests=functiontests(localfunctions);
end

function testVolumeVsObservationPlane(tc)
addpath(fullfile(repoRoot(),"src"));
x=0:.002:.012; z=(0:.002:.012).';
cs=2; speed=cs*ones(numel(z),numel(x));
loss=zeros(size(speed));
sources=[-.004 0 .006;-.004 .006 .006];
hs=[.003 .002 .0015];
for is=1:size(sources,1)
    source=sources(is,:);
    fprintf("\nsource %s\n",mat2str(source));
    for ih=1:numel(hs)
        opt=struct("GridSpacingM",hs(ih),"MaxGridCells",200000, ...
            "MaximumIterations",200,"ToleranceS",1e-9, ...
            "ReturnVolumeDiagnostics",true);
        [Tobs,~,D]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
            speed,loss,x,z,source,0,opt);
        v=D.volume;
        [Z3,Y3,X3]=ndgrid(v.z_m,v.y_m,v.x_m);
        texact3=sqrt((X3-source(1)).^2+(Y3-source(2)).^2+ ...
            (Z3-source(3)).^2)/cs;
        % Check all 3D nodes, excluding the near-source numerical core as
        % a separate measurement.
        r3=cs*texact3;
        hActual=max([mean(diff(v.x_m)),mean(diff(v.y_m)),mean(diff(v.z_m))]);
        far=r3>3*hActual;
        E3=relativeError(v.travel_time_zyx(far),texact3(far));
        E3all=relativeError(v.travel_time_zyx,texact3);
        [Z,X]=ndgrid(z,x);
        Tref=sqrt((X-source(1)).^2+source(2)^2+(Z-source(3)).^2)/cs;
        Eobs=relativeError(Tobs,Tref);
        TinterpExact=interpn(v.z_m,v.y_m,v.x_m,texact3, ...
            Z,zeros(size(Z)),X,"linear");
        % Isolate interpolation error with the exact field sampled on the
        % identical volume mesh; this is not equal to Eobs-E3.
        Einterpolation=relativeError(TinterpExact,Tref);
        EnumericalSlice=relativeError(Tobs,TinterpExact);
        fprintf("h=%.4g; E3_all=%.6g; E3_far=%.6g; E_slice_numeric=%.6g; E_slice_interp=%.6g; E_obs=%.6g\n", ...
            hs(ih),E3all,E3,EnumericalSlice,Einterpolation,Eobs);
        verifyTrue(tc,all(isfinite([E3all E3 EnumericalSlice Einterpolation Eobs])));
        verifyLessThan(tc,abs(Eobs-relativeError(Tobs,Tref)),1e-13);
    end
end
end

function e=relativeError(actual,reference)
a=double(actual(:));b=double(reference(:));
e=norm(a-b)/norm(b);
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
end
