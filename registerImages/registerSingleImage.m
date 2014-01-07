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
%       im = registerSingleImage(imAll, color,param)
%       Register preloaded images from different regions into one large
%       image
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
    case 3
        %Images have already been loaded-they just need to be stitched
        %together now.
        imAll = varargin{1};    
        colorType = varargin{2};
        param = varargin{3};
        colorNum =  find(strcmp(param.color, colorType));

        im = zeros(param.regionExtent.regImSize{colorNum}(1),...
            param.regionExtent.regImSize{colorNum}(2));
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

if(isfield(param.expData.Scan, 'isScan'))
    totalNumRegions = unique([param.expData.Scan.region].*[strcmp('true', {param.expData.Scan.isScan})]);
else
    totalNumRegions = unique([param.expData.Scan.region]);
end
totalNumRegions(totalNumRegions==0) = [];

totalNumRegions = length(totalNumRegions);
%Filling the input image with zeros, to be safe.
im(:) = 0;

im = uint16(im); %To match the input type of the images.

%Find which color's regionExtent.XY to use
colorNum =  find(strcmp(param.color, colorType));



if(nargin==3)
    im = registerImages(imAll,im);
else
    im = loadRegisteredImages(im,nScan,colorType,param);
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



    function im = loadRegisteredImages(im,nScan,colorType, param)
        
        %%Now loading in the images
        %Base directory for image location
        baseDir = [param.directoryName filesep 'Scans' filesep];
        %Going through each scan
        scanDir = [baseDir, 'scan_', num2str(nScan), filesep];
        %And each color (in the debugging phase, we'll restrict ourselves
        %to one color
        
        imNum = param.regionExtent.Z(zNum,:);
        %Load in the associated images
        
        for regNum=1:totalNumRegions
            
            height = param.regionExtent.XY{colorNum}(regNum,3);
            width = param.regionExtent.XY{colorNum}(regNum,4);
            
            %Get the range of pixels that we will read from and read out to.
            xOutI = param.regionExtent.XY{colorNum}(regNum,1);
            xOutF = xOutI+height-1;
            
            yOutI = param.regionExtent.XY{colorNum}(regNum,2);
            yOutF = yOutI+width -1;
            
            xInI = param.regionExtent.XY{colorNum}(regNum,5);
            xInF = xInI +height-1;
            
            yInI = param.regionExtent.XY{colorNum}(regNum,6);
            yInF = yInI +width-1;
            
            if(imNum(regNum)~=-1)
                
                %To deal with two different ways of loading in our data-necessary
                %in order to interface somewha efficiently with Hyugens software.
                if(isfield(param, 'directoryStructType'))
                    loadType = param.directoryStructType;
                else
                    loadType  = 'fullDirectory';
                end
                
                switch loadType
                    
                    case 'fullDirectory'
                        imFileNameTiff = ...
                            strcat(scanDir,  'region_', num2str(regNum),filesep,...
                            colorType, filesep,'pco', num2str(imNum(regNum)),'.tif');
                        
                        imFileNamePng = ...
                            strcat(scanDir,  'region_', num2str(regNum),filesep,...
                            colorType, filesep,'pco', num2str(imNum(regNum)),'.png');
                        
                        typeList = [exist(imFileNameTiff, 'file') exist(imFileNamePng, 'file')];
                        %See if we have a png or tiff type of file. If we
                        %have both return an error-we should only have one
                        %of these in the directory
                        whichType = find(typeList==2, 2);
                        if(length(whichType)==2)
                           fprintf(2, 'Directory can only contain png or tiff versions of the images!\n');
                           return
                        end
                        
                        switch whichType
                            case 1
                                %Images saved as tiff files
                                im(xOutI:xOutF,yOutI:yOutF) = imread(imFileNameTiff,...
                                    'PixelRegion', {[xInI xInF], [yInI yInF]}) + ...
                                    im(xOutI:xOutF,yOutI:yOutF);
                            case 2                     
                                %Images saved as png files-note the png
                                %format doesn't support loading in
                                %particular pixel regions directly (a
                                %consequence of how the image is
                                %compressed).
                                inputImage = imread(imFileNamePng);
                                im(xOutI:xOutF,yOutI:yOutF) = inputImage(xInI:xInF, yInI:yInF) + ...
                                    im(xOutI:xOutF,yOutI:yOutF);
                        end
                                
                        
                    case 'flatDirectory'
                        %flat directory only supports tiffs-I don't think
                        %png has support for multipage storage
                        imFileName = [param.directoryName '_S', num2str(nScan),'nR', num2str(regNum),'_', colorType, '.tif'];
                        
                        im(xOutI:xOutF, yOutI:yOutF) = imread(imFileName,...
                            'PixelRegion', {[xInI xInF], [yInI yInF]},...
                            'Index', imNum(regNum)+1) + ...
                            im(xOutI:xOutF,yOutI:yOutF);
                end
                
            end
            
        end
        
        %Dealing with overlap regions        
        for regNum = 2:totalNumRegions
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

    end

    function im = registerImages(imAll,im)
                
        for regNum=1:totalNumRegions
            
            height = param.regionExtent.XY{colorNum}(regNum,3);
            width = param.regionExtent.XY{colorNum}(regNum,4);
            
            %Get the range of pixels that we will read from and read out to.
            xOutI = param.regionExtent.XY{colorNum}(regNum,1);
            xOutF = xOutI+height-1;
            
            yOutI = param.regionExtent.XY{colorNum}(regNum,2);
            yOutF = yOutI+width -1;
            
            xInI = param.regionExtent.XY{colorNum}(regNum,5);
            xInF = xInI +height-1;
            
            yInI = param.regionExtent.XY{colorNum}(regNum,6);
            yInF = yInI +width-1;
            
            im(xOutI:xOutF, yOutI:yOutF) = imAll{colorNum,regNum}+...
                im(xOutI:xOutF, yOutI:yOutF);
            
        end
        
        for regNum = 2:totalNumRegions
            %Overlapping regions
            %This is potentially slow (however we need to be as quick as possible with this type of thing).
            %After we know this code works, we'll come back and write quicker code.
            
            %Overlap for regNum>1
            im(param.regionExtent.overlapIndex{colorNum,regNum-1} )= ...
                0.5*im(param.regionExtent.overlapIndex{colorNum,regNum-1});
            
            
        end
        
        
        
    end
end