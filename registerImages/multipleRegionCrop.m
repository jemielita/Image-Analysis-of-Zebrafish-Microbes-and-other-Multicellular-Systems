
function [param,data] = multipleRegionCrop(varargin)
switch nargin
    case 0
        [data, param] = loadParameters();
    case 3
        %global param
        param = varargin{1};
        %global data
        data  = varargin{2};
end


multipleRegionCropGUI(param,data);

%Not the most elegant way to extract information from the GUI, but it seems
%to work.
%If the third argument has been set to 'save Results', pause MATLAB until
%the gui has been closed.
if(nargin==3)
    if(strcmpi(varargin{3}, 'save results'))
        while(~isempty(findobj('Tag', 'fGui')))
            handles = findobj('Tag', 'fGui');
            paramTemp = guidata(handles);
            param = paramTemp.param;
            pause(0.5);
        end
    end
end

end


function [] = multipleRegionCropGUI(param, data)

%%%%%%%%%%%%%%
% GUI Elements
%%%%%%%%%%%%%%

%%Variables that we'll use in this GUI.
%All of these are set in the function initializeDisplay()-the values below
%should be replaced with place holders.

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
outlineRect = '';

%%%%%%%%%%%%%%%%
% The GUI window
fGui = figure('Name', 'Play the Outline the Gut Game!', 'Menubar', 'none', 'Tag', 'fGui',...
    'Visible', 'off', 'Position', [50, 50, 2000, 900], 'Color', [0.925, 0.914, 0.847]);

%Handle to GUI data-will be used to pass information out
myhandles = guihandles(fGui);
myhandles.param = param;
myhandles.data = data;
guidata(fGui, myhandles);
%%%%%%%%%%%%%%%%%%%%%%%%
% AXES to DISPLAY IMAGES

%%%%%%%%%%Create the menu pull downs

hMenuFile = uimenu('Label', 'File');
uimenu(hMenuFile, 'Label', 'Load scan stack', 'Callback', @loadScan_Callback);
uimenu(hMenuFile, 'Label', 'Save single image', 'Callback', @saveImage_Callback);
uimenu(hMenuFile, 'Label', 'Save scan stack', 'Callback', @saveScan_Callback);

hMenuCrop = uimenu('Label','Crop Images');
uimenu(hMenuCrop,'Label','Create cropping boxes','Callback',@createCropBox_Callback);
uimenu(hMenuCrop, 'Label', 'Crop the images', 'Callback', @cropImages_Callback);
uimenu(hMenuCrop, 'Label', 'Restore original image', 'Callback', @restoreImages_Callback);

uimenu(hMenuCrop, 'Label', 'Crop and overwrite images', 'Callback', @saveCropped_Callback);

hMenuOutline = uimenu('Label', 'Outline region');
uimenu(hMenuOutline,'Label','Freehand polygon outline','Callback',@createFreeHandPoly_Callback);
uimenu(hMenuOutline, 'Label', 'Load Outline', 'Callback', @loadPoly_Callback);
uimenu(hMenuOutline,'Label','Save outline','Callback',@savePoly_Callback);
uimenu(hMenuOutline, 'Label', 'Smooth Polygon', 'Callback', @smoothPoly_Callback);
uimenu(hMenuOutline,'Label','Clear outline ','Callback',@clearPoly_Callback);

uimenu(hMenuOutline, 'Label', 'Draw center of gut', 'Separator', 'on', ...
    'Callback',@drawGutCenter_Callback);
uimenu(hMenuOutline, 'Label', 'Load center of gut', 'Callback', @loadGutCenter_Callback);
uimenu(hMenuOutline, 'Label', 'Smooth line', 'Callback', @smoothGutCenter_Callback);
uimenu(hMenuOutline, 'Label', 'Save line', 'Callback', @saveGutCenter_Callback);

hMenuDisplay = uimenu('Label', 'Display');
hMenuContrast = uimenu(hMenuDisplay, 'Label', 'Adjust image contrast', 'Callback', @adjustContrast_Callback);
hMenuBoundBox = uimenu(hMenuDisplay, 'Label', 'Remove region bounding boxes', 'Callback', @modifyBoundingBox_Callback);
hMenuScroll = uimenu(hMenuDisplay, 'Label', 'Add scroll bar to image display', 'Callback', @scrollBar_Callback);
hMenuDenoise = uimenu(hMenuDisplay, 'Label', 'Denoise!', 'Callback', @denoiseIm_Callback);
set(hMenuDenoise, 'Checked', 'off');
        

