
function [param, data] = multipleRegionCrop(paramIn, dataIn)

global param
param = paramIn;
global data
data  = dataIn;

%Manually outline regions that should be cropped.
multipleRegionCropGUI();

%Find the cropped regions that this corresponds to.
param = calcCropRegion(param);

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

%%%%%%%%%%%%%%%%
% The GUI window
fGui = figure('Name', 'Play the Outline the Gut Game!', 'Menubar', 'none', 'Tag', 'fGui',...
    'Visible', 'off', 'Position', [50, 50, 2000, 900], 'Color', [0.925, 0.914, 0.847]);

%%%%%%%%%%%%%%%%%%%%%%%%
% AXES to DISPLAY IMAGES


imageRegion = axes('Tag', 'imageRegion', 'Position', [0.01, .18, .98, .8], 'Visible', 'on',...
    'XTick', [], 'YTick', [], 'DrawMode', 'fast');


hManipPanel = uipanel('Parent', fGui, 'Units', 'Normalized', 'Position',[ 0.05 0.02 0.3 0.2],...
    'Title', 'Change Registered Image');
  

dist = 0.3; %Spacing between slider bars
hZText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.05 0.8 0.1 0.15],...
    'Style', 'text', 'String', 'Z Depth');
hZTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.17 0.8 0.1 0.15],...
    'Style', 'text', 'String', zMin);
hZSlider = uicontrol('Parent', hManipPanel,'Units', 'Normalized', 'Position', [0.3 0.86 0.65 0.1],...
    'Style', 'slider', 'Min', zMin, 'Max', zMax, 'SliderStep', [zStepSmall zStepBig], 'Value', 1,...
    'Callback', @zSlider_Callback);

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



%%% Draw rectangles on the image, showing the boundary of the different
%%% regions that we're analyzing.
cMap = rand(totalNumRegions,3);

for numReg = 1:totalNumRegions
    x = param.regionExtent.XY(numReg, 2);
    y = param.regionExtent.XY(numReg, 1);
    width = param.regionExtent.XY(numReg, 4)-x+1;
    height = param.regionExtent.XY(numReg,3) -y +1;
    h = rectangle('Position', [x y width height] );
    set(h, 'EdgeColor', cMap(numReg,:));
    set(h, 'LineWidth', 2);
    pause(0.25)
end


%Create a number of rectangles equal to the number of regions in the
%registered image. These will be resizable and will allow the user a way to
%outline the regions that should be kept.
for numReg = 1:totalNumRegions
    imrect(imageRegion);
end
%After these rectangles have been placed down, find the handles to these
%rectangles.
hRect = findobj('Tag', 'imrect');

if(length(hRect)~=totalNumRegions)
    disp('The total number of rectangles does not match the number of regions!');
end

%Get the application programmer interface (whatever that means) for this
%handle (allows us to get position measurements more easily)

for numReg=1:totalNumRegions
    api(numReg) = iptgetapi(hRect(numReg));
    %For each of these api's add a callback function that updates a stored
    %array of all the positions
end

%Adding in a timer that will every second look for the position of these
%rectangles and update an array with them in it.
%Clumsy, but accessing this array of positions is somewhat difficult
%otherwise.
t = timer('TimerFcn',@getPositionTime_Callback, 'Period', 1);
set(t, 'ExecutionMode', 'fixedRate');
start(t);

%%%%%%%%%%%%%%%%%%%%%% Callback Functions
    function table_Callback(hObject,eventData)
       tableData = get(hRegTable, 'Data');
       param.regionExtent.crop.z = tableData;
    end

    function getPositionTime_Callback(hObject, eventData)
       b = 0;
       cropRegion = zeros(totalNumRegions,4);
       for numReg=1:totalNumRegions
          cropRegion(numReg, :) = api(numReg).getPosition(); 
       end
           
       param.regionExtent.crop.XY = cropRegion;
       
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
    function zSlider_Callback(hObject, eventData)
        zNum = get(hZSlider, 'Value');
        zNum = ceil(zNum);
        zNum = int16(zNum);
        
        %Update the displayed z level.
        set(hZTextEdit, 'String', zNum);
        
        color = colorType(colorNum);
        color = color{1};
        im = registerSingleImage(scanNum,color, zNum,im, data,param);
        set(hIm, 'CData', im);
                
        %Update the previous examined Z slice
        zLast = zNum;
    end


end


function param = calcCropRegion(param)

%Clumsy, but transparent way to do this.

%Make a mask equal to the size of the total, registered image
im = zeros(param.regionExtent.regImSize(1), param.regionExtent.regImSize(2));

%Create a mask that corresponds to each sub image that makes up this total
%registered image and also in turn to each cropped region. Find the pixels
%that overlap and get a range from this.



end