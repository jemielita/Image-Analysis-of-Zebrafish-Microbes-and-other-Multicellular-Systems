%Goes through the entire scan and calculates the overlaped regions and
%allows the user to draw a bounding polygon around each region.




function [data,param]= registerImagesScan(data,param)
nScan =1;
colorType = '488nm';

for i=1:80
    zNum = i;
im = registerSingleImage(nScan, colorType, zNum, data, param);
imshow(im,[]);
f(i) = getframe;
end
%However we get the number of cells from our data
param.boundPoly = cell(nScans, 1);

figure; imshow(im,[]);



end