%Goes through the entire scan and calculates the overlaped regions and
%allows the user to draw a bounding polygon around each region.




function [data,param]= registerImagesScan(data,param)
im = registerSingleImage(nScan, colorType, zNum, data, param);



%However we get the number of cells from our data
param.boundPoly = cell(numScans, 1);

figure; imshow(im,[]);



end