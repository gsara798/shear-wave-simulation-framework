function tau = computeTravelTime(x,z,d,cs)
%COMPUTETRAVELTIME Homogeneous plane-wave travel time on a physical x-z plane.
if abs(d(2))>1e-10
    error("swsynth:InvalidPhaseRequest","2d plane wave must be in the x-z plane.");
end
[X,Z]=meshgrid(double(x),double(z));
tau=(d(1)*X+d(3)*Z)/cs;
end
