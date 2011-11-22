
function [param, data] = multipleRegionCrop(paramIn, dataIn)

global param
param = paramIn;
global data
data  = dataIn;

%Manually outline regions that should be cropped.
multipleRegionCropGUI();

%Find the cropped regions that this corresponds to.
%param = calcCropRegion(param);

 
% calcCroppedRegion(param);
 
end

%GUI to manipulate cropped regions.
function [] = multipleRegionCropGUI()

global param
global data
%%%%%%%%%%%%%%
% GUI Elements
%%%%%%%%%%%%%%

%%Variables that we'll use in this GUI

%%%%%% z stack depth
zMin = 1;

%Put this back in in a second.
zMax = length([param.regionExtent.Z]);
zNum = zMin;
zLast = zNum; %The last z level we went to.


zStepSmall = 1.0/(zMax-zMin);
zStepBig = 15.0/(zMax-zMin);

%%%%%% number of scans
numScans = param.expData.totalNumberScans;
numScans = uint16(numScans);
minScan = uint16(1);
maxScan = uint16(numScans);
scanNum = 1;

%%%%%% number of colors
numColor = length([param.color]);
minColor = 1;
maxColor = numColor;
colorType = [param.color];
colorNum = 1;

%%%number of regions
totalNumRegions = length(unique([param.expData.Scan.region]));


%%%%api handle
hApi = '';

%%%%%handle to polygon
hPoly = '';

%Color map for bounding rectangles and cropping rectangles
cMap = rand(totalNumRegions,3);

%%%%%%%%%%%%%%%%
% The GUI window
fGui = figure('Name', 'Play the Outline the Gut Game!', 'Menubar', 'none', 'Tag', 'fGui',...
    'Visible', 'off', 'Position', [50, 50, 2000, 900], 'Color', [0.925, 0.914, 0.847]);

%%%%%%%%%%%%%%%%%%%%%%%%
% AXES to DISPLAY IMAGES



%%%%%%%%%%Create the menu pull downs
hMenuCrop = uimenu('Label','Crop Images');

uimenu(hMenuCrop,'Label','Create cropping boxes','Callback',@createCropBox_Callback);
uimenu(hMenuCrop, 'Label', 'Crop the images', 'Callback', @cropImages_Callback);
uimenu(hMenuCrop, 'Label', 'Restore original image', 'Callback', @restoreImages_Callback);


hMenuOutline = uimenu('Label', 'Outline region');
uimenu(hMenuOutline,'Label','Freehand polygon outline','Callback',@createFreeHandPoly_Callback);
uimenu(hMenuOutline, 'Label', 'Apply initial guess', 'Callback', @createGuessPoly_Callback);
uimenu(hMenuOutline,'Label','Create cropping boxes','Callback',@savePoly_Callback);
uimenu(hMenuOutline,'Label','Clear outline ','Callback',@clearPoly_Callback);


%%%%%%Create the displayed control panels
imageRegion = axes('Tag', 'imageRegion', 'Position', [0.01, .18, .98, .8], 'Visible', 'on',...
    'XTick', [], 'YTick', [], 'DrawMode', 'fast');


hManipPanel = uipanel('Parent', fGui, 'Units', 'Normalized', 'Position',[ 0.05 0.02 0.3 0.2],...
    'Title', 'Change Registered Image');
  

dist = 0.3; %Spacing between slider bars
hZText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.05 0.8 0.1 0.15],...
    'Style', 'text', 'String', 'Z Depth');
hZTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.17 0.8 0.1 0.15],...
    'Style', 'edit', 'Tag', 'zedit', 'String', zMin, 'Callback', @z_Callback);
hZSlider = uicontrol('Parent', hManipPanel,'Units', 'Normalized', 'Position', [0.3 0.86 0.65 0.1],...
    'Style', 'slider', 'Min', zMin, 'Max', zMax, 'SliderStep', [zStepSmall zStepBig], 'Value', 1, 'Tag', 'zslider',...
    'Callback', @z_Callback);

hScanText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.05 0.8-dist 0.1 0.15],...
    'Style', 'text', 'String', 'Scan Number');
hScanTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.17 0.8-dist 0.1 0.15],...
    'Style', 'text', 'String', minScan);
%Only render slider bar if there are more than one scan in this set.
if(numScans>1)
hScanSlider = uicontrol('Parent', hManipPanel,'Units', 'Normalized', 'Position', [0.3 0.86-dist 0.65 0.1],...
    'Style', 'slider', 'Min', minScan, 'Max',maxScan, 'SliderStep', [1 1], 'Value', 1,...
    'Callback', @scanSlider_Callback);
end