%%%%%%Create the displayed control panels

hImPanel = uipanel('BackgroundColor', 'white', 'Position', [0.01, .18, .98, .8],...
    'Units', 'Normalized');
imageRegion = axes('Parent', hImPanel,'Tag', 'imageRegion', 'Position', [0, 0 , 1,1], 'Visible', 'on',...
    'XTick', [], 'YTick', [], 'DrawMode', 'fast');

%Handle to the scroll panel, if we make it.
hScroll = '';

offset = 0.05;
hManipPanel = uipanel('Parent', fGui, 'Units', 'Normalized', 'Position',[ 0.05 0.02 0.3 0.2-offset],...
    'Title', 'Change Registered Image');

dist = 0.3; %Spacing between slider bars
hZText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.05 0.8 0.1 0.15],...
    'Style', 'text', 'String', 'Z Depth');
hZTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.17 0.8 0.1 0.15],...
    'Style', 'edit', 'Tag', 'zedit', 'String', zMin, 'Callback', @z_Callback);
hZSlider = uicontrol('Parent', hManipPanel,'Units', 'Normalized', 'Position', [0.3 0.86 0.65 0.1],...
    'Style', 'slider', 'Min', zMin, 'Max', zMax, 'SliderStep', [zStepSmall zStepBig], 'Value', 1, 'Tag', 'zslider',...
    'Callback', @z_Callback);


hScanText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.05 0.8-2*dist 0.1 0.15],...
    'Style', 'text', 'String', 'Scan Number');
hScanTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.17 0.8-2*dist 0.1 0.15],...
    'Style', 'edit', 'String', minScan, 'Tag', 'scanEdit','Callback', @scanSlider_Callback);
%Only render slider bar if there are more than one scan in this set.

hScanSlider = uicontrol('Parent', hManipPanel,'Units', 'Normalized', 'Position', [0.3 0.86-2*dist 0.65 0.1],...
    'Style', 'slider', 'Min', minScan, 'Max',maxScan, 'SliderStep', [1 1], 'Value', 1,...
    'Callback', @scanSlider_Callback, 'Tag', 'scanSlider');


hColorText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.05 0.8-dist 0.1 0.15],...
    'Style', 'text', 'String', 'Color');
hColorTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.17 0.8-dist 0.1 0.15],...
    'Style', 'text', 'String',colorType{1});
hColorSlider = uicontrol('Parent', hManipPanel,'Units', 'Normalized', 'Position', [0.3 0.86-dist 0.65 0.1],...
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
   'RowName', rnames, 'Units', 'Normalized', 'Position', [ 0.36 0.02 0.1 0.19-offset],...
   'ColumnEditable', true);
set(hRegTable, 'CellEditCallback', @table_Callback);
%%%%%%%%%%%
% GUI Setup
%%%%%%%%%%%

% Display GUI
set([fGui,  hZSlider, imageRegion],...
    'Units', 'normalized');

movegui(fGui, 'center');


%Show the bottom image in the stack
im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));

color = colorType(colorNum);
color = color{1};

im = registerSingleImage(scanNum,color, zNum,im, data,param);
im(im(:)>40000) = 0;
hIm = imshow(im, [],'Parent', imageRegion);

%Create a scroll panel
hScroll = imscrollpanel(hImPanel, hIm);
apiScroll = iptgetapi(hScroll);

initMag = apiScroll.findFitMag();
apiScroll.setMagnification(initMag);

initializeDisplay('Initial');%Function holding everything to enable display of new information
%-necessary to make it easy to load in new scans.


%And display the first image.
hRect = findobj('Tag', 'outlineRect');
delete(hRect);

im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));

color = colorType(colorNum);
color = color{1};
getRegisteredImage(scanNum, color, zNum, im, data, param )

initMag = apiScroll.findFitMag();
apiScroll.setMagnification(initMag);


outlineRegions(); %Outline the different regions that makes up the composite region.

set(fGui, 'Visible', 'on');

%Handle to image contrast toolbar
hContrast = imcontrast(imageRegion);


%%%%%%%%%%%%%%%%%%%%%% Callback Functions


%%%%% Drop down menu callback

