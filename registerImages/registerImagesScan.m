%Goes through the entire scan and calculates the overlaped regions and
%allows the user to draw a bounding polygon around each region.




function [data,param]= registerImagesScan(data,param)

%Construct the image arrays that we'll use to overlap the regions.
[im, imOr] = constructCompIm(data,param);

%Construct the image arrays that we'll use to overlay the results from the
%two colors.

imColor = zeros(size(im,1), size(im,2),3);


%Going through each scan
for nScan = param.scans(1):param.scans(end)
    %And each z level
    for zNum=1:size([param.registerImZ])
        %And each color
        for nColor =1:length(param.color)
            colorType = param.color(nColor);
            colorType =colorType{1};%Removing it from the cell.
            
            imColor(:,:,nColor)= registerSingleImage(nScan, colorType, zNum, im, imOr, data, param);
        
        end
        
      %  [poly] = display2Color(imColor, 'draw');
        imColor = mat2gray(imColor);
        imColor(:,:,1) = imadjust(imColor(:,:,1));
        imColor(:,:,2) = imadjust(imColor(:,:,2));
        imColor(:,:,3) = imadjust(imColor(:,:,3));
        
        %However we get the number of cells from our data
       % param.boundPoly = cell(nScans, 1);
%        imColor = imadjust(imColor);
         imshow(imColor,[]);
        drawnow;
        pause
        
    end
    
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