hColorText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.05 0.8-2*dist 0.1 0.15],...
    'Style', 'text', 'String', 'Color');
hColorTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.17 0.8-2*dist 0.1 0.15],...
    'Style', 'text', 'String',colorType{1});
hColorSlider = uicontrol('Parent', hManipPanel,'Units', 'Normalized', 'Position', [0.3 0.86-2*dist 0.65 0.1],...
    'Style', 'slider', 'Min', minColor, 'Max', maxColor, 'SliderStep', [1 1], 'Value', 1,...
    'Callback', @colorSlider_Callback);



%Create a data table where the user can give the upper and upper bound (in
%terms of the z level) for different regions.
 cnames = {'Bottom', 'Top'};
 rnames = cell(totalNumRegions,1);
 for i=1:totalNumRegions
    rnames{i} = i;
end

dataTable = param.regionExtent.crop.z;

hRegTable = uitable('Parent', fGui,...
'Data', dataTable, 'ColumnName', cnames,...
   'RowName', rnames, 'Units', 'Normalized', 'Position', [ 0.36 0.02 0.1 0.19],...
   'ColumnEditable', true);
set(hRegTable, 'CellEditCallback', @table_Callback);
%%%%%%%%%%%
% GUI Setup
%%%%%%%%%%%

% Display GUI
set([fGui,  hZSlider, imageRegion],...
    'Units', 'normalized');

movegui(fGui, 'center');
set(fGui, 'Visible', 'on');

%Show the bottom image in the stack
im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));
color = colorType(colorNum);
color = color{1};
im = registerSingleImage(scanNum,color, zNum,im, data,param);

hIm = imshow(im, [],'Parent', imageRegion);
hContrast = imcontrast(imageRegion);

outlineRegions(); %Outline the different regions that make up the composite region.


%%%%%%%%%%%%%%%%%%%%%% Callback Functions


%%%%% Drop down menu callback

    function outlineRegions(hObject, eventdata)
        
        %%% Draw rectangles on the image, showing the boundary of the different
        %%% regions that we're analyzing.
        
        for numReg = 1:totalNumRegions
            x = param.regionExtent.XY(numReg, 2);
            y = param.regionExtent.XY(numReg, 1);
            width = param.regionExtent.XY(numReg, 4);
            height = param.regionExtent.XY(numReg,3);
            h = rectangle('Position', [x y width height] );
            set(h, 'EdgeColor', cMap(numReg,:));
            set(h, 'LineWidth', 2);
            
            pause(0.25)
        end
    end

    function createCropBox_Callback(hObject, eventdata)
        
        %Create a number of rectangles equal to the number of regions in the
        %registered image. These will be resizable and will allow the user a way to
        %outline the regions that should be kept.
        
        %Get the initial handles to rectangle images (in case some other windows
        %were open.
        hRectLast = findobj('Tag', 'imrect');
        
        for numReg = 1:totalNumRegions
            h = imrect(imageRegion);
            
            %Set the color of the rectangle. Need to do this using the api
            %interface. Color will be set to the same color as the region that this
            %cropping rectangle is associated with.
            hApi = iptgetapi(h);
            hApi.setColor(cMap(numReg,:));
            
            hThisRect = findobj('Tag', 'imrect');
            
            hRect(numReg) = setdiff(hThisRect, hRectLast);
            hRectLast = hThisRect; %Update handles to other rectangles.
            
            
        end
        %After these rectangles have been placed down, find the handles to these
        %rectangles.
        %Get the application programmer interface (whatever that means) for this
        %handle (allows us to get position measurements more easily)
        
        for numReg=1:totalNumRegions
            apiTemp(numReg) = iptgetapi(hRect(numReg));
            %For each of these api's add a callback function that updates a stored
            %array of all the positions
        end
        hApi = apiTemp;
        
    end

    function cropImages_Callback(hObject, eventdata)

        
        %Updating the position of the cropping rectangles
        cropRegion = zeros(totalNumRegions,4);
        for numReg=1:totalNumRegions
           
            cropRegion(numReg, :) = hApi(numReg).getPosition();
        end
        cropRegion = round(cropRegion);
        
        param.regionExtent.crop.XY = cropRegion;
        
        %Cropping the image in the xy plane
        [data,param] = registerImagesXYData('crop', data,param);
        
        %Cropping the image stack in the z direction.
        [data,param] = registerImagesZData('crop', data,param);
        
        
        
        %Remove the cropping rectangles.
        hRect = findobj('Tag', 'imrect');
        delete(hRect);
        im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));
        color = colorType(colorNum);
        color = color{1};
        im = registerSingleImage(scanNum,color, zNum,im, data,param);
        
        hIm = imshow(im, [],'Parent', imageRegion);
        outlineRegions();
        
    end

    function restoreImages_Callback(hObject, eventdata)
        
        %Remove the cropping rectangles.
        hRect = findobj('Tag', 'imrect');
        delete(hRect);
        
        %Cropping the image
        [data,param] = registerImagesXYData('original', data,param);
        
        im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));
        color = colorType(colorNum);
        color = color{1};
        im = registerSingleImage(scanNum,color, zNum,im, data,param);
        
        hIm = imshow(im, [],'Parent', imageRegion);
        outlineRegions();
    end




    function table_Callback(hObject,eventData)
       tableData = get(hRegTable, 'Data');
       param.regionExtent.crop.z = tableData;
    end

    function colorSlider_Callback(hObject, eventData)
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        %Update the displayed color level.
        set(hColorTextEdit, 'String', colorType(colorNum));
          
        %Display the new image
        color = colorType(colorNum);
        color = color{1};
        im = registerSingleImage(scanNum,color, zNum,im, data,param);

        set(hIm, 'CData', im);
        
    %    hContrast = imcontrast(hIm);
    end

    function scanSlider_Callback(hObject, eventData)
        scanNum = get(hColorSlider, 'Value');
        scanNum = ceil(scanNum);
        scanNum = int16(scanNum);
        
        %Update the displayed scan number.
        set(hScanTextEdit, 'String', scanNum);
        
        %Display the new image
        color = colorType(colorNum);
        color = color{1};
        im = registerSingleImage(scanNum,color, zNum,im, data,param);
        set(hIm, 'CData', im);
    end
    function z_Callback(hObject, eventData)
        
        zTag = get(hObject, 'tag');
        
        switch zTag
            case 'zslider'
                zNum = get(hZSlider, 'Value');
                zNum = ceil(zNum);
                zNum = int16(zNum);
                
                %Update the displayed z level.
                set(hZTextEdit, 'String', zNum);
            case 'zedit'
                zNum = get(hZTextEdit, 'string');
                zNum = num2str(zNum);
                zNum = ceil(zNum);
                zNum = int16(zNum);
                zNum = set(hZSlider, 'Value');
        end
        
        color = colorType(colorNum);
        color = color{1};
        im = registerSingleImage(scanNum,color, zNum,im, data,param);
        set(hIm, 'CData', im);
                
        %Update the previous examined Z slice
        zLast = zNum;
    end