%Load in a new scan stack
    function loadScan_Callback(hObject, eventdata)
        fprintf(2, 'Loading in a new scan stack...');
        
        initializeDisplay();%Function holding everything to enable display of new information
        %-necessary to make it easy to load in new scans.
        
        
        %And display the first image.
        hRect = findobj('Tag', 'outlineRect');
        delete(hRect);
        
        
        im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));
        
        color = colorType(colorNum);
        color = color{1};
        getRegisteredImage(scanNum, color, zNum, im, data, param );
       
        set(hIm, 'XData', [1 param.regionExtent.regImSize(2)]);
        set(hIm, 'YData', [2 param.regionExtent.regImSize(1)]);

        
        initMag = apiScroll.findFitMag();
        apiScroll.setMagnification(initMag);
        
        
        outlineRegions(); %Outline the different regions that make up the composite region.
        
        fprintf(2, 'Done!\n');
    end

    function saveImage_Callback(hObject, eventdata)
        [filename, pathname, fIndex] = uiputfile('.tif', 'Save the displayed scan.');
        if isequal(filename,0) || isequal(pathname,0)
            disp('User pressed cancel-image will not be saved')
        else
            disp(['Saving image in the file ', fullfile(pathname, filename)])
                    im = registerSingleImage(scanNum,color, zNum,im, data,param);
        %Optionally denoise image
        if strcmp(get(hMenuDenoise, 'Checked'),'on')
            im = denoiseImage(im);
        end
        
            imwrite(im, strcat(pathname,filename), 'tiff');
        end
              
    end

    function saveScan_Callback(hObject, eventdata)
      dirName = uigetdir(param.directoryName, 'Save the entire scan stack, both colors. Only current scan number will be saved!');
      if isequal(dirName,0) 
          disp('User pressed cancel-image stack will not be saved')
          return
      end
      
      disp(['Saving image stack in the directory ', dirName]);
      
      for c = minColor:maxColor
        
          color = colorType(c);
          color = color{1};
          colorDir = strcat(dirName, filesep,color);
          mkdir(colorDir);
          disp(strcat('Saving color ', color));
          
          for zNum=zMin:zMax
              im = getRegisteredImage(scanNum, color, zNum, im, data, param);
              filename = strcat('pco', num2str(i), '.tif');
              
              imwrite(im, strcat(colorDir, filesep,filename), 'tiff');
              fprintf(2,'.');
          end
          fprintf('\n');
      end
    end

