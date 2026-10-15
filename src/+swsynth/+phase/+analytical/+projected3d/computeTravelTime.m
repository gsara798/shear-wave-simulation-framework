function tau = computeTravelTime(x,z,d,cs)
%COMPUTETRAVELTIME Homogeneous 3D incident wave sampled on the y=0 x-z plane.
[X,Z]=meshgrid(double(x),double(z));
tau=(d(1)*X+d(3)*Z)/cs;
end
