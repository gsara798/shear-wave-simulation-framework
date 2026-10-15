function tau = computeTravelTime(x,y,z,d,cs)
%COMPUTETRAVELTIME Homogeneous volumetric directional travel time.
[Z,Y,X]=ndgrid(double(z),double(y),double(x));
tau=(d(1)*X+d(2)*Y+d(3)*Z)/cs;
end
