%registerSingleImage: For a given scan number and color, combine all 
%the different regions together to produce one large registered image
%
%USAGE: im = registerSingleImage(nScan, color, zNum, im, filterType)
%       For a given scan number, color, height in the z stack use the
%       variables in param that gives the relative position of the
%       different regions to fill the variable im with the appropriate
%       registered images. Filter the images with the filter given by
%       filterType.
%
%       im = registerSingleImage(nScan, color, zNum, im, param)
%       Same as above, but with no image filtering.
%
%       im = registerSingleImage(nScan, color, zNum, param)
%       Same as previous but the variable im is now created within this
%       program (somewhat slower than the other two ways of calling this
%       function).
%
%       im = registerSingleImage(nScan, color, zNum, data, param).
%       Includes unused variable data. No longer necessary and code needs
%       to be picked through to remove this way of calling the function.
%
%INPUT: nScan: integer giving the scan number for the image. Should be
%       greater than 0 and not exceed the number of scans taken.
%       
%       color: string giving the wavelength for a given scan. Same as the
%       name of the subdirectory for each color. e.g. '488nm'
%       zNum: integer giving the height in the stack for the image
%       im: array of the same size as the output registered image. This
%       program resets all elements of im to 0, before adding any new
%       images.
%       filterType: string giving the type of filtering to be done on this
%       image. Will be expanded in the future.
%       param: contains all the relevant experimental parameters for this
%       fish
%       data: currently unused variable
%
%OUTPUT: im: image made up of all the registered images from different
%        regions.
% Author: Matthew Jemielita
function im = registerSingleImage(varargin)
%Get the appropriate variables
switch nargin
    
    case 0
        %Prompt the user for directories, etc...
    
    case 4
        nScan = varargin{1};
        colorType = varargin{2};
        zNum = varargin{3};
        param = varargin{4};
        
        colorNum =  find(strcmp(param.color, colorType));
        im = zeros(param.regionExtent.regImSize{colorNum}(1),...
            param.regionExtent.regImSize{colorNum}(2));
        
    case 5
        nScan = varargin{1};
        colorType = varargin{2};
        zNum = varargin{3};
        im = varargin{4};
        param = varargin{5};        
    %We should get rid of case 6-data is a useless variable
    case 6
        nScan = varargin{1};
        colorType = varargin{2};
        zNum = varargin{3};
        im = varargin{4};
        if ischar(varargin{5})
            filterType = varargin{5};
        else
            data = varargin{5}; %To deal with an unused data structure that should be culled.
        end
        param = varargin{6};
        
end

totalNumRegions = length(unique([param.expData.Scan.region]));
%%Now loading in the images
%Base directory for image location
baseDir = [param.directoryName filesep 'Scans' filesep];
%Going through each scan
scanDir = [baseDir, 'scan_', num2str(nScan), filesep];
%And each color (in the debugging phase, we'll restrict ourselves
%to one color

imNum = param.regionExtent.Z(zNum,:);
%Load in the associated images

%Filling the input image with zeros, to be safe.
im(:) = 0;

im = uint16(im); %To match the input type of the images.

%Find which color's regionExtent.XY to use
colorNum =  find(strcmp(param.color, colorType));
    
for regNum=1:totalNumRegions
    
    %Get the range of pixels that we will read from and read out to.
    xOutI = param.regionExtent.XY{colorNum}(regNum,1);
    xOutF = param.regionExtent.XY{colorNum}(regNum,3)+xOutI-1;
    
    yOutI = param.regionExtent.XY{colorNum}(regNum,2);
    yOutF = param.regionExtent.XY{colorNum}(regNum,4)+yOutI -1;
    
    xInI = param.regionExtent.XY{colorNum}(regNum,5);
    xInF = xOutF - xOutI +xInI;
    
    yInI = param.regionExtent.XY{colorNum}(regNum,6);
    yInF = yOutF - yOutI +yInI;
    
    if(imNum(regNum)~=-1)
        imFileName = ...
            strcat(scanDir,  'region_', num2str(regNum),filesep,...
            colorType, filesep,'pco', num2str(imNum(regNum)),'.tif');
        
        im(xOutI:xOutF,yOutI:yOutF) = imread(imFileName,...
            'PixelRegion', {[xInI xInF], [yInI yInF]}) + ...
            im(xOutI:xOutF,yOutI:yOutF);  
    end
    
end


for regNum = 2:totalNumRegions
    %Overlapping the regions
    %Overlapping regions
    %This is potentially slow (however we need to be as quick as possible with this type of thing).
    %After we know this code works, we'll come back and write quicker code.
    
    %Overlap for regNum>1
    if(imNum(regNum-1)>=0 &&imNum(regNum)>=0)
        im(param.regionExtent.overlapIndex{colorNum,regNum-1} )= ...
            0.5*im(param.regionExtent.overlapIndex{colorNum,regNum-1});
        %    im(:) =1;
        %   im(param.regionExtent.overlapIndex{regNum-1} ) = 0;
    end
    
end

if exist('filterType','var') && strcmp(filterType,'bpass')
    prompt = {'Pixel size of noise: ','Pixel size of object: '};
    dlg_title = 'Filter Options'; num_lines = 1;
    def = {'1','100'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    lnoise = str2double(answer(1));
    lobject = str2double(answer(2));
    im = bpassRegisteredSinglePlane(im,param,lnoise,lobject);

elseif exist('filterType','var') && strcmp(filterType,'bpass stack')
    
    %mlj: setting this in param instead-global variables can do some
    %fubar'd things.
    %global Glnoise Globject;
    %lnoise = Glnoise;
    %lobject = Globject;    
    lnoise = param.filter.bpass.lNoise;
    lobject = param.filter.bpass.lObject;
    im = bpassRegisteredSinglePlane(im,param,lnoise,lobject);
end


end