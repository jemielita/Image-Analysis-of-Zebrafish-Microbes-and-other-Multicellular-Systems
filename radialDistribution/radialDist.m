%Calculates the radial distribution of intensity down the length of the
% %gut
 [xMesh,yMesh] = meshgrid(1:size(im,2), 1:size(im,1));
% 
% xInterp=  X+cosTheta;
% yInterp =  Y+sinTheta;
% interpGradPos = interp2(X,Y,gradImage,xInterp,yInterp);


%Find the index of points that lie within the gut-we'll use this as our
%clumsy mask to only look at pixel intensities within the gut

maskP = bwperim(mask);
[indexGutY, indexGutX]  = find(maskP==1);
indexGut = cat(2, indexGutX, indexGutY);

%For a given point along the gut, get the orthogonal vector, for a series of
%lines.

i = 10;
xx(i) =50;
yy(i) = 50;
x = 1;
y = 1;
xI = x+1;
yI = y+2;

%The length of these lines should be long enough to
%intersect the gut...doesn't seem to be the case right now.
Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];

xVal = xx(i)+ Orth(1)*[-500:1:500];
yVal = yy(i)+ Orth(2)*[-500:1:500];

%Get the indices corresponding to these points, after rounding
%     %first remove points on this line outside the range of the image
%     xMask = xVal;
%     yMask = yVal;
%     index = find(xMask > size(im,2) |xMask<=0);
%     xMask(index) = [];
%     yMask(index) = [];
%     index = find(yMask > size(im,1) |yMask<=0);
%     xMask(index) = [];
%     yMask(index) = [];
      
indexLine = cat(2, round(xMask)', round(yMask)');
xyInter = intersect(indexLine, indexGut, 'rows');

xMax = max(xyInter(:,1)); xMin = min(xyInter(:,1));
yMax = max(xyInter(:,2)); yMin = min(xyInter(:,2));

%Get rid of elements of xVal and yVal outside the range of the mask
index = find(xVal>xMax |xVal<xMin);
xVal(index) = [];
yVal(index) = [];

index = find(yVal>yMax |yVal<yMin);
xVal(index) = [];
yVal(index) =[];


%Find the interpolated pixel intensities along this line for a given image

zVal = interp2(xMesh, yMesh, im, xVal, yVal);







 