%Adjust the contrast of the images.
    function adjustContrast_Callback(hObject, eventdata)
            hContrast = imcontrast(imageRegion);

    end

    function denoiseIm_Callback(hObject, eventdat)
        
        %Use a check mark to indicate whether we'll align or not
        if strcmp(get(hMenuDenoise, 'Checked'),'on')
            set(hMenuDenoise, 'Checked', 'off');
        else
            set(hMenuDenoise, 'Checked', 'on');

        end

        
        
    end
    function scrollBar_Callback(hObject, eventdata)
       value = get(hMenuScroll, 'Label');
       
       switch value
           case 'Add scroll bar to image display'
               
               apiScroll.setMagnification(1);
               set(hMenuScroll, 'Label','Remove scroll bar');
               
           case 'Remove scroll bar'
               
               initMag = apiScroll.findFitMag();
               apiScroll.setMagnification(initMag);
               
               set(hMenuScroll, 'Label', 'Add scroll bar to image display');
               
           
       end
       
       
        
    end
    function modifyBoundingBox_Callback(hObject, eventdata)
  
       %Get the current state of this button
       value = get(hMenuBoundBox, 'Label');
       
       switch value
           case  'Add region bounding boxes'
               outlineRegions();
               set(hMenuBoundBox, 'Label', 'Remove region bounding boxes');
           case 'Remove region bounding boxes'
               %Remove the outline rectangles
               hRect = findobj('Tag', 'outlineRect');
               delete(hRect);
               set(hMenuBoundBox, 'Label', 'Add region bounding boxes');
           
       end
       
        
    end

    function outlineRegions(hObject, eventdata)
        
        %%% Draw rectangles on the image, showing the boundary of the different
        %%% regions that we're analyzing.
        
        for numReg = 1:totalNumRegions
            x = param.regionExtent.XY(numReg, 2);
            y = param.regionExtent.XY(numReg, 1);
            width = param.regionExtent.XY(numReg, 4);
            height = param.regionExtent.XY(numReg,3);
            h(numReg) = rectangle('Position', [x y width height] );
            set(h(numReg), 'EdgeColor', cMap(numReg,:));
            set(h(numReg), 'LineWidth', 2);
            set(h(numReg), 'Tag', 'outlineRect');
            pause(0.25)
        end
        outlineRect = h;
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

        
        %Only crop images in xy if hApi.getPosition exists.
        
        if(isfield(hApi, 'getPosition'))
            
            %Updating the position of the cropping rectangles
            cropRegion = zeros(totalNumRegions,4);
            for numReg=1:totalNumRegions
                
                cropRegion(numReg, :) = hApi(numReg).getPosition();
            end
            cropRegion = round(cropRegion);
            
            param.regionExtent.crop.XY = cropRegion;
            
            %Cropping the image in the xy plane
            [data,param] = registerImagesXYData('crop', data,param);     
        end
        
        %Cropping the image stack in the z direction.
        [data,param] = registerImagesZData('crop', data,param);
        
        
        %Remove the previous outline regions
        hOutRect = findobj('Tag', 'outlineRect');
        delete(hOutRect);
        %Remove the cropping rectangles.
        hRect = findobj('Tag', 'imrect');
        delete(hRect);
        im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));
        color = colorType(colorNum);
        color = color{1};
        getRegisteredImage(scanNum, color, zNum, im, data, param )
        outlineRegions();
        
        
        myhandles.param = param;
        guidata(fGui, myhandles);
    end

    function restoreImages_Callback(hObject, eventdata)
        
        %Remove the cropping rectangles.
        hRect = findobj('Tag', 'imrect');
        delete(hRect);
        
        %Remove the outline rectangles
        hRect = findobj('Tag', 'outlineRect');
        delete(hRect);
        
        %Cropping the image
        [data,param] = registerImagesXYData('original', data,param);
        
        im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));
        color = colorType(colorNum);
        color = color{1};
        getRegisteredImage(scanNum, color, zNum, im, data, param);

        outlineRegions();
    end

    function saveCropped_Callback(hObject, eventdata)
        
        
        
    end




    function table_Callback(hObject,eventData)
       tableData = get(hRegTable, 'Data');
       
       lowVal = tableData(:,1)>=param.regionExtentOrig.crop.z(:,1);
       highVal = tableData(:,2)<=param.regionExtentOrig.crop.z(:,2);
       
       extent = lowVal.*highVal;
       index = find(extent==1);
       
       %Only update z values if they are greater than or equal to the
       %smallest z value for that region, and less than or equal to the
       %highest z value
       param.regionExtent.crop.z(index,:) = tableData(index,:);
       
       set(hRegTable, 'Data', param.regionExtent.crop.z);
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
        getRegisteredImage(scanNum, color, zNum, im, data, param);
    end

    function scanSlider_Callback(hObject, eventData)
        scanTag = get(hObject, 'tag');
        
        switch scanTag
            case 'scanSlider'
                scanNum = get(hScanSlider, 'Value');
                scanNum = int16(scanNum);
                
                %Update the displayed z level.
                set(hScanTextEdit, 'String', scanNum);
            case 'scanEdit'
                scanNum = get(hScanTextEdit, 'string');
                scanNum = str2double(scanNum);
                scanNum = int16(scanNum);
                
                set(hScanSlider, 'Value',double(scanNum));
        end
        
        %Display the new image
        color = colorType(colorNum);
        color = color{1};
        getRegisteredImage(scanNum, color, zNum, im, data, param);
    end
    function z_Callback(hObject, eventData)
        
        zTag = get(hObject, 'tag');
        
        switch zTag
            case 'zslider'
                zNum = get(hZSlider, 'Value');
                zNum = int16(zNum);
                
                %Update the displayed z level.
                set(hZTextEdit, 'String', zNum);
            case 'zedit'
                zNum = get(hZTextEdit, 'string');
                zNum = str2double(zNum);
                zNum = int16(zNum);
                
                set(hZSlider, 'Value',double(zNum));
        end
        
        color = colorType(colorNum);
        color = color{1};
        
        %Get the desired image and display it
        getRegisteredImage(scanNum, color, zNum, im, data, param );
                
        %Update the previous examined Z slice
        zLast = zNum;
    end


