%Crops the images stored into data to the region selected by the user.
%Currently the program selects the first image in the scan, but future
%versions should make this more dynamic, and allow the user to double check
%the cropping before proceeding.
%
%USAGE: [data,param] = cropStack(data,param)
%       -The user is is shown the first region in the stack and is prompted
%       to highlight the region to crop the images to.
%       -data-now contains cropped images instead of the original larger
%       images.
%       -param contains param.cropRegion, which gives the rectangle used to
%       crop the images
%       [data, param] = cropStack(data,param,rect).
%       -crops all the images in data to the size given by rect.
%CREATED: Matthew Jemielita, Nov 8, 2011
function [data,param] = cropStack(varargin)

if(nargin ==3)
    data = varargin{1};
    param = varargin{2};
    rect = varargin{3};
    
elseif(nargin==2)
    data = varargin{1};
    param = varargin{2};
    im = data.scan(1).region(1).color(1).im;
    hCrop = figure; imshow(im,[]);
    title 'Please select a cropping region'
    
    [imc, rect] = imcrop();
    param.cropRegion = rect;
    
    close(hCrop);
else
    disp('This function must be passed two or three arguments! See help menu for usage.')
    return
end


for nScan=1:length(data.scan)
    %Going through each scan
    for nRegion=1:length(data.scan(nScan).region)
        %Going through each region in this scan
        for nColor=1:length(data.scan(nScan).region(nRegion).color)
            %and each color

            %Cropping each of these images
            im = data.scan(nScan).region(nRegion).color(nColor).im;
            
            imc = imcrop(im, rect);
            data.scan(nScan).region(nRegion).color(nColor).im = imc;
            
        end
    end
end


end