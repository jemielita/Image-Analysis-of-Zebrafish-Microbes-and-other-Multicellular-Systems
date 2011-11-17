%Goes through the entire scan and calculates the overlaped regions and
%allows the user to draw a bounding polygon around each region.




function [imAll,data,param]= registerImagesScan(data,param)

%Construct the image arrays that we'll use to overlap the regions.
[im, imOr] = constructCompIm(data,param);

%Construct the image arrays that we'll use to overlay the results from the
%two colors.

imTest = im;


imAll = zeros(size(im,1), size(im,2), size([param.registerImZ]));

%Data structure to save position
polyPosition = cell(length([param.registerImZ]),1);
position = '';

%Going through each scan
for nScan = param.scans(1):param.scans(end)
    
    
    %And each color
%   for nColor =1:length(param.color)
        
nColor = 1;
        %And each z level
        h = waitbar(0, 'Constructing registered stack...');
        
        for zNum=1:size([param.registerImZ])
        waitbar(zNum/length([param.registerImZ]),h);    
            
            colorType = param.color(nColor);
            colorType =colorType{1};%Removing it from the cell.
            
            imTest= registerSingleImage(nScan, colorType, zNum, im, imOr, data, param);
            
            %Displaying the result
            imAll(:,:,zNum) = imTest;

        end
        clear h;
        
 %   end
    
    
end

end


function [im, imOr] = constructCompIm(data,param)

%%Construct array to store composite image

%Get needed x and y range
imRange = zeros(2,2);
imRange(1,1) = min([param.expData.Scan.yBegin]);
imRange(1,2) = max([param.expData.Scan.yBegin]);

imRange(2,1) = min([param.expData.Scan.xBegin]);
imRange(2,2) = max([param.expData.Scan.xBegin]);
%convert to pixels;
imRange = (1.0/param.micronPerPixel)*0.1*imRange;
imRange(1,2) = imRange(1,2) + 2560; %Add to this the size of our camera sensor
imRange(2,2) = imRange(2,2)+2160;
%Round up
imRange = ceil(imRange);

%Now get the total range of pixels needed
imRange(:,2) = imRange(:,2)-imRange(:,1);
imRange(:,1) = 0;
%And creating the image structure.
im = zeros(imRange(2,2), imRange(1,2));
%Also create a structure for the images that will be used to make this
%composite image.
totalNumRegions = length(unique([param.expData.Scan.region]));
imOr = zeros(2160, 2560,totalNumRegions);

end