%Callbacks for the polygon outlining of the gut

    function createFreeHandPoly_Callback(hObject, eventdata)
        %Start drawing the boundaries!
        hPoly = impoly(imageRegion);   
        
    end


    function loadPoly_Callback(hObject, eventdata)
        hPoly = impoly(imageRegion, param.regionExtent.poly);
       
    end

    function smoothPoly_Callback(hObject, eventdata)
       if(isfield(param.regionExtent, 'poly'));
           %Only smooth the polygon if it exists.
           poly = param.regionExtent.poly;
           
           %Parameterizing curve in terms of arc length
           t = cumsum(sqrt([0,diff(poly(:,1)')].^2 + [0,diff(poly(:,2)')].^2));
           %Find x and y positions as a function of arc length
           polyFit(:,1) = spline(t, poly(:,1), t);
           polyFit(:,2) = spline(t, poly(:,2), t);
           
           %Interpolate curve to make it less jaggedy, arbitrarily we'll
           %set the number of points to be 50.
           stepSize = (max(t)-min(t))/100.0;
           
           polyT(:,2) = interp1(t, polyFit(:,2),min(t):stepSize:max(t),'spline', 'extrap');
           polyT(:,1) = interp1(t, polyFit(:,1),min(t):stepSize:max(t), 'spline', 'extrap');
           
           %Redefining poly
           poly = cat(2, polyT(:,1), polyT(:,2));
           
           param.regionExtent.poly = poly;
           %Redrawing the polygon
           hApi = iptgetapi(hPoly);
           hApi.setPosition(poly);
           
           %Saving the resulting polygon
           myhandles.param = param;
           
           guidata(fGui, myhandles);
       end
        
    end

    function savePoly_Callback(hObject, eventdata)
        hApi = iptgetapi(hPoly);
        param.regionExtent.poly = hApi.getPosition();
        myhandles.param = param;
        %Save the GUI handles
        guidata(fGui, myhandles);
        
        %Save the result to the param file associated with the data.
        saveFile = [param.dataSaveDirectory filesep 'param.mat'];
        save(saveFile, 'param');
    end


    function clearPoly_Callback(hObject, eventdata)
       delete(hPoly); %Delete the displayed polygon. 
    end
        
    function drawGutCenter_Callback(hObject, eventdata)
        h = impoly('Closed', false);
        
        set(h, 'Tag', 'gutCenter');
        position = wait(h);
        
        param.centerLine = position;
        myhandles.param = param;
        guidata(fGui, myhandles);
               
    end

    function smoothGutCenter_Callback(hObject, eventdata)
        hLine = findobj('Tag', 'gutCenter');
        delete(hLine);
        line = getCenterLine(param.centerLine, 5, param);
        h = impoly(imageRegion, line, 'Closed', false);
        set(h, 'Tag', 'gutCenter');
        
    end

    function saveGutCenter_Callback(hObject, eventdata)
        
        %Annoying way to get the position of the line
        hLine = findobj('Tag', 'gutCenter');
        hLine = iptgetapi(hLine);
        
        param.centerLine = hLine.getPosition();
        myhandles.param = param;
        guidata(fGui, myhandles);

        saveFile = [param.dataSaveDirectory filesep 'param.mat'];
        save(saveFile, 'param');
    end
    function loadGutCenter_Callback(hObject, eventdata)
        if(isfield(param, 'centerLine'))
            hLine = findobj('Tag', 'gutCenter');
            delete(hLine);
            h = impoly(imageRegion, param.centerLine, 'Closed', false);
            set(h, 'Tag', 'gutCenter');
       end
        
    end
  
%%%%%%%%%%%%%Code to initialize the display of all data
 
    function []= initializeDisplay(varargin)
        
        if nargin==0
            %Load in new parameters
            [data,param] = loadParameters;
        end
        
        %Set z values
        zMax = length([param.regionExtent.Z]);
        
        zStepSmall = 1.0/(zMax-zMin);
        zStepBig = 15.0/(zMax-zMin);
        
        %Update the display of z values
        set(hZTextEdit, 'String', zMin);
        set(hZSlider, 'Min', zMin);
        set(hZSlider, 'Max', zMax);
        set(hZSlider, 'SliderStep', [zStepSmall, zStepBig]);
        
        
        %Set the number of scans
        %%%%%% number of scans
        numScans = param.expData.totalNumberScans;
        numScans = uint16(numScans);
        minScan = uint16(1);
        maxScan = uint16(numScans);
        scanNum = 1;
        
        scanStepSmall = 1/double(numScans);
        scanStepBig = 2.0/double(numScans);
       
        set(hScanTextEdit, 'String', minScan);
        set(hScanSlider, 'Min', minScan);
        set(hScanSlider, 'Max', maxScan);
        set(hScanSlider, 'SliderStep', [scanStepSmall, scanStepBig]);
        
        if(maxScan==1)
           set(hScanText, 'Visible', 'off');
           set(hScanSlider, 'Visible', 'off');
           set(hScanTextEdit, 'Visible', 'off'); 
        else
            set(hScanText, 'Visible', 'on');
            set(hScanSlider, 'Visible', 'on');
            set(hScanTextEdit, 'Visible', 'on');
        end
        
        
        
        %%%%%% number of colors
        numColor = length([param.color]);
        minColor = 1;
        maxColor = numColor;
        colorType = [param.color];
        colorNum = 1;
        %%%%And update the slider bar
        set(hColorTextEdit, 'String', minColor);
        set(hColorSlider, 'Min', minColor);
        set(hColorSlider, 'Max', maxColor);
        
        
        %%%number of regions
        totalNumRegions = length(unique([param.expData.Scan.region]));
        
        %Color map for bounding rectangles.
        cMap = rand(totalNumRegions,3);
        
        
        %Update the table for max and min z values.
        dataTable = param.regionExtent.crop.z;
        set(hRegTable, 'Data', dataTable);
        for i=1:totalNumRegions
            rnames{i} = i;
        end
        set(hRegTable, 'RowName', rnames);
        

    end

    function imF = denoiseImage(im)
                 
        %Denoise the image by filtering with a gaussian filter with a sigma
        %equal to the width of the PSF
        %sigma = 0.22*wavelength/NA...I think I got all the terms right.
        hG = fspecial('Gaussian', ceil(7*0.66),0.66);
        imF = imfilter(im, hG);
        
    end

