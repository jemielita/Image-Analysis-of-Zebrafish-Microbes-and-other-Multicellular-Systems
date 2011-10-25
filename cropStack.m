%DESCRIPTION: Crops a set of scans.
%USAGE:
%
%cropStack(directory, cropExtent, rect, saveLocation, checkCrop)
%
%   directory: the directory where all the images to be cropped are
%   located.
%   cropExtent: Depth of cropping to be done.
%           '': Only one image will be cropped, with the filename given by
%           directory if the directory string end in '.tif', otherwise the
%           user will be prompted.
%           'scan': all images in a given scan will be cropped to the same
%           size.
%           'region': all images in the same region will be cropped.
%           'color': all images in the same color channel will be cropped.
%           'all': all images in the directory will be cropped to the same
%           size.
%   rect: Rectangle giving the extent of the region to be cropped. If
%   rect is set to 0, the user will be prompted to select a region.
%   
%   saveLocation: Directory where all the cropped images will be saved. The
%   directory structure used above will be replicated in the save location.
%
%   checkCrop: if 'yes' the user will be presented with images from the
%   scans with the cropped region highlighted to check the cropping. If the
%   user changes the rectangle the crop program will crop to that new size.
%
%cropStack(): same as above, but all parameters will be taken from the user


function [] = cropStack(varargin)

if(nargin==5)
    directory = varargin{1};
    cropExtent = varargin{2};
    rect = varargin{3};
    saveLocation = varargin{4};
    checkCrop = varargin{5};
    
elseif(nargin==0)
    
    
else
   %Quit the script gently. 
end

%Check to see if the directo

end