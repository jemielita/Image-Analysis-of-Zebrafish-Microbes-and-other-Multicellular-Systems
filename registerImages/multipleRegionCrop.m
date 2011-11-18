
function [param, data] = multipleRegionCrop(param, data)

global param
global data
multipleRegionCropGUI();


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