%Callbacks for the polygon outlining of the gut

    function createFreeHandPoly_Callback(hObject, eventdata)
        %Start drawing the boundaries!
        hPoly = impoly(imageRegion);   
        
    end


    function createGuessPoly_Callback(hObject, eventdata)
        
    end


    function savePoly_Callback(hObject, eventdata)
        
    end


    function clearPoly_Callback(hObject, eventdata)
       delete(hPoly); %Delete the displayed polygon. 
    end
        
       
end



function param = calcCroppedRegion(param)

%Make a mask the size of the total registered image

im = zeros(param.regionExtent.regImSize);
imCropRect = im;

totalNumRegions = length(unique([param.expData.Scan.region]));

sizeOverlap = zeros(totalNumRegions);

for regNum =1:totalNumRegions
        im(:) = 0;
        imCropRect(:) = 0;
        
        %Get the range of pixels that we will read from and read out to.
        xOutI = param.regionExtent.XY(regNum,1);
        xOutF = param.regionExtent.XY(regNum,3);
        
        yOutI = param.regionExtent.XY(regNum,2);
        yOutF = param.regionExtent.XY(regNum,4);
        
        im(xOutI:xOutF, yOutI:yOutF) = 1;
        
        cropXY = param.regionExtent.crop.XY;
        
        cropXY = round(cropXY); %Won't be necessary in a bit-will be written into GUI.
        for cropNum=1:totalNumRegions
           xOutI = cropXY(cropNum,1);
           xOutF = xOutI + cropXY(cropNum,3);
           yOutI = cropXY(cropNum,2);
           yOutF = yOutI + cropXY(cropNum,4);
           
           imCropRect(xOutI:xOutF, yOutI:yOutF) = 1;
           
           imshow(imCropRect);
           
        end
        
        %Find the size of the overlap between these two regions. We will
        %use the cropping rectangle that has the largest overlap between
        %the region image and the cropping rectangle to crop that region. 
        %Somewhat convoluted, but it makes it unnecessary for the user to
        %keep track of some number on each rectangle.
        imOverlap = imCropRect.*im;
        sizeOverlap(cropNum,RegNum) = sum(imOverlap);
        
end

%[cropIndex, temp]  = find(sizeOverlap


end