%Function to get a desired image for either display or for saving
    function [] = getRegisteredImage(scanNum, color, zNum, im, data, param )
        im = registerSingleImage(scanNum,color, zNum,im, data,param);
        %Optionally denoise image
        if strcmp(get(hMenuDenoise, 'Checked'),'on')
            im = denoiseImage(im);
        end
        %Get rid of really bright pixels. WARNING: if the image is bright
        %to begin with this will mess things up. This approach is somewhat
        %crude. What we should really be doing is 
        im(im(:)>50000) = 0;
        set(hIm, 'CData', im);

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

function [data, param] = loadParameters()
                dirName = uigetdir(pwd, 'Pick a directory to show the registered images from.');
                paramFile = [dirName, filesep, 'gutOutline', filesep, 'param.mat'];
                paramFileExist = exist(paramFile, 'file');
                dataFile = [dirName, filesep, 'gutOutline', filesep, 'data.mat'];
                %If work has been done on this file already, load in the results
                
                
                switch paramFileExist
                    case 2
                        disp('Parameters for this scan have already been (partially?) calculated. Loading them into the workspace.');
                        
                        paramTemp = load(paramFile);
                        dataTemp = load(dataFile);
                        
                        param = paramTemp.param;
                        data = dataTemp.data;
                        
                    case 0
                        
                        parameterFile = [dirName, filesep, 'ExperimentData.mat'];
                        %Load in information about this scan...this information should be
                        %passed in, or stored in one place on the computer.
                        param.micronPerPixel = 0.1625; %For the 40X objective.
                        param.imSize = [2160 2560];
                        
                        expData = load(parameterFile);
                        param.expData = expData.parameters;
                        
                        param.directoryName = dirName;
                        
                        %Load in the number of scans. Default will be for all of the
                        %scans...might want to make this an interactive thing at some point.
                        param.scans = 1:param.expData.totalNumberScans;
                       % param.scans = 3:37;
                        %Number of regions in be analyzed. Hardcoded to be all of them
                        param.regions = 'all';
                       % param.regions = 1:4;
                        %Colors to be analyzed. Need to provide a more machine readable way and
                        %elegant way to load this into the code.
                        param.color = [{'488nm'}, {'568nm'}];
                        %param.color = [{'568nm'}];
                        %For the parameters above construct a structure that will contain all the
                        %results of this calculation.
                        
                        [data,param] = initializeScanStruct(param);
                        
                        disp('Paremeters succesfully loaded.');
                        
                        % Calculate the overlap between different regions
                        
                        fprintf(2,'Calculating information needed to register the images...');
                        [data,param] = registerImagesXYData('original', data,param);
                        
                        [data,param] = registerImagesZData('original', data,param);
                        
                        %Store the result in a backup structure, since .regionExtent will be
                        %modified by cropping.
                        param.regionExtentOrig = param.regionExtent;
                        fprintf(2, 'done!\n');
                        
                end
                
                
                %The number of scans might not equal the number reported
                %if the scan was halted early...manually updating this 

                scanDir = dir([param.directoryName filesep 'Scans']);
                numScans = regexp({scanDir.name}, 'scan_\d+');
                numScans = sum([numScans{:}]);
                param.expData.totalNumberScans = numScans;
    end