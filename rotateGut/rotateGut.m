% rotateGut: rotate an entire z-stack of gut images and return an array
% that contains all pixels that are contained within the gut
%
% USAGE: im = rotateGut(param)
%        [im, angle] = rotateGut(param)
% INPUT: param: parameter file associated with a particular fish
%        This function requires one values in param to be set that isn't 
%        automatically found:
%           1) param.regionExtent.poly-which gives the outline of the gut
% OUTPUT: im: large 3d image stack containing only pixels found within the

%
% AUTHOR: Matthew Jemielita, July 27, 2012

function im = rotateGut(param)

%Get mask of gut
height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);
polyX = param.regionExtent.poly(:,1);
polyY = param.regionExtent.poly(:,2);
mask = poly2mask(polyX, polyY, height, width);

%Get angle
angle = rotateGutAngle(mask);

%Go through and make one large image stack

color = param.color{1};
minZ = 1;
maxZ = size(param.regionExtent.Z,1);
numZ = maxZ-minZ+1;

imOrig = zeros(param.regionExtent.regImSize{1}(1), param.regionExtent.regImSize{1}(2));

imOrig = registerSingleImage(1,color, minZ, imOrig, '',param);


imRot = rotateGutSingleImage(imOrig, mask, angle);

im = zeros(1865,9264, numZ, 'uint16');














end