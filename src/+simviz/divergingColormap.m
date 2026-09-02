function map = divergingColormap(n)
%DIVERGINGCOLORMAP Blue-white-red map from the shared paper theme.
arguments
    n (1,1) double {mustBeInteger,mustBePositive} = 256
end
theme = simviz.paperTheme();
blue = theme.rgb.blue.main;
red = theme.rgb.red.main;
white = [1 1 1];
leftCount = ceil(n/2);
rightCount = n-leftCount+1;
left = interpolate(blue,white,leftCount);
right = interpolate(white,red,rightCount);
map = [left; right(2:end,:)];
end

function values = interpolate(a,b,n)
t = linspace(0,1,n)';
values = (1-t).*a + t.*b;
end
