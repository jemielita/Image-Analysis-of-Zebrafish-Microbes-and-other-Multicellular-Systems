
function [param,data] = multipleRegionCrop(varargin)
switch nargin
    case 0
        [data, param] = loadParameters();
        if(strcmp(data, 'error'))
            fprintf(2, 'No directory selected!\n');
            return;
        end
    case 1
        fileDir = varargin{1};
        
        [data, param] = loadParameters(fileDir);
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
if(nargin>0)
    %if(strcmp(varargin{3}, 'save results')||nargin==1)
        while(~isempty(findobj('Tag', 'fGui')))
            handles = findobj('Tag', 'fGui');
            paramTemp = guidata(handles);
            param = paramTemp.param;
            pause(0.5);
        end
   % end
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
if(isfield(param.regionExtent, 'Z'))
    zMax = length([param.regionExtent.Z]);
else 
    zMax = zMin+1;
end
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
scanNumPrev = scanNum;
%%%%%% number of colors
numColor = length([param.color]);
minColor = 1;
maxColor = numColor;
colorType = [param.color];
colorNum = 1;


%Load in fish analysis class-over time most of what we do in this program
%that has a bearing on curating the *analysis* of our data should be moved
%here (e.g. spot detection filtering, clump filtering, etc.). The param
%structure should be used exclusively for parameters that affect region
%features of the fish themselves (gut outline, etc.)
f = fishClass(param);


%%%%%%%%%%%% variable that contains information about expected pixel
%%%%%%%%%%%% intensity of background and different colors of bacteria
bkgInten = cell(numScans, numColor); 
bacInten = cell(numScans, numColor);

%%%%%%% projection type
projectionType = 'mip';

%%%number of regions
if(isfield(param.expData.Scan, 'isScan'))
    totalNumRegions = unique([param.expData.Scan.region].*[strcmp('true', {param.expData.Scan.isScan})]);
else
    totalNumRegions = unique([param.expData.Scan.region]);
end
totalNumRegions(totalNumRegions==0) = [];

totalNumRegions = length(totalNumRegions);
 
%%%%api handle
hApi = '';

%%%%%handle to polygon
hPoly = '';

%Color map for bounding rectangles and cropping rectangles
cMap = rand(totalNumRegions,3);
outlineRect = '';

%%%%%%%%%%%%%%%%
% The GUI window
figName = ['Play the Outline the Gut Game!   ', param.directoryName];
fGui = figure('Name', figName, 'Menubar', 'none', 'Tag', 'fGui',...
    'Visible', 'off', 'Position', [50, 50, 2000, 900], 'Color', [0.925, 0.914, 0.847]);


%Set key press functions for the figure-will be used to interface with
%touch screen monitor more efficiently
%Can be changed by the user in File/change key-stroke value
set(fGui, 'KeyPressFcn', @(fGui, evt)keyPressGUI(fGui, evt));


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
uimenu(hMenuFile, 'Label', 'Save param and fish file', 'Callback', @saveParam_Callback);
uimenu(hMenuFile, 'Label', 'Load fish analysis file', 'Separator', 'on' ,'Callback', @loadFishAnalysis_Callback);
uimenu(hMenuFile, 'Separator', 'on', 'Label', 'Change key-stroke value', 'Callback', @changeKeystroke_Callback);
uimenu(hMenuFile, 'Label', 'Set default GUI screen location', 'Callback', @saveWindowLocation_Calback);

hMenuCrop = uimenu('Label','Crop Images');
uimenu(hMenuCrop,'Label','Create cropping boxes','Callback',@createCropBox_Callback);
uimenu(hMenuCrop, 'Label', 'Crop the images', 'Callback', @cropImages_Callback);
uimenu(hMenuCrop, 'Label', 'Restore original image', 'Callback', @restoreImages_Callback);

uimenu(hMenuCrop, 'Label', 'Save cropped region', 'Callback', @saveCropped_Callback);
uimenu(hMenuCrop, 'Label', 'Single crop region', 'Separator', 'on', ...
    'Callback', @singleCrop_Callback);
hQuickZ = uimenu(hMenuCrop, 'Label', 'Quick z-crop Initialize', 'Callback', @heightZCrop_Callback, 'Separator', 'on',...
     'Checked', 'off');

hzCropBoxInit = uimenu(hMenuCrop, 'Label', 'Add new Z-crop box', 'Callback', @cropBoxInit_Callback);
zCropBox = cell(numScans,1);
zCropBoxHandle = [];

hzCropBox = uimenu(hMenuCrop, 'Label', 'Finalize z-crop box', 'Callback', @cropBoxMeas_Callback);

hMenuOutline = uimenu('Label', 'Outline region');
hMultipleOutline = uimenu(hMenuOutline, 'Label', 'New outline/center for each time point', 'Checked', 'on', 'Separator', 'on',...
    'Callback', @multipleOutline_Callback);
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
uimenu(hMenuOutline, 'Label', 'Clear center of gut line', 'Callback', @clearGutCenter_Callback);

uimenu(hMenuOutline, 'Label', 'Smooth/extrapolate all outlines & centers',...
    'Separator', 'on', 'Callback', @smoothAll_Callback);

%Box to outline the region containing the bulb
uimenu(hMenuOutline, 'Label', 'Outline bulb region', 'Callback', @outlineBulbRegion_Callback, 'Separator', 'on');
hShowBulbSeg = uimenu(hMenuOutline, 'Label', 'Show bulb segmentation', 'Callback', @showBulbSegmenatation_Callback, 'Checked', 'off');
showBulb = false;

hMenuOutlineEntireGut = uimenu(hMenuOutline, 'Label', 'Outline entire gut', 'Callback', @outlineEntireGut_Callback, 'Separator', 'on');
hMenuSaveEntireGutOutline = uimenu(hMenuOutline, 'Label', 'Save entire gut outline', 'Callback', @saveEntireGut_Callback);
entireGutOutline = cell(maxScan-minScan+1,zMax-zMin+1);
hPolyEntireGut = [];

%Create outlines for each of the clumps found in the gut
hMenuCreateClumpOutline = uimenu(hMenuOutline, 'Label', 'Show/add clump outline', 'Separator', 'on', ...
    'Callback', @showClumpOutline_Callback);
hMenuAddClumpOutline = uimenu(hMenuOutline, 'Label', 'Make new clump outline', 'Callback', @outlineClump_Callback);
hMenuClearClumpOutline = uimenu(hMenuOutline, 'Label', 'Clear last clump outline', 'Callback', @clearClumpOutline_Callback);
hMenuSaveClumpOutline = uimenu(hMenuOutline, 'Label', 'Save clump outline', 'Callback', @saveClumpOutline_Callback);
clumpOutline = [];
hClumpPoly = [];



hMenuDisplay = uimenu('Label', 'Display');
hMenuContrast = uimenu(hMenuDisplay, 'Label', 'Adjust image contrast', 'Callback', @adjustContrast_Callback);
hMenuBoundBox = uimenu(hMenuDisplay, 'Label', 'Add region bounding boxes', 'Callback', @modifyBoundingBox_Callback);
hMenuScroll = uimenu(hMenuDisplay, 'Label', 'Add scroll bar to image display', 'Callback', @scrollBar_Callback);
hMenuDenoise = uimenu(hMenuDisplay, 'Label', 'Denoise!', 'Callback', @denoiseIm_Callback);
set(hMenuDenoise, 'Checked', 'off');
hMenuMIP = uimenu(hMenuDisplay, 'Label', 'Maximum intensity projection', 'Callback', @mip_Callback);
hMenuOverlapImages = uimenu(hMenuDisplay, 'Label', 'Overlap different colors', 'Callback', @overlapColors_Callback, 'Checked', 'off');

hMenuChangeVariableZStep = uimenu(hMenuDisplay, 'Label', 'Change variable z-step', 'Callback', @changeVarZ_Callback, 'Tag', '1');
multiZSliceMax = 1;

hMenuShowSegmentation = uimenu(hMenuDisplay, 'Separator', 'on', 'Label', 'Show gut segmentation', ...
    'Checked', 'off','Callback', @showSegmentation_Callback);
hMenuSetSegementationType = uimenu(hMenuDisplay, 'Label', 'Choose segmentation type', 'Callback', @setSegmentation_Callback);
segmentationType.List = {'none', 'Otsu', 'estimated background', 'final seg', 'clump'};
segmentationType.Selection = 'none';
hMenuShowFoundCoarseRegions = uimenu(hMenuDisplay, 'Label', 'Show coarse analysis results', 'Callback', @showCoarseResults_Callback);

%Neutrophil identification
hMenuSpotSelectorMenu = uimenu('Label', 'Spot selector');
hMenuSpot = uimenu(hMenuSpotSelectorMenu, 'Checked', 'off', 'Label', 'Add spots', 'Callback', @addSpots_Callback);
hMenuSpotSave = uimenu(hMenuSpotSelectorMenu, 'Label', 'Save spot list', 'Callback', @saveSpots_Callback);
spotList = cell(numScans, numColor);
hMenuSpotRemove = uimenu(hMenuSpotSelectorMenu, 'Label', 'Remove last spot', 'Callback', @removeLastSpots_Callback);

hMenuRemoveClump = uimenu(hMenuSpotSelectorMenu, 'Separator', 'on', 'Label', 'Begin removing clumps','Checked', 'off','Callback', @removeClump_Callback);
hMenuAddRemoveClump = uimenu(hMenuSpotSelectorMenu,'Label', 'Remove clump', 'Callback', @removeThisClump_Callback);
hMenuLoadClumpData = uimenu(hMenuSpotSelectorMenu, 'Label', 'Load clump data', 'Callback', @loadClump_Callback);

%% 
hManualSpotPlot = [];
hSpotSelect = [];

overlapBugs = false;
hP{1} = ''; %Handle to bugs located above, at the current (or near to) z-slice, and above.
hP{2} = '';
hP{3} = '';
hMenuOverlapBugs = uimenu(hMenuDisplay, 'Label', 'Show found bugs', 'Separator', 'on', 'Callback', @overlapBugs_Callback, 'Checked', 'off');
hMenuOverlapBugOptions = uimenu(hMenuDisplay, 'Label', 'Bug label options', 'Callback', @overlapBugOptions_Callback);
hMenuRemoveBugs = uimenu(hMenuDisplay, 'Label', 'Remove bugs', 'Callback', @removeBugs_Callback, 'Checked', 'off');
rProp = ''; %Will be filled with information about current scans found bacteria
removeBugInd = cell(numScans, numColor); %Variable to save culled bacteria points.
remBugsSaveDir = [param.dataSaveDirectory filesep 'singleBacCount' filesep 'removedBugs.mat'];
if(exist(remBugsSaveDir, 'file')==2)
   removeBugInd = load(remBugsSaveDir); 
   removeBugInd = removeBugInd.removeBugInd;
end
hMenuUseSavedRemBugList = uimenu(hMenuDisplay, 'Label', 'Use only saved removed bug list', 'Callback', @useSaveRemBug_Callback);

hMenuKeepBugs = uimenu(hMenuDisplay, 'Label', 'Label bugs (instead of removing)', 'Callback', @keepBugs_Callback, 'Checked', 'off');
keepBugInd = cell(numScans, numColor); %Variable to save culled bacteria points.
keepBugsSaveDir = [param.dataSaveDirectory filesep 'singleBacCount' filesep 'removedBugs.mat'];
if(exist(keepBugsSaveDir, 'file')==2)
   keepBugInd = load(keepBugsSaveDir); 
   if(isfield(keepBugInd, 'keepBugInd'))
       keepBugInd = keepBugInd.keepBugInd;
   else 
       keepBugInd  = cell(numScans, numColor);
   end
else
    keepBugInd  = cell(numScans, numColor);
end

hMenuSaveRemovedBugs = uimenu(hMenuDisplay, 'Label', 'Save removed bug list', 'Callback', @saveRemovedBugs_Callback);
hMenuShowAllBugs = uimenu(hMenuDisplay, 'Label', 'Show ALL found bugs', 'Callback', @showAllBugs_Callback);
hMenuVariableZ = uimenu(hMenuDisplay, 'Label', 'Only z slices with found bugs', 'Callback', @variableZ_Callback);
useSubsetZList = false;
zSubsetList = [];

hMenuManualParticleThresh = uimenu(hMenuDisplay, 'Label', 'Manual thresholding for particles','Callback', @manualThresh_Callback);
useManualParticleThresh = false;
manualParticleThresh = zeros(numScans, numColor,2);
%hMenuManualParticleThreshChange = uimenu(hMenuDisplay, 'Label', 'Change manual threshold value', 'Callback', @changeManualThresh_Callback);



hMenuRegister = uimenu('Label', 'Registration');
hMenuRegisterManual = uimenu(hMenuRegister, 'Label', 'Manually register images',...
    'Callback', @getImageArray_Callback);
set(hMenuRegisterManual, 'Checked', 'off');
hMenuRegisterResize = uimenu(hMenuRegister, 'Label', 'Minimize total image size',...
    'Callback', @setMinImageSize_Callback);

hMenuGlobalOffsetSave = uimenu(hMenuRegister, 'Label', 'Save global offset in registration',...
    'Callback', @saveRegisterGlobalOffset_Callback, 'Separator', 'on');





hMenuSeg = uimenu('Label', 'Segment');
hMenuSurf = uimenu(hMenuSeg, 'Label', 'Remove surface cells', 'Callback', @segSurface_Callback, 'Checked', 'off', 'Visible', 'off');
hMenuBkg = uimenu(hMenuSeg, 'Label', 'Label background pixel intensity', 'Callback',@background_Callback,'Checked', 'off');
hMenuBacteria = uimenu(hMenuSeg, 'Label', 'Identify single bacteria', 'Callback', @outlineBacteria_Callback, 'Checked', 'off');
hMenuCameraBkg = uimenu(hMenuSeg, 'Label', 'Identify camera background noise', 'Callback', @camBackground_Callback);

hMenuEndGut = uimenu(hMenuSeg, 'Separator', 'On','Label',  'Label the end of the gut', 'Callback', @endGut_Callback, 'Checked', 'off');
hMenuAutoFluorGut = uimenu(hMenuSeg, 'Label', 'Label beginning of autofluorescent region', 'Callback', @autoFluorGut_Callback, 'Checked', 'off');
hMenuEndAutoFluorGut = uimenu(hMenuSeg, 'Label', 'Label the end of the autofluorescent region', 'Callback', @autoFluorEnd_Callback, 'Checked', 'off');
hMenuBeginGut = uimenu(hMenuSeg, 'Label', 'Label beginning of the gut (EJ)', 'Callback', @beginGut_Callback);
hMenuEndBulb = uimenu(hMenuSeg, 'Label', 'Label ~ end of bulb', 'Callback', @endBulb_Callback);

%Populating markers for different parts of the gut
if(~isfield(param, 'endGutPos')||size(param.endGutPos,1)~=maxScan)
        param.endGutPos = zeros(maxScan, 2);
end

if(~isfield(param, 'autoFluorPos')||size(param.autoFluorPos,1)~=maxScan)
        param.autoFluorPos = zeros(maxScan, 2);
end

if(~isfield(param, 'endBulbPos')||size(param.endBulbPos,1)~=maxScan)
        param.endBulbPos = zeros(maxScan, 2);
end

if(~isfield(param, 'autoFluorEndPos')||size(param.autoFluorEndPos,1)~=maxScan)
        param.autoFluorEndPos = zeros(maxScan, 2);
end

if(~isfield(param, 'beginGutPos')||size(param.beginGutPos,1)~=maxScan)
        param.beginGutPos = zeros(maxScan, 2);
end

%Create a table that will contain the x and y location of each of the image
%panels-we'll use this to manually adjust the location of each of the
%images to fix our registration issues.

for i=0:length(param.color)-1
   cnames{2*i+1} = [param.color{i+1}, '  x'];
   cnames{2*i+2} = [param.color{i+1}, '   y'];
end

rnames = cell(totalNumRegions,1);
for i=1:totalNumRegions
    rnames{i} = i;
end

rnames{end+1} = 'size';

dataTable = [];
for i=1:length(param.color)
    thisColorData = [param.regionExtent.XY{i}(:, 1:2); param.regionExtent.regImSize{i}];
dataTable = [dataTable,thisColorData];
end

offset = 0.05;
hxyRegTable = uitable('Parent', fGui,...
'Data', dataTable, 'ColumnName', cnames,...
   'RowName', rnames, 'Units', 'Normalized', 'Position', [ 0.50 0.02 0.23 0.19-offset],...
   'ColumnEditable', true);
set(hxyRegTable, 'CellEditCallback', @manualRegisterImage_Callback);
set(hxyRegTable, 'Visible', 'off');

hMenuAlternateRegions = uibuttongroup('Parent', fGui, 'Units', 'Normalized',...
    'Position', [ 0.76 0.02 0.05 0.1]);
hReg1 = uicontrol('Parent', hMenuAlternateRegions,'Style', 'Radio', 'String', 'Odd','Units', 'Normalized',...
    'Position', [0.1 0.05 0.9 0.25]);
hReg2 = uicontrol('Parent', hMenuAlternateRegions,'Style', 'Radio', 'String', 'Even','Units', 'Normalized',...
    'Position', [0.1 0.40 0.9 0.25]);
hReg3 = uicontrol('Parent', hMenuAlternateRegions,'Style', 'Radio', 'String', 'Both','Units', 'Normalized',...
    'Position', [0.1 0.70 0.9 0.25]);
set(hMenuAlternateRegions, 'SelectionChangeFcn', @alternateRegions_Callback);
set(hMenuAlternateRegions, 'Visible', 'off');

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


%Button group to select one of several projection types
hMenuProjectionType = uibuttongroup('Parent', fGui, 'Units', 'Normalized','Title', 'Projection',...
    'Position', [ 0.005 0.02 0.04 0.2-offset]);
hProj2 = uicontrol('Parent', hMenuProjectionType,'Style', 'Radio', 'String', 'mip','Units', 'Normalized',...
    'Position', [0.1 0.40 0.9 0.25]);
hProj3 = uicontrol('Parent', hMenuProjectionType,'Style', 'Radio', 'String', 'none','Units', 'Normalized',...
    'Position', [0.1 0.70 0.9 0.25]);
hProj1 = uicontrol('Parent', hMenuProjectionType,'Style', 'Radio', 'String', 'multiZSlice','Units', 'Normalized',...
    'Position', [0.1 0.05 0.9 0.25]);


set(hMenuProjectionType, 'SelectionChangeFcn', @projectionType_Callback);



%Create a data table where the user can give the upper and upper bound (in
%terms of the z level) for different regions.
 cnames = {'Bottom', 'Top'};
 rnames = cell(totalNumRegions,1);
 for i=1:totalNumRegions
    rnames{i} = i;
 end

 if(isfield( param.regionExtent, 'crop'))
     dataTable = param.regionExtent.crop.z;
     
     hRegTable = uitable('Parent', fGui,...
         'Data', dataTable, 'ColumnName', cnames,...
         'RowName', rnames, 'Units', 'Normalized', 'Position', [ 0.36 0.02 0.11 0.19-offset],...
         'ColumnEditable', true);
     set(hRegTable, 'CellEditCallback', @table_Callback);
     
 end
%%%%%%%%%%%
% GUI Setup
%%%%%%%%%%%

% Display GUI
set([fGui,  hZSlider, imageRegion],...
    'Units', 'normalized');


%Move multipleRegionCrop window to a location that works best for this
%computer.
S = which('multipleRegionCrop.m');
S = [S(1:end-20) 'windowLocation.mat'];
if(exist(S)==2)
    inputVar = load(S);
    windowPos = inputVar.windowPos;
    set(fGui, 'Position', windowPos);
else
    movegui(fGui, 'center');
end

%Show the bottom image in the stack
im = zeros(param.regionExtent.regImSize{1}(1), param.regionExtent.regImSize{1}(2));

color = colorType(colorNum);
color = color{1};

projectionType = 'mip';

hIm = imshow(im, [],'Parent', imageRegion);

im = getRegisteredImage(scanNum, color, 0, im, data, param );
im(im(:)>40000) = 0;

set(imageRegion, 'CLim', [0 1000]);

numColor = length(param.color);

%%% quick Z cropping variables
imArray = cell(numColor,totalNumRegions); %Will be used for quickly registering the different regions of the image.
imAll = cell(numColor, totalNumRegions); %Store entire z-stack in both colors-used for quickly cropping in the z-direction
imAllmip = cell(numColor, totalNumRegions,2); %Store the mip for each region and the pixel location of the MIP pixel
im = cell(totalNumRegions,1); %Store the index where the MIP pixel is located.

imZ = cell(numColor, 3); %Handle to subplots used to crop in the z-direction on the image stacks.
imZmip = '';%Handle to images in each of these subplots
imZMask = ''; %Masks that will be used to crop the images in the z-direction differently at different points in the image

%contains the different points the user has selected to change the cropping
%height of the image
%The structure of the variables is: zCropPos{1,:}: contains the information
%for cropping above the gut in the z direction, while zCropPos{2,:} contains
%info for cropping below the gut. zCrop{n,j} is a structure with the
%following elements
% zCrop{n,j}.handle = handle to line drawn showing where we clicked the
% image
% zCrop{n,j}.pos = pos in x,y where we drew the line
% zCrop{n,j}.z = final z height to crop the image to.
%This variable will be used to construct an interpolative z-crop along the
%entire length of the gut...the hope is that this will reduce the number of
%"clicks" necessary to crop the gut.
zCrop = cell(0,0);
surfaceCell = cell(0,0); %Same structure as zCrop, but will be used to exclusively remove surface cells from the image series
hThresh = ''; %Handle to the mask showing segmented/possible segmented regions
threshIm = ''; %Array that will contain the masks for pixels that we're trying to remove from the image

imC = [];
%Create a scroll panel
hScroll = imscrollpanel(hImPanel, hIm);
apiScroll = iptgetapi(hScroll);

initMag = apiScroll.findFitMag();
apiScroll.setMagnification(initMag);
pause(1);
while(apiScroll.getMagnification()~=initMag)
    pause(0.1);
end
initializeDisplay('Initial');%Function holding everything to enable display of new information
%-necessary to make it easy to load in new scans.

%And display the first image.
hRect = findobj('Tag', 'outlineRect');
delete(hRect);

im = zeros(param.regionExtent.regImSize{1}(1), param.regionExtent.regImSize{1}(2));

color = colorType(colorNum);
color = color{1};
getRegisteredImage(scanNum, color, zNum, im, data, param )

initMag = apiScroll.findFitMag();
apiScroll.setMagnification(initMag);


%outlineRegions(); %Outline the different regions that makes up the composite region.

set(fGui, 'Visible', 'on');

%Handle to image contrast toolbar
hContrast = imcontrast(imageRegion);




%Structure to hold all user manipulable objects on the gui
userG = graphicsHandle(param, numScans, numColor, imageRegion);

%%%%%%%%%%%%%%%%%%%%%% Callback Functions


%%%%% Drop down menu callback
    function keyPressGUI(hObject, eventdata)
        eventdata.Key
        switch eventdata.Key
            case 'rightarrow'
                %Go one scan forward
                scanNum = get(hScanSlider, 'Value');
                scanNum = int16(scanNum);
                
                if(scanNum<maxScan)
                    scanNum = scanNum+1;
                end
                
                %Update the displayed z level.
                set(hScanTextEdit, 'String', scanNum);
                set(hScanSlider, 'Value', scanNum);
                scanSlider_Callback('', '');
                
            case 'leftarrow'
                %Go one scan backward
                %Go one scan forward
                scanNum = get(hScanSlider, 'Value');
                scanNum = int16(scanNum);
                
                if(scanNum>minScan)
                    scanNum = scanNum-1;
                end
                
                %Update the displayed z level.
                set(hScanTextEdit, 'String', scanNum);
                set(hScanSlider, 'Value', scanNum);
                scanSlider_Callback('', '');
                
            case 'downarrow'
                %Go one z-depth up
                zNum = get(hZSlider, 'Value');
                
                zIncr = str2num(get(hMenuChangeVariableZStep, 'Tag'));
                if(zNum<zMax-zIncr)
                    zNum = zNum+zIncr;
                    ['this']
                elseif(zNum>=xMax-zIncr);
                    zNum = zNum+1;
                   
                    ['that']
                end
                  [zNum zIncr]
                zNum = int16(zNum);

                %Update the displayed z level.
                set(hZTextEdit, 'String', zNum);
                set(hZSlider, 'Value',double(zNum));

                z_Callback('','');
            case 'uparrow'
                %Go one z-depth down
                %Go one z-depth up
                zNum = get(hZSlider, 'Value');
                
                
                zIncr = str2num(get(hMenuChangeVariableZStep, 'Tag'));
                
                if(zNum>zMin+zIncr)
                    zNum = zNum-zIncr;
                elseif(zNum<=zMin+zIncr);
                    zNum = zNum-1;
                end
                [zNum zIncr]
                zNum = int16(zNum);

                %Update the displayed z level.
                set(hZTextEdit, 'String', zNum);
                set(hZSlider, 'Value',double(zNum));

                z_Callback('','');
                
            case 't'
               updateManualThresholdValues();
               
            case 'n'
                %Create a new gut clump cropping box
                outlineClump_Callback('','');
                
            case 'c'
                %Add new clump removal button
                removeThisClump_Callback('','');
        end
        
    end
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
        set(hIm, 'YData', [1 param.regionExtent.regImSize(1)]);

        initMag = apiScroll.findFitMag();
        apiScroll.setMagnification(initMag);
        
        
        outlineRegions(); %Outline the different regions that make up the composite region.
        
        fprintf(2, 'Done!\n');
    end


    function saveImage_Callback(hObject, eventdata)

        [filename, pathname, fIndex] = uiputfile('.tif', 'Save the displayed scan.',...
            [param.directoryName filesep 'temp.tif']);
        if isequal(filename,0) || isequal(pathname,0)
            disp('User pressed cancel-image will not be saved')
        else
            disp(['Saving image in the file ', fullfile(pathname, filename)])
                im = getRegisteredImage(scanNum, color, zNum, im, data, param);
        %Optionally denoise image
        if strcmp(get(hMenuDenoise, 'Checked'),'on')
            im = denoiseImage(im);
        end
        
            imwrite(uint16(im), strcat(pathname,filename), 'tiff');
        end
        
              
    end

    function saveParam_Callback(hObject, eventdata)
       %Function to save the param file that's created in the course of this analysis.
       %This is done in other function calls, but not with a directory of
       %your choice...currently this will only be used to create a script
       %for cropping images.
       if(isfield(param, 'dataSaveDirectory'))
           [fileName, saveDir]  = uiputfile('*.mat', 'Select a location to save the param.mat file', [param.dataSaveDirectory filesep 'param.mat']);
       else
           [fileName, saveDir]  = uiputfile('*.mat', 'Select a location to save the param.mat file', [param.directoryName filesep 'param.mat']);
       end
       if(fileName==0)
           return
       end
       %Save the result to the param file associated with the data.
       saveFile = [saveDir fileName];
       
       %Remove the last backspace
       saveDir = saveDir(1:end-1);
       %Update param.dataSaveDirectory to where we are saving param
       param.dataSaveDirectory = saveDir;
       save(saveFile, 'param');
      
       %Save the fish file (containing analysis stuff) also to the same
       %directory
       saveFishFile = [saveDir filesep 'fishAnalysis.mat'];
       save(saveFishFile, 'f');
       
    end
    function loadFishAnalysis_Callback(~, ~)
       fileName = [param.dataSaveDirectory filesep 'fishAnalysis.mat'];
       if(exist(fileName, 'file')==2)
          inputVar = load(fileName);
          f = inputVar.f
       else
           fprintf(1, 'No fish analysis class saved yet!\n');
       end
        
    end
    function changeKeystroke_Callback(hObject, eventdata)
        answer = inputdlg('Change z-increment value', '',1, {num2str(zIncr)});
        
        zIncr = num2str(answer{1});
    end

    function saveWindowLocation_Calback(hObject, eventdata)
        
       S = which('multipleRegionCrop.m');
       S = [S(1:end-20) 'windowLocation.mat'];
       
       windowPos = get(fGui, 'Position');
       
       save(S, 'windowPos');
       
    end


    function saveScan_Callback(hObject, eventdata)
        prompt = {'Scan range: initial', 'Scan range: final',...
            'Z depth: initial', 'Z depth: final'};
        name = 'Set range of scans to save-currently saves both colors';
        defaultAnswer = {num2str(scanNum), num2str(scanNum), num2str(zNum), num2str(zNum)};
        numLines = 1;
        answer = inputdlg(prompt, name, numLines, defaultAnswer);
        
        if isempty(answer)
            disp('User pressed cancel-image stack will not be saved')
            return
        end
        
        %Unpacking results
        scanMin = str2num(answer{1});
        scanMax = str2num(answer{2});
        zMin = str2num(answer{3});
        zMax = str2num(answer{4});
        
        dirName = uigetdir(param.directoryName, 'Save location');
        if isequal(dirName,0)
            disp('User pressed cancel-image stack will not be saved')
            return
        end
        
        disp(['Saving image stack in the directory ', dirName]);
        
        imBig = zeros(param.regionExtent.regImSize{1}(1), param.regionExtent.regImSize{1}(2));
        
        for scanNum = scanMin:scanMax
            scanDir = strcat(dirName, filesep, 'scan_', num2str(scanNum));
            mkdir(scanDir);          
            for c = minColor:maxColor  
                color = colorType(c);
                color = color{1};
                colorDir = strcat(scanDir, filesep,color);
                mkdir(colorDir);
                disp(strcat('Saving color ', color));
                
                imNum=0;
                for zStackN=zMin:zMax
                    im = getRegisteredImage(scanNum, color, zStackN, imBig, data, param);
                    filename = strcat('pco', num2str(imNum), '.tif');
                    
                    imwrite(im, strcat(colorDir, filesep,filename), 'tiff');
                    fprintf(2,'.');
                    imNum = imNum+1;
                end
                fprintf('\n');
            end    
        end
        
    end

%Adjust the contrast of the images.
    function adjustContrast_Callback(hObject, eventdata)
            hContrast = imcontrast(imageRegion);

    end

    function mip_Callback(hObject, eventdata)
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        imBig = zeros(param.regionExtent.regImSize{colorNum}(1), param.regionExtent.regImSize{colorNum}(2));
        for zStackN=zMin:zMax-5
            imOut = getRegisteredImage(scanNum, color, zStackN, imBig, data, param);
            index = find(imOut>imBig);
            imBig(index) = imOut(index);
            fprintf('.');
        end
        fprintf('\n');
        set(hIm, 'CData', imBig); 
    end
    function overlapColors_Callback(hObject, eventdata)
        %Use a check mark to indicate whether we'll align or not
        if strcmp(get(hMenuOverlapImages, 'Checked'),'on')
            set(hMenuOverlapImages, 'Checked', 'off');
        else
            set(hMenuOverlapImages, 'Checked', 'on');
        end
 
    end
    function changeVarZ_Callback(hObject, eventdata)
        prompt = 'Change variable z step size';
        name = 'Variable z';
        numlines = 1;
        defaultanswer = {num2str(multiZSliceMax)};
        answer = inputdlg(prompt, name, numlines, defaultanswer);
        multiZSliceMax = str2num(answer{1});
        zStepSmall = multiZSliceMax/(zMax-zMin);
        set(hZSlider, 'SliderStep', [zStepSmall, zStepBig]);
        set(hMenuChangeVariableZStep, 'Tag', num2str(multiZSliceMax+1));
    end


    function showSegmentation_Callback(hObject, eventdata)
        
        if strcmp(get(hMenuShowSegmentation, 'Checked'),'on')
            set(hMenuShowSegmentation, 'Checked', 'off');
        else
            set(hMenuShowSegmentation, 'Checked', 'on');
        end
    end

    function showCoarseResults_Callback(hObject, eventdata)
       if(strcmp(get(hMenuShowFoundCoarseRegions, 'Checked'), 'on'))
           set(hMenuShowFoundCoarseRegions, 'Checked', 'off');
       else
           set(hMenuShowFoundCoarseRegions, 'Checked', 'on');
       end
        
    end

    function setSegmentation_Callback(hObject, eventdata)
        [selection, ok] = listdlg('SelectionMode', 'single',...
            'ListString', segmentationType.List,...
            'PromptString', 'Choose segmentation type');
        segmentationType.Selection = segmentationType.List{selection};
        
        if(strcmp(segmentationType.Selection, 'estimated background'))
            name = 'Background offset value to use';
            numlines = 1;
            defaultanswer = {'1.8'};
             answer=inputdlg(name,name,numlines,defaultanswer);
           segmentationType.bkgOffset = str2num(answer{1});  
        end
    end


    function displaySegmentation(scanNum, colorNum, segmentationType, f)
        
        

            poly = param.regionExtent.polyAll{scanNum};
            cL = param.centerLineAll{scanNum};
            
            height = param.regionExtent.regImSize{1}(1);
            width = param.regionExtent.regImSize{1}(2);
            
            gutMask = poly2mask(poly(:,1), poly(:,2), height,width);
            imSeg = im; imSeg(~gutMask) = NaN;
            segMask = segmentGutMIP(imSeg, segmentationType, scanNum, colorNum, param,f);
            maskFeat.Type = 'perim';
            maskFeat.seSize = 5;
            
            hRem = findobj('Tag', 'segMask');
            delete(hRem);
            
            %rgbIm = maskClass.showMask(segmask, 'perim', 5);
            
            rgbIm = segmentRegionShowMask(segMask, maskFeat);
            hAlpha = alphamask(rgbIm, [1 0 0], 0.5, imageRegion);
            set(hAlpha, 'Tag', 'segMask');
            
    end
    function addSpots_Callback(hObject, eventdata)
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        if strcmp(get(hMenuSpot, 'Checked'),'on')
            set(hMenuSpot, 'Checked', 'off');
            
        else
            set(hMenuSpot, 'Checked', 'on');
            
            spotSaveDir = [param.dataSaveDirectory filesep 'manualSpotSelection'];
            if(~isdir(spotSaveDir))
                mkdir(spotSaveDir);
            end
            spotSaveFile = [spotSaveDir filesep 'spotSelectionList.mat'];
            if(exist(spotSaveFile)==2)
               inputVar = load(spotSaveFile);
               spotList = inputVar.spotList;
            end 
            
            while(strcmp(get(hMenuSpot, 'Checked'), 'on'))
                hSpotSelect = impoint(imageRegion);
                position = wait(hSpotSelect);
                spotList{scanNum, colorNum} = [spotList{scanNum, colorNum}; position];
                delete(hSpotSelect);
                displayFoundSpots()
            end
        end
        
    end

    function  displayFoundSpots()
         scanNum = get(hScanSlider, 'Value');
         scanNum = int16(scanNum);
         
         colorNum = get(hColorSlider, 'Value');
         colorNum = ceil(colorNum);
         colorNum = int16(colorNum);
         
         if(isempty(hManualSpotPlot))
             hold on
             hManualSpotPlot = plot(1,1 ,'o', 'Color', [0.8 0.4 0.2]);
             hold off
         end
         
         
         
         if(isempty(spotList{scanNum, colorNum}))
             set(hManualSpotPlot, 'XData', []);
             set(hManualSpotPlot, 'YData', []);             
         else
             set(hManualSpotPlot, 'XData', spotList{scanNum, colorNum}(:,1)); 
             set(hManualSpotPlot, 'YData', spotList{scanNum, colorNum}(:,2));
         end
        
    end

    function saveSpots_Callback(hObject, eventdata)
            spotSaveDir = [param.dataSaveDirectory filesep 'manualSpotSelection'];
            spotSaveFile = [spotSaveDir filesep 'spotSelectionList.mat'];
        
            save(spotSaveFile, 'spotList');
            fprintf(1, 'Spot list saved!\n');
            beep
    end

    function removeLastSpots_Callback(hObject, eventdata)
        
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        %Remove the last spot in the list of spots we found for this scan
        %and color
        
        spotList{scanNum, colorNum} = spotList{scanNum, colorNum}(1:end-1,:);
        displayFoundSpots();
    end

    function removeClump_Callback(hObject, eventdata)
        if(strcmp(get(hMenuRemoveClump, 'Checked'), 'on'))
            set(hMenuRemoveClump, 'Checked', 'off');
        else
            set(hMenuRemoveClump, 'Checked', 'on');
            
            %Create structure for storing data
            newVal = true; %Click on different clumps for each time point
            userG = newHandleList(userG, 'clumpRemove', 'point',newVal, 'fishClass');
            
        end
            
    end

    function removeThisClump_Callback(hObject, eventdata)
        %Remove a new clump from the image
        [scanNum, colorNum] = getScanAndColor();
        userG = newObject(userG, 'clumpRemove', scanNum, colorNum);
        userG = userG.saveG(scanNum, colorNum);

        [f, ~] = updateField(userG, f, param, scanNum, colorNum);
        
        displaySegmentation(scanNum, colorNum, segmentationType, f);
        
    end

    function loadClump_Callback(hObject, eventdata)
       fprintf(1, 'Loading in clumps data.');
        f= f.getClumps;
        fprintf(1, '.succesful!\n');
    end

    function overlapBugs_Callback(hObject, eventdata)
       
        if strcmp(get(hMenuOverlapBugs, 'Checked'),'on')
            set(hMenuOverlapBugs, 'Checked', 'off');
            overlapBugs = false;
           
            if(~isempty(hP))
                for i=1:3
                    set(hP{i}, 'XData', []);
                    set(hP{i}, 'YData', []);
                end
            end
        else
            set(hMenuOverlapBugs, 'Checked', 'on');
            overlapBugs = true;
            
            scanNum = get(hScanSlider, 'Value');
            scanNum = int16(scanNum);
            color = colorType(colorNum);
            color = color{1};
            getRegisteredImage(scanNum, color, zNum, im, data, param);
        end      
    end

    function overlapBugOptions_Callback(hObject, eventdata)
       
        
    end

    function findBugZLocation        

        rProp = load([param.dataSaveDirectory filesep 'singleBacCount'...
            filesep 'bacCount' num2str(scanNum) '.mat']);
        rProp = rProp.rProp;
        
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        if(strcmp(get(hMenuOverlapImages, 'Checked'), 'on'))
            rPropComb = rProp{1};
            for i=1:length(rProp{2});
                rPropComb(end+1) = rProp{2}(i);
            end
        elseif(iscell(rProp))
            if(length(rProp)==1)
                %Not greatest way to deal with this since we'll have image
                %overlaps on both channels...oh well.
                
                rProp = rProp{1};
            else
                rProp = rProp{colorNum};
            end
        end
        
        %Find the z location of all the bugs
        [xyz, ~, ~,~] = getBugList(rProp);

        %Give a nice bit of space around each bug
        zSubsetList = round(xyz(3,:));
        zSubsetList = sort(unique(zSubsetList));
        zSubsetList(zSubsetList>zMax) = [];
        zSubsetList(zSubsetList<zMin) = [];
        
        
    end

    function removeBugs_Callback(hObject, eventdata)
        %Until unchecked produce rectangles that the user can place down on
        %the image. All bacteria in the box are turned pink.
        if strcmp(get(hMenuRemoveBugs, 'Checked'),'on')
            removeBugs = false;
            set(hMenuRemoveBugs, 'Checked','off');
            hRemBug = findobj('Tag', 'removeBug');
            delete(hRemBug);
        else
            removeBugs = true;
            set(hMenuRemoveBugs, 'Checked', 'on');
            
            while(strcmp(get(hMenuRemoveBugs, 'Checked'),'on'))
                hRemBug = imrect(imageRegion);
                set(hRemBug, 'Tag', 'removeBug');
                
                %position = wait(hRemBug);
                pause(0.5);
                hRemBugAPI =iptgetapi(hRemBug);
                
                position = hRemBugAPI.getPosition();
                
                delete(hRemBug)
                drawnow;
                removeBugBox(position)
            end
        end
    end

    function useSaveRemBug_Callback(hObject, eventdata)
       %Check box indicates whether in getBugList(rProp) we will
       %exclusively use the list of removed bugs that are saved in
       %gutOutline/singleBacCount or if we will use the list in
       %multipleRegionCrop that's updated by the user while removing false
       %positive spots.
        if(strcmp(get(hMenuUseSavedRemBugList, 'Checked'), 'on'))
          set(hMenuUseSavedRemBugList, 'Checked', 'off'); 
       else
           set(hMenuUseSavedRemBugList, 'Checked', 'on')
       end
    end

    function keepBugs_Callback(hObject, eventdata)
         %Until unchecked produce rectangles that the user can place down on
        %the image. All bacteria in the box are turned pink.
        if strcmp(get(hMenuKeepBugs, 'Checked'),'on')
            keepBugs = false;
            set(hMenuKeepBugs, 'Checked','off');
            hKeepBug = findobj('Tag', 'keepBug');
            delete(hKeepBug);
        else
            keepBugs = true;
            set(hMenuKeepBugs, 'Checked', 'on');
            
            while(strcmp(get(hMenuKeepBugs, 'Checked'),'on'))
                hKeepBug = imrect(imageRegion);
                set(hKeepBug, 'Tag', 'keepBug');
                
                %position = wait(hRemBug);
                pause(0.5);
                hKeepBugAPI =iptgetapi(hKeepBug);
                
                position = hKeepBugAPI.getPosition();
                
                delete(hKeepBug)
                drawnow;
                keepBugBox(position)
            end
        end
    end

    function saveRemovedBugs_Callback(hObject, eventdata)
        remBugsSaveDir = [param.dataSaveDirectory filesep 'singleBacCount' filesep 'removedBugs.mat'];
        save(remBugsSaveDir, 'removeBugInd', 'keepBugInd');
        fprintf(1, 'List of bugs removed (or kept) saved!\n');
      
    end
    function showAllBugs_Callback(hObject, eventdata)
        if strcmp(get(hMenuShowAllBugs, 'Checked'),'on')
            set(hMenuShowAllBugs, 'Checked','off');
        else
            set(hMenuShowAllBugs, 'Checked', 'on');
            set(hMenuOverlapBugs, 'Checked', 'on');
            
            overlapBugs_Callback();
        end
        
    end


    function variableZ_Callback(hObject, eventdata)
        if(strcmp(get(hMenuVariableZ, 'Checked'), 'on'))
            set(hMenuVariableZ, 'Checked', 'off');
            useSubsetZList = false;
        else
            set(hMenuVariableZ, 'Checked', 'on');
            useSubsetZList = true;
            findBugZLocation();
        end
    end

    function manualThresh_Callback(hObject, eventdata)
       
        
        if(strcmp(get(hMenuManualParticleThresh, 'Checked'), 'on'))
            set(hMenuManualParticleThresh, 'Checked', 'off');
            useManualParticleThresh = false;
        else
            set(hMenuManualParticleThresh, 'Checked', 'on');
            useManualParticleThresh = true;
        end
        
    end
    function changeManualThresh_Callback(hObject, eventdata)
       updateManualThresholdValues(); 
    end
    function updateManualThresholdValues()
        %Set the manual threshold for this scan and color
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        prompt = {'Minimum intensity','Minimum area'};
        name = 'Manual thresholding for particles';
        numlines = 1;
        defaultanswer = {num2str(manualParticleThresh(scanNum, colorNum,1)), ...
            num2str(manualParticleThresh(scanNum, colorNum,2))};
        answer = inputdlg(prompt, name, numlines, defaultanswer);
        manualParticleThresh(scanNum, colorNum,1) = str2num(answer{1});
        manualParticleThresh(scanNum, colorNum,2) = str2num(answer{2});
        
        removeBugBox('')
    end


    function removeBugBox(position)
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        color = colorType(colorNum);
        color = color{1};
        
        zNum = get(hZSlider, 'Value');
        zNum = int16(zNum);
        
        %Apply a user defined harsh threshold for all bacteria, different
        %for different scan numbers and intensities
        if(useManualParticleThresh==true)
           intenThresh = manualParticleThresh(scanNum, colorNum,1);
           sizeThresh = manualParticleThresh(scanNum, colorNum,2);
           indI = find([rProp.CentroidOrig]<intenThresh);
           indA = find([rProp.Area]<sizeThresh);
           
           indAll = union(indI, indA);
       
           if(isempty(position))
               removeBugInd{scanNum,colorNum} =  unique([removeBugInd{scanNum, colorNum} ,indAll]);
               %Remove these bugs from the list of z-depths to go to.
               findBugZLocation();
               displayOverlappedBugs()
               return;
           end
            xyz = [rProp.CentroidOrig];
            xyz = reshape(xyz,3,length(xyz)/3);
            
        else
            
            xyz = [rProp.CentroidOrig];
            xyz = reshape(xyz,3,length(xyz)/3);
        end
        bugWindow = 1;
        indAll = findBugsBox(position, xyz);
        %If looking at the MIP then remove all bugs in the entire z-stack.
        switch projectionType
            case 'mip'
                %Do nothing further to the list.
            case 'none'
                loc = -1*(xyz(3,:)<zNum-bugWindow) + (xyz(3,:)>zNum+bugWindow);
                indZ = find(loc==0);
                
                indAll = intersect(indAll, indZ);
            case 'multiZSlice'
                loc = -1*(xyz(3,:)<zNum-bugWindow) + (xyz(3,:)>zNum+bugWindow+multiZSliceMax);
                indZ = find(loc==0);
                
                indAll = intersect(indAll, indZ);
        end
      
        removeBugInd{scanNum, colorNum} =  [removeBugInd{scanNum, colorNum} ,indAll];
        
        
        %Remove these bugs from the list of z-depths to go to.
        findBugZLocation();
        
        getRegisteredImage(scanNum, color, zNum, im, data, param);
        
    end

    function keepBugBox(position)
        %Option to pick bugs to keep instead of remove-useful if we have
        %very few bugs and lots of background signal.
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        color = colorType(colorNum);
        color = color{1};
        
        zNum = get(hZSlider, 'Value');
        zNum = int16(zNum);
        
        xyz = [rProp.CentroidOrig];
        xyz = reshape(xyz,3,length(xyz)/3);
        
        indAll = findBugsBox(position, xyz);
        bugWindow = 1;
        %If looking at the MIP then remove all bugs in the entire z-stack.
        switch projectionType
            case 'mip'
                %Do nothing further to the list.
            case 'none'
                loc = -1*(xyz(3,:)<zNum-bugWindow) + (xyz(3,:)>zNum+bugWindow);
                indZ = find(loc==0);
                
                indAll = intersect(indAll, indZ);
            case 'multiZSlice'
                loc = -1*(xyz(3,:)<zNum-bugWindow) + (xyz(3,:)>zNum+bugWindow+multiZSliceMax);
                indZ = find(loc==0);
                
                indAll = intersect(indAll, indZ);
        end
      
        keepBugInd{scanNum, colorNum} =  [keepBugInd{scanNum, colorNum} ,indAll];
        
        keepBugInd{scanNum, colorNum}
          
        %Remove these bugs from the list of z-depths to go to.
        findBugZLocation();
        
        getRegisteredImage(scanNum, color, zNum, im, data, param);
    end

    function ind = findBugsBox(position, xyz)
               
        xMin = position(1); xMax = position(1) + position(3);
        yMin = position(2); yMax = position(2) + position(4);
        
        indX = find((xyz(1,:)>xMin) + (xyz(1,:)<xMax) ==2);
        indY = find((xyz(2,:)>yMin) + (xyz(2,:)<yMax) ==2);
        
        ind = intersect(indX, indY); 
    end



    function displayOverlappedBugs()
        rProp = load([param.dataSaveDirectory filesep 'singleBacCount'...
            filesep 'bacCount' num2str(scanNum) '.mat']);
        rProp = rProp.rProp;
        
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
      
        if(strcmp(get(hMenuOverlapImages, 'Checked'), 'on'))
            rPropComb = rProp{1};
            for i=1:length(rProp{2});
                rPropComb(end+1) = rProp{2}(i);
            end
        elseif(iscell(rProp))
            if(length(rProp)==1)
                %Not greatest way to deal with this since we'll have image
                %overlaps on both channels...oh well.
                
                rProp = rProp{1};
            else
                rProp = rProp{colorNum};
            end
        end
             
        if(isempty(hP{1}))
            hold on
            
            hP{1} = plot(1,1 ,'o', 'Color', [0.8 0.4 0.2]);
            hP{2} = plot(1,1,'o', 'Color', [0.3 0.7 0.4]);
            hP{3} = plot(1,1, 'o', 'Color', [0.4 0.5 0.9]);
            
            %Handle to bugs that we've declared to be mislabeled
            hP{4} = plot(1,1,'o', 'Color',[1 110/255 180/255]); 	
            hold off
            
        end
        
        [xyz, xyzRem, xyzKept,rPropClassified] = getBugList(rProp);
        disp(['Total num:'  num2str(sum([rPropClassified.gutRegion]<5))])
        switch projectionType
            case 'mip'
               
                %ind = setdiff(1:size(xyz,2), keptSpots);
                %Set all bug outlines to be one color
                set(hP{1}, 'XData', xyz(1,:));
                set(hP{1}, 'YData', xyz(2,:));
                
                set(hP{2}, 'XData',[]);
                set(hP{2}, 'YData', []);
                set(hP{3}, 'XData', []);
                set(hP{3}, 'YData', []);
                
                %Remove spots that were manually removed
                set(hP{4}, 'XData', []);
                set(hP{4}, 'YData', []);
                
                
                if(~isempty(keepBugInd{scanNum, colorNum}))
                    %Use same color for removed and kept bugs, depending on
                    %what we do.
                    locData{4} = xyzKept;
                    
                    set(hP{4},'XData', locData{4}(1,:));
                    set(hP{4}, 'YData', locData{4}(2,:));
                    
                    set(hP{1}, 'XData', []);
                    set(hP{1}, 'YData', []);
                end
                
                
            case 'none'
                
                bugWindow = 1;
                loc = -1*(xyz(3,:)<zNum-bugWindow) + (xyz(3,:)>zNum+bugWindow);
                
                showBugsZ=true;
                if(showBugsZ==true)
                    %Only display bacteria in the ~ vicinity of the found
                    %z-location.
                    loc(loc~=0) = 2;
                end
                
                locData{1} = xyz(:,loc==-1);
                locData{2} = xyz(:,loc==0);
                locData{3} = xyz(:, loc==1);
                
                for i=1:3
                    set(hP{i},'XData', locData{i}(1,:));
                    set(hP{i}, 'YData', locData{i}(2,:));
                end
                if(~isempty(removeBugInd))
                    
                    remLoc = -1*(xyzRem(3,:)<zNum-bugWindow) + (xyzRem(3,:)>zNum+bugWindow);
                    locData{4} = xyzRem(:,remLoc==0);
                    
                    set(hP{4},'XData', locData{4}(1,:));
                    set(hP{4}, 'YData', locData{4}(2,:));
                end
                
                if(~isempty(keepBugInd))
                    %Use same color for removed and kept bugs, depending on
                    %what we do.
                    remLoc = -1*(xyzKept(3,:)<zNum-bugWindow) + (xyzKept(3,:)>zNum+bugWindow);
                    locData{4} = xyzKept(:,remLoc==0);
                    
                    set(hP{4},'XData', locData{4}(1,:));
                    set(hP{4}, 'YData', locData{4}(2,:));
                end
            case 'multiZSlice'
                 bugWindow = 1;
                 %Only difference between this code and the code for 'none'
                 %is that the window now extends up to bugWindow +
                 %multiZSliceMax
                loc = -1*(xyz(3,:)<zNum-bugWindow) + (xyz(3,:)>zNum+bugWindow+multiZSliceMax);
  
                showBugsZ=true;
                if(showBugsZ==true)
                    %Only display bacteria in the ~ vicinity of the found
                    %z-location.
                    loc(loc~=0) = 2;
                end
                
                locData{1} = xyz(:,loc==-1);
                locData{2} = xyz(:,loc==0);
                locData{3} = xyz(:, loc==1);
                locData{2}(3,:)
                for i=1:3
                    set(hP{i},'XData', locData{i}(1,:));
                    set(hP{i}, 'YData', locData{i}(2,:));
                end
                if(~isempty(removeBugInd))
                    
                    remLoc = -1*(xyzRem(3,:)<zNum-bugWindow) + (xyzRem(3,:)>zNum+bugWindow+multiZSliceMax);
                    locData{4} = xyzRem(:,remLoc==0);
                    
                    set(hP{4},'XData', locData{4}(1,:));
                    set(hP{4}, 'YData', locData{4}(2,:));
                end
                
                if(~isempty(keepBugInd))
                    %Use same color for removed and kept bugs, depending on
                    %what we do.
                    remLoc = -1*(xyzKept(3,:)<zNum-bugWindow) + (xyzKept(3,:)>zNum+bugWindow+multiZSliceMax);
                    locData{4} = xyzKept(:,remLoc==0);
                    
                    set(hP{4},'XData', locData{4}(1,:));
                    set(hP{4}, 'YData', locData{4}(2,:));
                end
                
                
        end
        
    end

    function [xyz, xyzRem,  xyzKept,rPropClassified] = getBugList(rProp)
        
        xyzKeptInd = keepBugInd{scanNum, colorNum};
        xyzKept = [rProp.CentroidOrig];
        xyzKept = reshape(xyzKept,3,length(xyzKept)/3);
        xyzKept = xyzKept(:, xyzKeptInd);
        
        %Remove spots that were manually segmented.
        keptSpots = setdiff(1:length(rProp), removeBugInd{scanNum, colorNum});
        
        %Construct list of removed spots
        xyzRem = [rProp.CentroidOrig];
        
        xyzRem = reshape(xyzRem,3,length(xyzRem)/3);
        
        xyzRem = xyzRem(:,removeBugInd{scanNum,colorNum});

        if(strcmp(get(hMenuUseSavedRemBugList, 'Checked'), 'on'))
            useRemovedBugList = true;
            rPropClassified = rProp;
        else
            rPropClassified = rProp(keptSpots);
            useRemovedBugList = false;
        end

        classifierType = 'svm';
        
        %Let's filter out all points with an intensity below 200
        % rPropClassified =  rPropClassified([rPropClassified.MeanIntensity]>200);
        %rPropClassified = rPropClassified([rPropClassified.Area]>40);
        
        switch get(hMenuShowAllBugs, 'Checked')
            case 'off'
                %Use the filter that we've built to further classify the
                %data
                distCutoff_combRegions = false;
                rPropClassified = bacteriaCountFilter(rPropClassified, scanNum, colorNum, param, useRemovedBugList, classifierType,distCutoff_combRegions);
                %rPropClassified
                %keptSpots = intersect(keptSpots, [rProp.ind]);
                
            case 'on'
                %Apply some harsh-ish threshold-Set this threshold in
                %bacteriaCountFilter.
                %for now.distCutoff_combRegions = false;
                %  classifierType = 'none';
                % distCutoff_combRegions = false;
                
                %rPropClassified = bacteriaCountFilter(rPropClassified, scanNum, colorNum, param, useRemovedBugList, classifierType,distCutoff_combRegions);
                
                colorThresh = [0,0];
                areaThresh = [3,3];
                classifierType = 'none_plusAutoFluor';
              
                
                distCutoff_combRegions = false;

                rPropClassified = bacteriaCountFilter(rPropClassified, scanNum, colorNum, param, useRemovedBugList, classifierType,distCutoff_combRegions);
                
                
              %  rPropClassified = rPropClassified([rPropClassified.Area]>areaThresh(colorNum));
                
               % rPropClassified = rPropClassified([rPropClassified.MeanIntensity]>colorThresh(colorNum));
                
                
        end
        
        xyz = [rPropClassified.CentroidOrig];
        xyz = reshape(xyz,3,length(xyz)/3);
        
        %keptSpots = logical(keptSpots.*(~outsideGut));
        %xyz = xyz(:, keptSpots);
        
        
    end


    function denoiseIm_Callback(hObject, eventdata)
        
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
               apiScroll.setMagnification(0.6);
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
        
        thisColor = get(hColorSlider, 'Value');
        thisColor = ceil(thisColor);
        thisColor = int16(thisColor);
        
        
        for numReg = 1:totalNumRegions
            x = param.regionExtent.XY{thisColor}(numReg, 2);
            y = param.regionExtent.XY{thisColor}(numReg, 1);
            width = param.regionExtent.XY{thisColor}(numReg, 4);
            height = param.regionExtent.XY{thisColor}(numReg,3);
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
        set(hZSlider, 'Max', size(param.regionExtent.Z,1));
        zNum = get(hZSlider, 'Value');
        zNum = int16(zNum);
         if(zNum>size(param.regionExtent.Z,1))
             zNum = size(param.regionExtent.Z,1);
             set(hZTextEdit, 'String', num2str(zNum));
             set(hZSlider, 'Value', double(zNum));
         end
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        %Display the new image
        color = colorType(colorNum);
        color = color{1};
        
        
        %Remove the previous outline regions
        hOutRect = findobj('Tag', 'outlineRect');
        delete(hOutRect);
        %Remove the cropping rectangles.
        hRect = findobj('Tag', 'imrect');
        delete(hRect);
        im = zeros(param.regionExtent.regImSize{colorNum}(1), param.regionExtent.regImSize{colorNum}(2));
        color = colorType(colorNum);
        color = color{1};
        getRegisteredImage(scanNum, color, zNum, im, data, param )
        outlineRegions();
        
        myhandles.param = param;
        guidata(fGui, myhandles);
    
        dataTable = [];
        for i=1:length(param.color)
            thisColorData = [param.regionExtent.XY{i}(:, 1:2); param.regionExtent.regImSize{i}];
            dataTable = [dataTable,thisColorData];
        end
        set(hxyRegTable, 'Data', dataTable);
        
        
        
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


    function quickZCrop_Callback(hObject, eventdata)
       isChecked = get(hQuickZ, 'Checked');
       switch isChecked
           case 'off'
               set(hQuickZ, 'Checked', 'on');
           case 'on'
               set(hQuickZ, 'Checked', 'off');
               return;
       end
       
        
        %Quickly crop image stacks in the z-direction
       
       
       %Set mousecallback so that when you click on the different regions
       %with the left or right mouse you change the z-level for that region
       
       %Remove z-number and color button-we don't want to have control of
       %these while we do z-cropping
       set(imageRegion, 'HandleVisibility', 'on');
       
       set(hZText, 'Visible', 'off');
       set(hZTextEdit, 'Visible', 'off');
       set(hZSlider, 'Visible', 'off');
       
       set(hColorText, 'Visible', 'off');
       set(hColorTextEdit, 'Visible', 'off');
       set(hColorSlider, 'Visible', 'off');
       
%        set(outlineRect(:), 'Visible', 'off');
%        set(hIm, 'Visible', 'off');       
       
       %Create 6 new axes in the image panel that we'll use to crop the
       %images
%        
%        imZ{1,1} = axes('Parent', hImPanel, 'Position', [0 0  0.5 0.3], 'XTick', [], 'YTick', []);
%        imZ{1,2} = axes('Parent', hImPanel, 'Position', [0 0.33  0.5 0.3], 'XTick', [], 'YTick', []);
%        imZ{1,3} = axes('Parent', hImPanel, 'Position', [0 0.7  0.5 0.3], 'XTick', [], 'YTick', []);
%        
%        imZ{2,1} = axes('Parent', hImPanel, 'Position', [0.5 0  0.5 0.3], 'XTick', [], 'YTick', []);
%        imZ{2,2} = axes('Parent', hImPanel, 'Position', [0.5 0.33  0.5 0.3], 'XTick', [], 'YTick', []);
%        imZ{2,3} = axes('Parent', hImPanel, 'Position', [0.5 0.70  0.5 0.3], 'XTick', [], 'YTick', []);
      
       %Tags to the axes so that we can individually manipulate them
%        set(imZ{1,1}, 'Tag', 'quick11');
%        set(imZ{1,2}, 'Tag', 'quick12');
%        set(imZ{1,3}, 'Tag', 'quick13');
%        
%        set(imZ{2,1}, 'Tag', 'quick21');
%        set(imZ{2,2}, 'Tag', 'quick22');
%        set(imZ{2,3}, 'Tag', 'quick23');

       %Loading in entire image stack in both colors
       totalNumColors = size(param.color,2);

       imAll = cell(totalNumColors, totalNumRegions);
       fprintf(1, 'Loading in all images');
       for nC=1:totalNumColors
           for nR=1:totalNumRegions
               imVar.color = param.color{nC};
               imVar.zNum = '';
               imVar.scanNum = scanNum;
               imAll{nC, nR} = load3dVolume(param, imVar, 'single', nR);
               fprintf(1, '.');
           end
       end
       fprintf(1,'Done!\n');

       %Displaying the MIP for both colors
        
       for nC=1:totalNumColors
           for nR=1:totalNumRegions
           [imAllmip{nC,nR,1}, imAllmip{nC,nR,2}] = max(imAll{nC,nR},[],3);
           end
       end
       
       im = registerSingleImage(imAllmip, param.color{1},param)+ registerSingleImage(imAllmip, param.color{2},param);
       set(hIm, 'CData', im);
           
               %imZmip{nC,i} = imshow(im,[0,2000],'Parent', imZ{nC,i});
               %set callbacks for each of these images
               set(hIm, 'ButtonDownFcn', @varZCrop_Callback);
               
               %set(imZmip{nC,i}, 'Tag', ['mip_',num2str(nC), '_', num2str(i)]);
       
       
    end

%Crop the zebrafish gut in the z-direction. The user is prompted to put
%down lines along the gut at different z-heights. Everything to the right
%of that line will not be used in getting the volume of the gut. This
%exploits the feature of most of our samples where the bulb is higher in
%the z-direction than the other parts of the gut. For samples where this is
%not the case we will have to use a different strategy.
    function heightZCrop_Callback(hObject, eventdata)
        isChecked = get(hQuickZ, 'Checked');
        switch isChecked
            case 'off'
                set(hQuickZ, 'Checked', 'on');
            case 'on'
                set(hQuickZ, 'Checked', 'off');
                return;
        end
        %Set the callback for when the image is clicked on.
        set(hIm, 'ButtonDownFcn', @varZCrop_Callback);
        
    end

    function cropBoxInit_Callback(hobject, eventdata)
        %Open up a timer object-we'll use this to update the z-cropping
        %rectangles as we go.
        prevtimer = timerfind('tag', 'zCropTimer');
        delete(prevtimer);
       if(isempty(zCropBoxHandle))
           zCropBoxHandle{1}(1) = imrect(imageRegion);
       else
           zCropBoxHandle{end+1}(1) = imrect(imageRegion);
       end
       
       set(zCropBoxHandle{end}(1), 'Tag', 'zCropBoxHandle');
       addNewPositionCallback(zCropBoxHandle{end}(1), @(p)updateCropBox);
       
       T = timer('ExecutionMode', 'fixedDelay', 'Tag', 'zCropTimer',...
           'TimerFcn', @updateCropBox, 'Period', 1);
       start(T);
    end

    function updateCropBox(~,~)
        
        zNum = get(hZSlider, 'Value');
        zNum = int16(zNum);
        
        for nB=1:length(zCropBoxHandle)
            h = iptgetapi(zCropBoxHandle{nB}(1));
            zCropBox{scanNumPrev,nB}{1} = zCropBoxHandle{nB}(1);
            %zCropBox{scanNumPrev,nB}{2} = h.getPosition();%Filler for now-we'll set this when we go to a new scan
            thisBoxColor = h.getColor();
            
            %If the color is green or red, then set this height to be the
            %top or bottom of the cropping window.
            greenColor = [0.2824 0.9725 0.2824];
            redColor = [0.9725 0.3098 0.3098];
            
            if(sum(abs(thisBoxColor-greenColor))<0.01)
                zCropBox{scanNumPrev,nB}{3} = 'top';
                zCropBox{scanNumPrev,nB}{4} = zNum;
                
                %Then set to be a color slightly different so that we don't
                %update zNum unless we've picked a different z-height
                h.setColor(greenColor - [0.1 0 0]);
            elseif(sum(abs(thisBoxColor-redColor))<0.01)
                zCropBox{scanNumPrev,nB}{3} = 'bottom';
                zCropBox{scanNumPrev,nB}{4} = zNum;
                h.setColor(redColor - [0.1 0 0]);
            end
        
            %Depending on where we are in the z-height set the color to be
            %blue or yellow depending on if we're inside or outside the
            %cropping region
            if(length(zCropBox{scanNumPrev,nB})<3)
              %Then declare this to be a top region until we've said
              %otherwise
              zCropBox{scanNumPrev, nB}{3} = 'top';
              zCropBox{scanNumPrev, nB}{4} = zNum;
            end
            
            zCutoff = zCropBox{scanNumPrev,nB}{4};
            switch zCropBox{scanNumPrev,nB}{3}
                case 'top'
                    if(zNum>zCutoff)
                        h.setColor([1 1 0]); %set color to yellow
                    elseif(zNum<zCutoff)
                        h.setColor([0 0 1]);
                    else
                        h.setColor(greenColor - [0.1 0 0]);
                    end
                case 'bottom'
                    if(zNum<zCutoff)
                        h.setColor([1 1 0]); %set color to yellow
                    elseif(zNum>zCutoff)
                        h.setColor([0 0 1]);
                    else
                        h.setColor(redColor - [0.1 0 0]);
                    end
                    
                otherwise
                    fprintf(2, 'Yikes! Something went wrong in updateCropBox()');
            end
                        
            zCropBox{scanNumPrev,nB}{5} = h.getColor();

            %If the color of the box is red, crop towards the bottom of the
            %z-stack. If the color
            
%             if(nB==2)
% 
%               [sum(zCropBox{1,nB}{2}), sum(zCropBox{2,nB}{2}), sum(zCropBox{3,nB}{2})]
%             end
        end
        
    end

    function updateCropBoxPosition(thisScanNum)
        
        for nB=1:size(zCropBoxHandle,2)
            h = iptgetapi(zCropBoxHandle{nB}(1));
            zCropBox{thisScanNum,nB}{2} = h.getPosition();
            
            %Set the next scan box, if empty, to have all the same features
            %of the previous box.
            if(isempty(zCropBox{scanNum, nB}))
                zCropBox{scanNum,nB} = zCropBox{thisScanNum,nB};
            end
            %Also save the result to the param file for later use in
            %cropping the image stack
            param.regionExtent.zCropBox{thisScanNum}{nB} =...
                zCropBox{thisScanNum,nB};
        end
       
    end

    function updateCropBoxNewScan()
        cropTimer = timerfind('tag', 'zCropTimer');
        stop(cropTimer);
        
        updateCropBoxPosition(scanNumPrev);
        
        for nB=1:size(zCropBoxHandle,2)

            h = iptgetapi(zCropBoxHandle{nB}(1));
        
            if(isempty(zCropBox{scanNum,nB})||nB>size(zCropBox,2))
                continue
            else
                h.setPosition(zCropBox{scanNum,nB}{2});
                
                if(length(zCropBox{scanNum,nB})>=5)
                    h.setColor(zCropBox{scanNum,nB}{5});
                end
            end
        end
        
        start(cropTimer);        
    end

    function im = removeZCroppedRegions(im)
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
       for nB=1:size(zCropBoxHandle,2)
           thisPos = zCropBox{scanNumPrev,nB}{2};
           thisPos = round(thisPos);
          

           zList = param.regionExtent.Z;
           zCutoff = zCropBox{scanNumPrev,nB}{4};
           %Remove all z heights that are not within the cropping region
           switch zCropBox{scanNumPrev, nB}{3}
               case 'top'
                   zList(zCutoff:end,:) = -1;
               case 'bottom'
                   zList(1:zCutoff,:) = -1;
           end
           paramTemp = param;
           paramTemp.regionExtent.Z = zList;
           
           imVar.color ={param.color{colorNum}};imVar.scanNum= scanNumPrev;
           thisIm = load3dVolume(paramTemp, imVar, 'crop', thisPos);
           thisIm = max(thisIm,[],3);
           im(thisPos(2):thisPos(2)+thisPos(4), thisPos(1):thisPos(1)+thisPos(3))=...
               thisIm;
       end
        
    end

    function cropBoxMeas_Callback(hObject, eventdata)
        zCropBoxHandle = findobj('Tag', 'zCropBoxHandle');
        apiTemp = iptgetapi(zCropBoxHandle);
        zCropBox{scanNum}(end+1).pos = apiTemp.getPosition();
        zCropBox{scanNum}(end).zHeight = int16(get(hZSlider, 'Value'));

        delete(zCropBoxHandle);
        param.regionExtent.zCropBox = zCropBox;
    end

    function saveCropped_Callback(hObject, eventdata)
    %Function to save the cropped region. Either to a new directory,
    %or overwriting the previous images. This function will also save all
    %the metadata associated withthe new cropped region (i.e. pixel
    %location of each region).
    
    prompt = {'Save the cropped region to a new directory (1) or overwrite the existing directory structure (2)?',...
        'Save as TIFF (1) or PNG (2)?'};
    
     dlg_title = 'Saving cropped images';
     num_lines = 1;
     def = {'1','1'};
     answer = inputdlg(prompt,dlg_title,num_lines,def);

     totalNumScans = param.expData.totalNumberScans;
     totalNumColors = size(param.color,2);
    
     switch answer{1}
         
         case '1'
             %Save to a new directory structure
             %directory = uigetdir(param.saveLocation);
             cropDir = uigetdir(pwd, 'Pick a location to save the images to');
             
             %Now duplicate the directory structure that the orignal set of
             %scans had. Should include some more error handling here.
             
         case '2'
             %Overwrite the previous directory structure
             cropDir = param.directoryName; %Check to make sure that this is the right syntax.
         otherwise
            disp('Location input must be either 1 or 2!');
            return
            
     end
     
     switch answer{2}
         case '1'
             fileType = 'tiff';
         case '2'
             fileType = 'png';
         otherwise
            disp('File type input must be either 1 or 2!');
            return
     end
     
     %Run a script to crop these images.
     saveCroppedBatch(param, cropDir, fileType, 'xy');

     
    end


    function singleCrop_Callback(hObject, eventData)
        if strcmp(get(gcbo, 'Checked'), 'off')
            set(gcbo, 'Checked', 'on');
            %Only add crop box if there isn't one there
            h = imrect(imageRegion);
            
            position = wait(h);
            param.regionExtent.singleCrop = position;
            set(h, 'Tag', 'largeCropRegion');
            
            %Crop the image down to this size
            param.regionExtent.singleCrop = round(position);
            
            getRegisteredImage(scanNum, color, zNum, im, data, param)
          
            set(hIm, 'XData', [1 param.regionExtent.singleCrop(3)]);
            set(hIm, 'YData', [1 param.regionExtent.singleCrop(4)]);
            
            initMag = apiScroll.findFitMag();
            apiScroll.setMagnification(initMag);
            
            
            
            %Remove other boxes...
            
            %Remove cropping box and restore the original image.
            cropRect = findobj('Tag', 'largeCropRegion');
            delete(cropRect);
            
            %Remove the outline rectangles
            hRect = findobj('Tag', 'outlineRect');
            delete(hRect);
            set(hMenuBoundBox, 'Label', 'Add region bounding boxes');
            
            
        else
            %Remove cropping box and restore the original image.
            cropRect = findobj('Tag', 'largeCropRegion');
            delete(cropRect);
            set(gcbo, 'Checked', 'off');
            
            
            %Add region bounding boxes.
            outlineRegions();
            set(hMenuBoundBox, 'Label', 'Remove region bounding boxes');
            %Restore the original image
            param.regionExtent.singleCrop = '';
            
            getRegisteredImage(scanNum, color, zNum, im, data, param)

            set(hIm, 'XData', [1 param.regionExtent.regImSize(2)]);
            set(hIm, 'YData', [1 param.regionExtent.regImSize(1)]);

            
            initMag = apiScroll.findFitMag();
            apiScroll.setMagnification(initMag);
        end
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

    function getImageArray_Callback(hObject, eventdata)
        if(strcmp(get(hMenuRegisterManual, 'Checked'), 'on'))
            set(hMenuRegisterManual, 'Checked', 'off');
            
            set(hxyRegTable, 'Visible', 'off');
            set(hMenuAlternateRegions, 'Visible', 'off');
            
        else
            set(hMenuRegisterManual, 'Checked', 'on');
            getIndividualRegions();
            % manualRegisterImage_Callback('','');
            set(hxyRegTable, 'Visible', 'on');
            set(hMenuAlternateRegions, 'Visible', 'on');
            
            tableData = get(hxyRegTable, 'Data');
            %Increase size of image in x direction
            for i=1:size(tableData,2)/2
                tableData(end,2*(i-1)+1) = round(1.5*tableData(end,2*(i-1)+1));
            end
            set(hxyRegTable, 'Data', tableData);
            manualRegisterImage_Callback('','');
        end
        
    end

    function setMinImageSize_Callback(hObject, eventdata)
        numColor = length(param.color);
        
        for i=1:numColor
            thisColor = param.regionExtent.XY{i};
            
            cMinX(i) = min(thisColor(:,1));
            cMinY(i) = min(thisColor(:,2));
            
            cMaxX(i) = max(thisColor(:,1)+thisColor(:,3));
            cMaxY(i) = max(thisColor(:,2) + thisColor(:,4));
            
        end
        minX = min(cMinX);
        minY = min(cMinY);
        maxX = max(cMaxX);
        maxY = max(cMaxY);
        
       for i=1:numColor
        param.regionExtent.regImSize{i} = [maxX-minX+1 maxY-minY+1];
        param.regionExtent.XY{i}(:,1) = param.regionExtent.XY{i}(:,1)-minX+1;
        param.regionExtent.XY{i}(:,2) = param.regionExtent.XY{i}(:,2)-minY+1;
       end
        

       regDataTable = [];
       for i=1:length(param.color)
           thisColorData = [param.regionExtent.XY{i}(:, 1:2); param.regionExtent.regImSize{i}];
           regDataTable = [regDataTable,thisColorData];
       end
       set(hxyRegTable, 'Data', regDataTable);
       
       [~,param] = registerImagesXYData('overlap', data,param);
       set(imageRegion, 'YLim', [1 param.regionExtent.regImSize{1}(1)]);
       set(imageRegion, 'XLim', [1 param.regionExtent.regImSize{1}(2)]);
       
       im = zeros(param.regionExtent.regImSize{1});
       im = registerSingleImage(scanNum,color, zNum,im, data,param);
       set(hIm, 'CData', im);
       if(~isempty(hContrast))
           hContrast = imcontrast(imageRegion);    
       end
       %Draw the bounding boxes again
       hRect = findobj('Tag', 'outlineRect');
       if(~isempty(hRect))
           delete(hRect);
           outlineRegions();
       end
        %Display the new image
        color = colorType(colorNum);
        color = color{1};
        getRegisteredImage(scanNum, color, zNum, im, data, param);
    end

    function saveRegisterGlobalOffset_Callback(hObject, eventdata)
       %Load in current value

       S = which('registerImagesXYData.m');
       S = [S(1:end-22) 'globalOffset.mat'];
       inputVar = load(S);
       globalOffsetX = inputVar.globalOffsetX;
       
        answer =inputdlg('Set the new global offset in the image registration', '', 1, {num2str(globalOffsetX)});
       answer = answer{1}; answer = str2num(answer);
       
       globalOffsetX = answer;
       
       save(S, 'globalOffsetX');
        
    end

%%% Functions for doing removal of surface cells
    function segSurface_Callback(hObject, eventdata)
         isChecked = get(hMenuSeg, 'Checked');

       
       
        thisIm = get(hIm, 'CData');
        threshIm = zeros(size(thisIm,1), size(thisIm,2),3);
        threshIm(:,:,3) =thisIm>500;
        threshIm = double(threshIm);
        hold on
        hThresh = imshow(threshIm, 'Parent', imageRegion);
        
        trans = 0.8;
        set(hThresh, 'AlphaData', trans*threshIm(:,:,3));
        
        hold off
        
         switch isChecked
           case 'off'
               set(hMenuSeg, 'Checked', 'on');
               
               set(hThresh, 'ButtonDownFcn', @segSurfaceClick_Callback);

           case 'on'
               set(hMenuSeg, 'Checked', 'off');
               if(ishandle(hThresh))
                   set(hThresh, 'AlphaData', 0);
                  
               end
              
                set(hThresh, 'Visible', 'off');
                drawnow;
         end
       
         
    end

    function background_Callback(hObject, eventdata)
        if strcmp(get(hMenuBkg, 'Checked'),'on')
            set(hMenuBkg, 'Checked', 'off');
            hTemp = findobj('Tag', 'bkgRect');
            delete(hTemp);
        else
            set(hMenuBkg, 'Checked', 'on');    
            bkgRect = imrect(imageRegion);
            set(bkgRect, 'Tag', 'bkgRect');
            addNewPositionCallback(bkgRect, @(p)updateBkgPosition);
            
        end
    end

    function updateBkgPosition()
        

        %Get color and scan number
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        %Update the mean and std. dev of the background pixel values.
        bkgHandle = findobj('Tag', 'bkgRect');
        
        bkgHandle = iptgetapi(bkgHandle);
        bkgPos = bkgHandle.getPosition();
        allIm = get(hIm, 'CData');
        bkgPos = round(bkgPos);
        allIm = allIm(bkgPos(2):bkgPos(2)+bkgPos(4), bkgPos(1):bkgPos(1)+bkgPos(3));
        %bkgInten(scanNum,colorNum,1) = mean(allIm(:));
        %bkgInten(scanNum, colorNum,2) = std(double(allIm(:)));
        bkgInten{scanNum,colorNum} = bkgPos;
        %Load in this cropped region and calculate features of it
        imVar.color = {param.color{colorNum}}; imVar.scanNum = scanNum;
        % thisIm = load3dVolume(param, imVar, 'crop', bkgPos);
        %NO!!!!!NO!!! Don't calculate the mean of mip-get the position of
        %this rect. and get the mean of the z-stack instead.
        param.bkgIntenAll = bkgInten; %Keep record of background intensity in different scans to see if it change
        
        %Update mean and std of total bkg intensity
        meanVal = param.bkgIntenAll(:,colorNum,1);
        param.bkgInten(colorNum,1) = nanmean(meanVal);
        
        stdVal = param.bkgIntenAll(:,colorNum,2);
        param.bkgInten(colorNum,2) = nanmean(stdVal);
   
    end

    function outlineBacteria_Callback(hObject, eventdata)
         if strcmp(get(hMenuBacteria, 'Checked'),'on')
            set(hMenuBacteria, 'Checked', 'off');
            hTemp = findobj('Tag', 'bkgRect');
            delete(hTemp);
        else
            set(hMenuBacteria, 'Checked', 'on');    
            bacRect = imrect(imageRegion);
            set(bacRect, 'Tag', 'bkgRect');
            bacPos = wait(bacRect);
            
            answer = inputdlg('How many bacteria are in this box?', 'Bacteria count', ...
                1, {'1'});
            numBact = str2num(answer{1});
            
            delete(bacRect);
            
            scanNum = get(hScanSlider, 'Value');
            scanNum = int16(scanNum);
            
            colorNum = get(hColorSlider, 'Value');
            colorNum = ceil(colorNum);
            colorNum = int16(colorNum);
           
            %Load in this cropped region and calculate features of it
            
            %Calculate the mean and total pixel intensity values for a
            %variety of cutoffs above
            
            cutPoint = 1:10;
%            cutoff = param.bkgInten(colorNum,1)+cutPoint*param.bkgInten(colorNum,2);
            
            bacInten{scanNum,colorNum}(end+1).rect = bacPos;
            
%             meanVal = arrayfun(@(x)mean(double(thisIm(thisIm>cutoff(x)))), cutPoint, 'UniformOutput', false);
%             bacInten{scanNum,colorNum}(end).mean = cell2mat(meanVal);
%             
%             stdVal = arrayfun(@(x)std(double(thisIm(thisIm>cutoff(x)))), cutPoint, 'UniformOutput', false);
%             bacInten{scanNum,colorNum}(end).std = cell2mat(stdVal);
%             
%             sumVal = arrayfun(@(x)sum(sum(thisIm(thisIm>cutoff(x))))/numBact, cutPoint, 'UniformOutput', false);
%             bacInten{scanNum,colorNum}(end).sum = sumVal;
            bacInten{scanNum, colorNum}(end).numBac = numBact;
            
            param.bacInten = bacInten;
            
            set(hMenuBacteria, 'Checked', 'off');

         end
        
         
    end

    function camBackground_Callback(hObject, eventdata)
        bkgRect = imrect(imageRegion);
        bkgPos = wait(bkgRect);
        
        delete(bkgRect);
        
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        imVar.scanNum = scanNum;
        %Load in images of the background and its mean/std
        for nC=1:length(param.color);
            imVar.color = {param.color{nC}};
            thisIm = load3dVolume(param, imVar, 'crop', bkgPos);
            camBkg(nC).mean = mean(double(thisIm(:)));
            camBkg(nC).std = std(double(thisIm(:)));
            camBkg(nC).color = imVar.color;
        end
        param.camBkg = camBkg;
    end

    function endGut_Callback(hObject, eventdata)
        if strcmp(get(hMenuEndGut, 'Checked'),'on')
            set(hMenuEndGut, 'Checked', 'off');
            hTemp = findobj('Tag', 'endGutPt');
            delete(hTemp);
        else
            set(hMenuEndGut, 'Checked', 'on');
            endGutPt = impoint(imageRegion);
            set(endGutPt, 'Tag', 'endGutPt'); 
            setColor(endGutPt, 'r');
            updateEndGutPosition();
           % addNewPositionCallback(endGutPt, @(p)updateEndGutPosition);

        end
         
    end

    function beginGut_Callback(hObject, eventdata)
        if strcmp(get(hObject, 'Checked'),'on')
            set(hObject, 'Checked', 'off');
            hTemp = findobj('Tag', 'beginGutPt');
            delete(hTemp);
        else
            set(hObject, 'Checked', 'on');
            beginGutPt = impoint(imageRegion);
            set(beginGutPt, 'Tag', 'beginGutPt');
            setColor(beginGutPt, 'y');
            updateGutBeginPosition();
            %addNewPositionCallback(beginGutPt, @(p)updateGutBeginPosition);
            
        end
    end

    function endBulb_Callback(hObject, eventdata)
        if strcmp(get(hObject, 'Checked'),'on')
            set(hObject, 'Checked', 'off');
            hTemp = findobj('Tag', 'endBulbPt');
            delete(hTemp);
        else
            set(hObject, 'Checked', 'on');
            beginGutPt = impoint(imageRegion);
            set(beginGutPt, 'Tag', 'endBulbPt');
            setColor(beginGutPt, [0.8 0.4 0.2]);
            updateEndBulbPosition();
           % addNewPositionCallback(beginGutPt, @(p)updateEndBulbPosition);
            
            updateGutBeginPosition();
        end
    end

    function autoFluorGut_Callback(hObject, eventdata)
        if strcmp(get(hMenuAutoFluorGut, 'Checked'),'on')
            set(hMenuAutoFluorGut, 'Checked', 'off');
            hTemp = findobj('Tag', 'autoFluorPt');
            delete(hTemp);
        else
            set(hMenuAutoFluorGut, 'Checked', 'on');
            autoFluorPt = impoint(imageRegion);
            set(autoFluorPt, 'Tag', 'autoFluorPt');
            setColor(autoFluorPt, 'b');
            updateAutoFluorPosition();
            %addNewPositionCallback(autoFluorPt, @(p)updateAutoFluorPosition);

        end 
    end
        
    function autoFluorEnd_Callback(hObject, eventdata)
        if strcmp(get(hMenuEndAutoFluorGut, 'Checked'),'on')
            set(hMenuEndAutoFluorGut, 'Checked', 'off');
            hTemp = findobj('Tag', 'autoFluorEndPt');
            delete(hTemp);
        else
            set(hMenuEndAutoFluorGut, 'Checked', 'on');
            autoFluorEndPt = impoint(imageRegion);
            set(autoFluorEndPt, 'Tag', 'autoFluorEndPt');
            setColor(autoFluorEndPt, [0.3 0.2 0.5]);
            updateAutoFluorEndPosition();
            %addNewPositionCallback(autoFluorPt, @(p)updateAutoFluorPosition);

        end
        
    end

    function updateAutoFluorPosition()
        autoFluorHandle = findobj('Tag', 'autoFluorPt');

        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        autoFluorHandle = iptgetapi(autoFluorHandle);
        autoFluorPos = autoFluorHandle.getPosition();
        param.autoFluorPos(scanNumPrev,:) = autoFluorPos;
        
        if(sum(param.autoFluorPos(scanNum,:))~=0)
            autoFluorHandle.setPosition(param.autoFluorPos(scanNum,:));
        end
    end

    function updateAutoFluorEndPosition()
        autoFluorHandle = findobj('Tag', 'autoFluorEndPt');

        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        autoFluorHandle = iptgetapi(autoFluorHandle);
        autoFluorPos = autoFluorHandle.getPosition();
        param.autoFluorEndPos(scanNumPrev,:) = autoFluorPos;
        
        if(sum(param.autoFluorEndPos(scanNum,:))~=0)
            autoFluorHandle.setPosition(param.autoFluorEndPos(scanNum,:));
        end
    end

    function updateGutBeginPosition()        
        beginGutHandle = findobj('Tag', 'beginGutPt');

        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        beginGutHandle = iptgetapi(beginGutHandle);
        beginGutPos = beginGutHandle.getPosition();
        param.beginGutPos(scanNumPrev,:) = beginGutPos;
        
        if(sum(param.beginGutPos(scanNum,:))~=0)
            beginGutHandle.setPosition(param.beginGutPos(scanNum,:));
        end
    end


    function updateEndGutPosition()
        endGutHandle = findobj('Tag', 'endGutPt');
        
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        endGutHandle = iptgetapi(endGutHandle);
        endGutPos = endGutHandle.getPosition();
        param.endGutPos(scanNumPrev,:) = endGutPos;
        
        
        if(sum(param.endGutPos(scanNum,:))~=0)
            endGutHandle.setPosition(param.endGutPos(scanNum,:));
        end
%         endGutPos = param.endGutPos;
%         if(scanNum>size(endGutPos,1))
%             changePos = false;
%         elseif(sum(endGutPos(scanNum,:))==0)
%             changePos = false;
%         else
%             changePos = true;
%         end
%         
%         if(changePos==true)
%             endGutHandle.setPosition([endGutPos(scanNum,1), endGutPos(scanNum,2)]);
%         end
    end

    function updateEndBulbPosition()
        endBulbHandle = findobj('tag', 'endBulbPt');
        
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        endBulbHandle = iptgetapi(endBulbHandle);
        endBulbPos = endBulbHandle.getPosition();
        param.endBulbPos(scanNumPrev,:) = endBulbPos;
        
        if(sum(param.endBulbPos(scanNum,:))~=0)
            endBulbHandle.setPosition(param.endBulbPos(scanNum,:));
        end
            
    end

    function segSurfaceClick_Callback(~, ~)
        
        pos =  get(gca, 'Currentpoint'); pos = pos(1,1:2);
        allInd = cellfun(@isempty, surfaceCell);
        
        if(isempty(allInd))
            ind = 1;
        elseif(size(allInd,1)~=scanNum)
            ind = 1;
        else
            ind = find(allInd(scanNum,:)==1, 1,'first');
            if(isempty(ind))
                %Lengthen the cell array
                ind = size(allInd,2) +1;
            end
        end
        surfaceCell{scanNum,ind}.pos = pos;
        
        %Find which region in the image this overlaps with and set that to
        %a different color
        obj = bwselect(threshIm(:,:,3), pos(1), pos(2));
        %Remove the object from the potential segmented region and add it
        %to the to-be segmented regions
        threshIm(:,:,3)= threshIm(:,:,3)- obj;
        threshIm(:,:,1) = threshIm(:,:,1) + obj;
        set(hThresh, 'CData', threshIm);
        
        %Find which regions this point is in
        overlap = zeros(totalNumRegions,2);
        for nR=1:totalNumRegions
            %x position
            regOverlap(nR,1,1) = param.regionExtent.XY{colorNum}(nR,1);
            regOverlap(nR,1,2) = regOverlap(nR,1,1)+param.regionExtent.XY{colorNum}(nR,3);
            
            %y position
            regOverlap(nR,2,1) = param.regionExtent.XY{colorNum}(nR,2);
            regOverlap(nR,2,2) = regOverlap(nR,2,1)+param.regionExtent.XY{colorNum}(nR,4);
            
            
            %See if the position that we clicked on is in the range of one of
            %these regions.
            if(surfaceCell{scanNum,ind}.pos(2)>regOverlap(nR,1,1) &&...
                    surfaceCell{scanNum,ind}.pos(2)<regOverlap(nR,1,2))
                overlap(nR,1) = 1;
            end
            
            if(surfaceCell{scanNum,ind}.pos(1)>regOverlap(nR,2,1) &&...
                    surfaceCell{scanNum,ind}.pos(1)<regOverlap(nR,2,2))
                overlap(nR,2) = 1;
            end
        end
        
        %Save a list of all the regions that are in the region clicked on. If we
        %clicked outside of all regions then don't update anything
        
        overlap = sum(overlap,2);
        surfaceCell{scanNum,ind}.region = find(overlap==2, length(overlap));
        
        if(length(find(overlap==2))>0)
            %Update the axes ticks to show where we put down a marker
            minY = 1;
            maxY = size(get(gcbo, 'CData'),1);
            yArr = minY:1:maxY;
            
            
            %Find the position in the different region where we clicked
            %on the image
            for j=1:length(find(overlap==2))
                thisR = surfaceCell{scanNum,ind}.region(j,1);
                surfaceCell{scanNum,ind}.region(j,2) = surfaceCell{scanNum,ind}.pos(2)-regOverlap(thisR,1,1);
                surfaceCell{scanNum,ind}.region(j,3) = surfaceCell{scanNum,ind}.pos(1)-regOverlap(thisR,2,1);
                
            end
            
            
        else
            surfaceCell{scanNum,ind} = [];
            return
            
        end
        
        
        %Update the entry in param
        param.surfaceCell = surfaceCell;
    end

    function getIndividualRegions()


        if(~isfield(param.expData, 'saveScan')||strcmp(param.expData.saveScan, 'true'))
            imNum = param.regionExtent.Z(zNum,:);
            saveScan = 'true';
        else
            saveScan = 'false';
        end
            
        
        %Load in the associated images
        
        baseDir = [param.directoryName filesep 'Scans' filesep];
        %Going through each scan
        scanDir = [baseDir, 'scan_', num2str(scanNum), filesep];
        
        numColor = length(param.color);
        
        %Filling the input image with zeros, to be safe.
        imC = zeros(size(im,1),size(im,2),2);
        imC(:) = 0;
        
        imC = uint16(imC); %To match the input type of the images.
        
        for cN=1:numColor
            
            for regNum=1:totalNumRegions
                
                %Get the range of pixels that we will read from and read out to.
                xOutI = param.regionExtent.XY{cN}(regNum,1);
                xOutF = param.regionExtent.XY{cN}(regNum,3)+xOutI-1;
                
                yOutI = param.regionExtent.XY{cN}(regNum,2);
                yOutF = param.regionExtent.XY{cN}(regNum,4)+yOutI -1;
                
                xInI = param.regionExtent.XY{cN}(regNum,5);
                xInF = xOutF - xOutI +xInI;
                
                yInI = param.regionExtent.XY{cN}(regNum,6);
                yInF = yOutF - yOutI +yInI;
                
                switch saveScan
                    
                    case 'true'
                        %Full scan has been saved-load this ind
                        
                        if(imNum(regNum)~=-1)
                            imFileName = ...
                                strcat(scanDir,  'region_', num2str(regNum),filesep,...
                                color, filesep,'pco', num2str(imNum(regNum)),'.tif');
                            
                            imArray{cN,regNum} = imread(imFileName,...
                                'PixelRegion', {[xInI xInF], [yInI yInF]});
                            
                        else
                            imArray{cN,regNum} = zeros(xInF-xInI+1, yInF-yInI+1);
                        end
                        
                        %Also update imC
                        if(imNum(regNum)~=-1)
                            whichC = mod(regNum, 2)+1;
                            imC(xOutI:xOutF,yOutI:yOutF,whichC) = ...
                                imArray{cN,regNum} + ...
                                imC(xOutI:xOutF,yOutI:yOutF,whichC);
                            
                        end
                        
                    case 'false'
                        %Load in just the MIP
                        imFileName = strcat('mip', color, '_R',num2str(regNum), '_nS', num2str(scanNum));
                        imArray{cN,regNum} = imread(imFileName,...
                            'PixelRegion', {[xInI xInF], [yInI yInF]});
                        
                        %Also update imC
                        whichC = mod(regNum,2)+1;
                        imC(xOutI:xOutF, yOutI:yOutF, whichC) = ...
                            imArray{cN,regNum} + ...
                            imC(xOutI:xOutF,yOutI:yOutF,whichC);
                end

                
            end
            
        end
         
        
        
    end

    function alternateRegions_Callback(hObject, eventdata)
        %Update image contrast
        hContrast = findobj('Tag', 'imcontrast');
        conPos = get(hContrast, 'Position');
        
        if(~isempty(hContrast))
            delete(hContrast);
        end
        
        switch get(eventdata.NewValue, 'String')
            case 'Even'
                set(hIm, 'CData', imC(:,:,1));
            case 'Odd'
                set(hIm, 'CData', imC(:,:,2));
            case 'Both'
                set(hIm, 'CData', imC(:,:,1)+imC(:,:,2));
        end
        
          hContrast = imcontrast(imageRegion);
          hContrast = findobj('Tag', 'imcontrast');
          set(hContrast, 'Position', conPos);
           
    end

    function manualRegisterImage_Callback(hObject, eventdata)
        %Get values from the table and update the .regionExtent values in
        %param. Then update the displayed image.
        tableData = get(hxyRegTable, 'Data');
        
        numColor = length(param.color);
        
        %See if we've changed a color, if so change both of them.
        for j=0:numColor-1
            
            isSame = param.regionExtent.XY{j+1}(:, 1:2)==tableData(1:end-1,2*j+1:2*j+2);
            
            isSameSize = param.regionExtent.regImSize{j+1}==tableData(end,2*j+1:2*j+2);
            isSameSize = prod(double(isSameSize(:)));
            
            
            
            [changeRow,changeCol] = find(isSame==0);
            thisOffset = tableData(changeRow,numColor*j+changeCol) -...
                param.regionExtent.XY{j+1}(changeRow, changeCol);
            
            isSame = prod(double(isSame(:)));
            isSame = isSame*isSameSize;

            %Move every region after the region that was adjusted by the
            %same amount.
            
            if(isSame==0)
                changeColor = j;
                break
            end
        end
        
        %Move everything after the manually moved region by the same
        %amount
        for j=0:numColor-1
            for i=changeRow+1:size(tableData,1)-1
        
              tableData(i, changeCol+(numColor*j)) = ...
                  tableData(i,changeCol+(numColor*j))+thisOffset;
            end
        end
        
        %Update table data so that the different colors are the same
        for j=0:numColor-1
            if(j~=changeColor)
                tableData(:,2*j+1:2*j+2) = tableData(:,2*changeColor+1:2*changeColor+2);               
            end
        end
        
        %Update the table
        set(hxyRegTable, 'Data', tableData);
        
        %Update regionExtent and regImSize
        for j=0:numColor-1
           param.regionExtent.XY{j+1}(:,1:2) = tableData(1:end-1,2*j+1:2*j+2);
           param.regionExtent.regImSize{j+1} = tableData(end,2*j+1:2*j+2);
        end
        
        %Change size of displayed image if necessary
        if(isSameSize==0)
            
            hContrast = findobj('Tag', 'imcontrast');
            if(~isempty(hContrast))
                conPos = get(hContrast, 'Position');
            else
                conPas = [];
            end
            im = zeros(param.regionExtent.regImSize{j+1});
            %hIm = imshow(im,[],'Parent', imageRegion);
            
            %set(hIm, 'CData', im);
            set(imageRegion, 'YLim', [1 param.regionExtent.regImSize{j+1}(1)]);
            set(imageRegion, 'XLim', [1 param.regionExtent.regImSize{j+1}(2)]);
            if(isempty(hContrast))
                hContrast = imcontrast(imageRegion);
                if(~isempty(conPos))
                    set(hContrast, 'Position', conPos);
                end
            end
        end

        [~,param] = registerImagesXYData('overlap', data,param);
        
        if(~isfield(param.expData, 'saveScan') ||strcmp(param.expData.saveScan, 'true'))
            imNum = param.regionExtent.Z(zNum,:);
            saveScan = 'true';
        else
           saveScan = 'false'; 
        end
        %Load in the associated images
        
        %Filling the input image with zeros, to be safe.
        imC = zeros(size(im,1),size(im,2),2);
        imC(:) = 0;
        
        imC = uint16(imC); %To match the input type of the images.

        baseDir = [param.directoryName filesep 'Scans' filesep];
        %Going through each scan
        scanDir = [baseDir, 'scan_', num2str(scanNum), filesep];
        

        thisColor = get(hColorSlider, 'Value');
        thisColor = ceil(thisColor);
        thisColor = int16(thisColor);
        
        imC(:) = 0;
        
        for regNum=1:totalNumRegions    
            %Get the range of pixels that we will read from and read out to.
            xOutI = param.regionExtent.XY{thisColor}(regNum,1);
            xOutF = param.regionExtent.XY{thisColor}(regNum,3)+xOutI-1;
            
            yOutI = param.regionExtent.XY{thisColor}(regNum,2);
            yOutF = param.regionExtent.XY{thisColor}(regNum,4)+yOutI -1;
            
            xInI = param.regionExtent.XY{thisColor}(regNum,5);
            xInF = xOutF - xOutI +xInI;
            
            yInI = param.regionExtent.XY{thisColor}(regNum,6);
            yInF = yOutF - yOutI +yInI;
            
            switch saveScan
                case 'true'
                    if(imNum(regNum)~=-1)
                        whichC = mod(regNum, 2)+1;
                        imC(xOutI:xOutF,yOutI:yOutF,whichC) = ...
                            imArray{thisColor,regNum} + ...
                            imC(xOutI:xOutF,yOutI:yOutF,whichC);
                        
                    end
                
                case 'false'
                    
                    %Also update imC
                    whichC = mod(regNum,2)+1;
                    imC(xOutI:xOutF, yOutI:yOutF, whichC) = ...
                        imArray{thisColor,regNum} + ...
                        imC(xOutI:xOutF,yOutI:yOutF,whichC);
            end
            
        end
        
        if(strcmp(projectionType, 'mip'))  
            set(hIm,'CData',...
                selectProjection(param, 'mip', 'false', scanNum,color, zNum,false));
        else
            set(hIm, 'CData', imC(:,:,1)+imC(:,:,2));
        end
        %Draw the bounding boxes again
        hRect = findobj('Tag', 'outlineRect');
        if(~isempty(hRect))
            delete(hRect);
            outlineRegions();
        end
        
        %Update image contrast
        hContrast = findobj('Tag', 'imcontrast');
        conPos = get(hContrast, 'Position');
        if(~isempty(hContrast))
            delete(hContrast);
            hContrast = imcontrast(imageRegion);
            set(hContrast, 'Position', conPos);
        end
        
        
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
        
        if(~isempty(clumpOutline))
            displayClump_Callback('','');
        end
        
        userG = userG.saveG(scanNumPrev, colorNum);
        userG = userG.newG(scanNum, scanNumPrev,colorNum);
        [f, param] = updateField(userG, f, param, scanNum, colorNum);

        getRegisteredImage(scanNum, color, zNum, im, data, param);
        
        hRect = findobj('Tag', 'outlineRect');
        if(~isempty(hRect))
            delete(hRect);
            outlineRegions();
        end
        
        if(useSubsetZList ==true)
            findBugZLocation();
            
        end
    end

    function scanSlider_Callback(hObject, eventData)
        %Stop the timer for updating the crop windows before doing anything
        %else-it's acting screwy.
        cropTimer = timerfind('tag', 'zCropTimer');
        if(~isempty(cropTimer))
            stop(cropTimer);
        end
        scanTag = get(hObject, 'tag');
        if(isempty(scanTag))
            scanTag = '';
        end
        
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
            case ''
                %Do nothing-numbers already updated by key press callback
                %function
                
                
        end
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        if(~isempty(cropTimer))
            %Update the z-cropping rectangles when we go through the scan list
            updateCropBoxNewScan();
        end
        
        %%%Update, if necessary, the position of manually selected boxes
        %%%around clumps of bacteria
        if(~isempty(clumpOutline))
            displayClump_Callback('','');
        end
        %%% See if we're calculating the background intensity of the gut,
        %%% if so update the appropriate entry in param
        bkgHandle = findobj('Tag', 'bkgRect');
        if(~isempty(bkgHandle))
           updateBkgPosition();
        end
        
        %%% Check to see if the end of the gut has been labeled and if so
        %%% update param
        endGutHandle = findobj('Tag', 'endGutPt');
        if(~isempty(endGutHandle))
            updateEndGutPosition();
        end
        
        %%% Check to see if the beginning of the autofluorescent region has
        %%% been labeled and if so update param
        autoFluorHandle = findobj('Tag', 'autoFluorPt');
        if(~isempty(autoFluorHandle))
            updateAutoFluorPosition();
        end
        
        %%% Check to see if the beginning of the autofluorescent region has
        %%% been labeled and if so update param
        endBulbHandle = findobj('Tag', 'endBulbPt');
        if(~isempty(endBulbHandle))
            updateEndBulbPosition();
        end
        
        autoFluorEndHandle = findobj('Tag', 'autoFluorEndPt');
        if(~isempty(autoFluorEndHandle))
            updateAutoFluorEndPosition();
        end
        
        beginGutHandle = findobj('Tag', 'beginGutPt');
        if(~isempty(beginGutHandle))
            updateGutBeginPosition();
        end
        
        
         userG = userG.saveG(scanNumPrev, colorNum);
         userG = userG.newG(scanNum, scanNumPrev,colorNum);
         [f, param] = updateField(userG, f, param, scanNum, colorNum);

        %Display the new image
        color = colorType(colorNum);
        color = color{1};
        getRegisteredImage(scanNum, color, zNum, im, data, param);
        
        %If we're drawing a different outline & center of gut  on the gut
        %at different time points, get the new outline.
        multipleOutline = get(hMultipleOutline, 'Checked');
       
        switch multipleOutline
            case 'off'
                %Do nothing
            case 'on'
                h = findobj('Tag', 'gutOutline');
                if(~isempty(h) &&ishandle(h))
                    %Save previous outline
                    hApi = iptgetapi(h);
                    param.regionExtent.polyAll{scanNumPrev} = hApi.getPosition();
                    
                    try
                        poly = param.regionExtent.polyAll{scanNum};
                        hApi = iptgetapi(hPoly);
                        hApi.setPosition(poly);
                    catch
                        %If no gut outline exists at this time set the gut
                        %outline at ths time point to equal to previous one
                        param.regionExtent.polyAll{scanNum} =...
                            param.regionExtent.polyAll{scanNumPrev};
                    end
                
                end
                
                hLine = findobj('Tag', 'gutCenter');
                if(~isempty(hLine)&& ishandle(hLine))
                    hLine = iptgetapi(hLine);
                    param.centerLineAll{scanNumPrev} = hLine.getPosition();
                    
                    try
                        line = param.centerLineAll{scanNum};
                        if(~isempty(line))
                       hLine.setPosition(line);
                        end
                    catch
                        line = param.centerLineAll{scanNumPrev};
                        param.centerLineAll{scanNum} = param.centerLineAll{scanNumPrev};
                    end
                    
                    
                end    
                
        end
        

        scanNumPrev = scanNum;
        
        %If we're removing surface cells etc. then update this mask
       if(strcmp(get(hMenuSeg, 'Checked'), 'on'))
           threshIm(:,:,3) = get(hIm, 'CData')>700;
           threshIm(:,:,1) = 0;
           set(hThresh, 'CData', threshIm);
           set(hThresh, 'AlphaData', 0.8*sum(threshIm,3));
       end
       
       if(useSubsetZList ==true)
           findBugZLocation();
           
       end
    end

    function z_Callback(hObject, eventData)
        
        zTag = get(hObject, 'tag');
        if(isempty(zTag))
           zTag = ''; 
        end
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
            case ''
                %Do nothing-z position already updated by key press
                %callback function.
        end
         
        %If we're only going through a subset of z values. For example,
        %this is useful if we want to quickly screen a set of found
        %bacteria spots by hand.
        if(isempty(zLast))
            zLast = zNum;
        end
        if(useSubsetZList==true)
            if(~ismember(zNum, zSubsetList))
                
               switch zLast-zNum>0
                   case 1
                       %Going down in z direction
                       smallerZ = zSubsetList(zSubsetList<=zNum);
                       newzVal  = max(smallerZ);
                       if(isempty(newzVal))
                           newzVal = min(zSubsetList);
                       end
                   case 0
                       %Going up in z direction
                       largerZ = zSubsetList(zSubsetList>=zNum);
                       newzVal = min(largerZ);
                       if(isempty(newzVal))
                           newzVal = max(zSubsetList);
                       end
                       
               end
               zNum = newzVal;
            
               set(hZSlider, 'Value',double(zNum));
               set(hZTextEdit, 'String', zNum);

            end
            
            
        end
        
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        %Display the new image
        color = colorType(colorNum);
        color = color{1};
        
        %See if we're outlining the entire gut by hand
        if(strcmp(get(hMenuOutlineEntireGut, 'Checked'),'on'))
            hObj = findobj('Tag', 'entireGutOutline');
            if(~isempty(hObj))
                if(length(hObj)>1)
                    delete(hObj(2));
                    hObj = hObj(1);
                end
            hOutlineEntireGut = iptgetapi(hObj);
            entireGutOutline{scanNum, zLast} = hOutlineEntireGut.getPosition();
            
            delete(hObj);
            end
        end
        
        
        %Get the desired image and display it
        getRegisteredImage(scanNum, color, zNum, im, data, param );
                
        %Update the previous examined Z slice
        zLast = zNum;
        
        if(strcmp(get(hMenuOutlineEntireGut, 'Checked'),'on'))
            hPolyEntireGut = impoly(imageRegion);
            set(hPolyEntireGut, 'Tag', 'entireGutOutline');
            hPolyEntireGut = iptgetapi(hPolyEntireGut);
            hPolyEntireGut.setColor([0.5 0.5 0]);
        end
    end

    function projectionType_Callback(hObject, eventdata)
        
        oldValue = get(eventdata.OldValue, 'String');
        newValue = get(eventdata.NewValue, 'String');
         switch newValue
             case 'none'
                 projectionType = 'none';
             case 'mip'
                 projectionType = 'mip';
             case 'multiZSlice'
                 projectionType = 'multiZSlice';
                 zStepSmall = multiZSliceMax/(zMax-zMin);
                 set(hZSlider, 'SliderStep', [zStepSmall, zStepBig]);
                 set(hMenuChangeVariableZStep, 'Tag', num2str(multiZSliceMax+1));

         end
        
         if(~strcmp(oldValue,newValue))
             znum = get(hZSlider, 'value');
             znum = int16(znum);
              getRegisteredImage(scanNum, color, zNum, im, data, param );
         end
    end

%Callbacks for the polygon outlining of the gut
    function multipleOutline_Callback(hObject, eventdata)
        %Marker telling us to load in a new outline for each time point
        if strcmp(get(hMultipleOutline, 'Checked'),'on')
            set(hMultipleOutline, 'Checked', 'off');
        else
            set(hMultipleOutline, 'Checked', 'on');
            
        end
        
        
    end

    function createFreeHandPoly_Callback(hObject, eventdata)
        %Start drawing the boundaries!
        hPoly = impoly(imageRegion);   
        set(hPoly, 'Tag', 'gutOutline');
        hPoly = iptgetapi(hPoly);
        hPoly.setColor([0 1 0]);
        
    end


    function loadPoly_Callback(hObject, eventdata)
        multipleOutline = get(hMultipleOutline, 'Checked');
        
        switch multipleOutline
            case 'off'
                hPoly = impoly(imageRegion, param.regionExtent.poly);
            case 'on'
             
                scanNum = get(hScanSlider, 'Value');
                scanNum = int16(scanNum);
                
                if(isfield(param.regionExtent, 'polyAll')&&...
                        ~isempty(param.regionExtent.polyAll{scanNum}))
                    hPoly = impoly(imageRegion, param.regionExtent.polyAll{scanNum});
                    set(hPoly, 'Tag', 'gutOutline');
                    hPoly = iptgetapi(hPoly);
                    hPoly.setColor([0 1 0]);
                else
                    disp('The gut has not been outlined yet!');
                    beep
                end               
        end
        
    end

    function smoothPoly_Callback(hObject, eventdata)
        
        if(~isempty(hPoly))
            hApi = iptgetapi(hPoly);
            poly = hApi.getPosition();
            
            poly = splineSmoothPolygon(poly);
            
            multipleOutline = get(hMultipleOutline, 'Checked');
            
            switch multipleOutline
                case 'off'
                    param.regionExtent.poly = poly;
                case 'on'
                    scanNum = get(hScanSlider, 'Value');
                    scanNum = int16(scanNum);
                    param.regionExtent.polyAll{scanNum} = poly;
            end
            
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
        
        
        if(~isfield(param, 'dataSaveDirectory'))
           param.dataSaveDirectory = ...
               [param.directoryName filesep 'gutOutline'];
        end
        %If this directory doesn't exist then make it.
           if(~isdir(param.dataSaveDirectory))
               mkdir(param.directoryName, 'gutOutline');
           end
        %Save the result to the param file associated with the data.
        saveFile = [param.dataSaveDirectory filesep 'param.mat'];
        save(saveFile, 'param');
        disp(['Gut outline saved to the file: ', saveFile]);
    end

    function clearPoly_Callback(hObject, eventdata)
      obj = findobj('Tag', 'gutOutline'); %Delete the displayed polygon. 
      delete(obj);
    end
        
    function drawGutCenter_Callback(hObject, eventdata)
        h = impoly('Closed', false);
        
        set(h, 'Tag', 'gutCenter');
        position = wait(h);
        
        hLine = findobj('Tag', 'gutCenter');
        hLine = iptgetapi(hLine);
        hLine.setColor([1 0 0]);
        
        multipleOutline = get(hMultipleOutline, 'Checked');
        
        switch multipleOutline
            case 'off'
                param.centerLine = hLine.getPosition();
            case 'on'
                scanNum = get(hScanSlider, 'Value');
                scanNum = int16(scanNum);
                param.centerLineAll{scanNum} = hLine.getPosition();
        end
        
        myhandles.param = param;
        guidata(fGui, myhandles);
               
    end

    function smoothGutCenter_Callback(hObject, eventdata)
        hLine = findobj('Tag', 'gutCenter');
       
        line = hLine.getPosition();
        line = getCenterLine(line, 5, param);
        
        multipleOutline = get(hMultipleOutline, 'Checked');
        
        switch multipleOutline
            case 'off'
                param.centerLine =line;
            case 'on'
                scanNum = get(hScanSlider, 'Value');
                scanNum = int16(scanNum);
                param.centerLineAll{scanNum} = line;
        end

        h = impoly(imageRegion, line, 'Closed', false);
        set(h, 'Tag', 'gutCenter');
        
    end

    function saveGutCenter_Callback(hObject, eventdata)
        
        %Annoying way to get the position of the line
        hLine = findobj('Tag', 'gutCenter');
        hLine = iptgetapi(hLine);
        
        line = hLine.getPosition();
        multipleOutline = get(hMultipleOutline, 'Checked');

        switch multipleOutline
            case 'off'
                param.centerLine =line;
            case 'on'
                scanNum = get(hScanSlider, 'Value');
                scanNum = int16(scanNum);
                param.centerLineAll{scanNum} = line;
        end

        
        myhandles.param = param;
        guidata(fGui, myhandles);
        
        if(isfield(param, 'dataSaveDirectory'))
            saveFile = [param.dataSaveDirectory filesep 'param.mat'];
            save(saveFile, 'param');
        else
            prompt = ['No data save directory chosen! Choose a directory to save data from:  '...
                param.directoryName];
            folderName = uigetdir(pwd, prompt);
            if(folderName ==0)
                disp('No directory chosen-not saving param file');
                return
            else
                param.dataSaveDirectory = folderName;
                saveFile = [param.dataSaveDirectory filesep 'param.mat'];
                save(saveFile, 'param');
            end
        end
        
    end

    function clearGutCenter_Callback(hObject,eventdata)
       %Delete any lines places on the iamge
        hLine = findobj('Tag', 'gutCenter');
        if(ishandle(hLine))
            delete(hLine);
        end       
    end

    function smoothAll_Callback(hObject, eventdata)
        multipleOutline = get(hMultipleOutline, 'Checked');
        if(strcmp(multipleOutline, 'off'))
            fprintf(2, 'smoothAll_Callback: Must be assigning multiple outlines!');
            return
        end
        
        %Go through all the scans and construct a cell array of all
        %outlines and gut centers. If an outline/center hasn't been filled,
        %then set it equal to the last filled one.
        
        %Update current position of curves
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
         hLine = findobj('Tag', 'gutCenter');
        hApi = iptgetapi(hLine);
        param.centerLineAll{scanNum} = hApi.getPosition();
        
        hOutline = findobj('Tag', 'gutOutline');
        hApi = iptgetapi(hOutline);
        param.regionExtent.polyAll{scanNum} = ...
            hApi.getPosition();

        allLine = cell(maxScan-minScan+1, 1);
        allOutline = cell(maxScan-minScan+1,1);
        lastFilled = [];
        
        for nS = minScan:maxScan
            %Update the center line
            try
                allLine{nS} = param.centerLineAll{nS};
            catch
                 if(~isempty(lastFilled))
                   allLine{nS} = allLine{lastFilled};
                else
                    allLine{nS} = [];                    
                 end
            end
            if(isempty(allLine{nS}))
                allLine{nS} = allLine{lastFilled};
            end
            
            %Update the gut outline
            try
                allOutline{nS} = param.regionExtent.polyAll{nS};
            catch
                if(~isempty(lastFilled))
                    allOutline{nS} = allOutline{lastFilled};
                else
                    allOutline{nS} = [];
                end
            end
            if(isempty(allOutline{nS}))
                allOutline{nS} = allOutline{lastFilled};
            end
            
            lastFilled = nS;
            
        end
        
        %Remove double counted elements in allLine
        allLine =cellfun(@(allLine) unique(allLine, 'rows'), allLine,...
            'UniformOutput', false);
        
        allLine = cellfun(@(allLine) splineSmoothPolygon(allLine), allLine,...
            'UniformOutput', false);
        allOutline = cellfun(@(allOutline) splineSmoothPolygon(allOutline),...
            allOutline, 'UniformOutput', false);
        
        
        %Updating the entries
        param.centerLineAll = allLine;
        param.regionExtent.polyAll = allOutline;
              
        %Updating the displayed outline/center of gut
        hLine = findobj('Tag', 'gutCenter');
        hApi = iptgetapi(hLine);
        hApi.setPosition(allLine{scanNum});
        
        hOutline = findobj('Tag', 'gutOutline');
        hApi = iptgetapi(hOutline);
        hApi.setPosition(allOutline{scanNum});
        
        myhandles.param = param;
        guidata(fGui, myhandles);
      
    end

    function outlineBulbRegion_Callback(hOjbect, eventdata)
        hBulbRect = imrect(imageRegion); 
        posBulb = wait(hBulbRect);
        
        param.regionExtent.bulbRect = posBulb;
        
        hBulbApi = iptgetapi(hBulbRect);
        hBulbApi.setColor([1 0 0]);
        pause(1);
        delete(hBulbRect); clear hBulbRect
    end

    function showBulbSegmenatation_Callback(hObject, eventdata)
        %Use a check mark to indicate whether we'll align or not
        if strcmp(get(hShowBulbSeg, 'Checked'),'on')
            set(hShowBulbSeg, 'Checked', 'off');
            if(isfield(param.regionExtent, 'bulbMask'))
                showBulb = false;
            end
        else
            set(hShowBulbSeg, 'Checked', 'on');
            if(isfield(param.regionExtent, 'bulbMask'))
                showBulb = true;
            end
        end
    end

    function outlineEntireGut_Callback(hObject, eventdata)
        if strcmp(get(hMenuOutlineEntireGut, 'Checked'),'on')
            set(hMenuOutlineEntireGut, 'Checked', 'off');
            
        else
            set(hMenuOutlineEntireGut, 'Checked', 'on');
            hPolyEntireGut = impoly(imageRegion);
            set(hPolyEntireGut, 'Tag', 'entireGutOutline');
            hPolyEntireGut = iptgetapi(hPolyEntireGut);
            hPolyEntireGut.setColor([0.5 0.5 0]);
        end
        
    end


    function saveEntireGut_Callback(hObject, eventdata)
        spotSaveDir = [param.dataSaveDirectory];
        spotSaveFile = [spotSaveDir filesep 'manualGutOutlining.mat'];
        
        save(spotSaveFile, 'entireGutOutline');
        fprintf(1, 'Spot list saved!\n');
        beep
    end

    function showClumpOutline_Callback(hObject, eventdata)
        hClumpPoly = cell(maxScan, numColor);

        if(isdir([param.dataSaveDirectory filesep 'clumpOutline']))
            inputVar = load([param.dataSaveDirectory filesep 'clumpOutline' filesep 'clump.mat']);
            clumpOutline = inputVar.clumpOutline;
            %Update saved locations of all the polygons
            for nS=1:size(clumpOutline,1)
                for nC = 1:size(clumpOutline,2)
                    for i=1:length(clumpOutline{nS, nC})
                        
                        hClumpPoly{nS, nC}(i) = impoly(imageRegion, clumpOutline{nS,nC}{i});
                        
                        set(hClumpPoly{nS, nC}(i), 'Tag', 'clumpOutline');
                        hPoly = iptgetapi(hClumpPoly{nS, nC}(i));
                        hPoly.setColor([0 1 0]);
                        
                        addNewPositionCallback(hClumpPoly{nS, nC}(i), @(p)updateClumpPosition);
                        updateClumpPosition();
                    end
                end
            end
            displayClump_Callback('','');
        else
            clumpOutline = cell(maxScan, numColor);
            mkdir([param.dataSaveDirectory filesep 'clumpOutline']);
            
        end
        
    end

    function displayClump_Callback(~, ~)
        %Update which clumps are shown
        scanNum = get(hScanTextEdit, 'string');
        scanNum = str2double(scanNum);
        scanNum = int16(scanNum);
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);

        allPoly = findobj('Tag', 'clumpOutline');
        set(allPoly, 'Visible', 'off');
        for i=1:length(hClumpPoly{scanNum, colorNum})
            set(hClumpPoly{scanNum, colorNum}(i), 'Visible', 'on');
        end
        
    end

    function outlineClump_Callback(~, ~)
        
        scanNum = get(hScanTextEdit, 'string');
        scanNum = str2double(scanNum);
        scanNum = int16(scanNum);
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        if(isempty(clumpOutline{scanNum, colorNum}))
            clumpNum = 1;
        else
           clumpNum = length(clumpOutline{scanNum, colorNum})+1; 
        end
        
        hClumpPoly{scanNum, colorNum}(clumpNum) = impoly(imageRegion);
        
        set(hClumpPoly{scanNum, colorNum}(clumpNum), 'Tag', 'clumpOutline');
        hPoly = iptgetapi(hClumpPoly{scanNum, colorNum}(clumpNum));
        hPoly.setColor([0 1 0]);
        
        addNewPositionCallback(hClumpPoly{scanNum, colorNum}(clumpNum), @(p)updateClumpPosition);
        updateClumpPosition();
    end

    function [] = updateClumpPosition(~,~)
          
        scanNum = get(hScanTextEdit, 'string');
        scanNum = str2double(scanNum);
        scanNum = int16(scanNum);
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        
        for i=1:length(hClumpPoly{scanNum,colorNum})
            thisPoly = iptgetapi(hClumpPoly{scanNum, colorNum}(i));
            clumpOutline{scanNum, colorNum}{i} = thisPoly.getPosition();
        end
        
    end


        
    function clearClumpOutline_Callback(hObject, eventdata)
        scanNum = get(hScanTextEdit, 'string');
        scanNum = str2double(scanNum);
        scanNum = int16(scanNum);
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
        %Clear the last element in the array for this scan#/color
        cL = length( clumpOutline{scanNum, colorNum});
        if(cL>0)
            clumpOutline{scanNum, colorNum}(cL) = [];
        end
        %Clear the handle to this polygon
        if(~isempty(hClumpPoly{scanNum, colorNum}(cL)))
        delete(hClumpPoly{scanNum, colorNum}(cL));
        hClumpPoly{scanNum, colorNum}(cL) = [];
        end
        
    end

    function saveClumpOutline_Callback(hObject, eventdata)
        for nS=1:size(hClumpPoly,1)
            for nC = 1:size(hClumpPoly,2)
                for i=1:length(hClumpPoly{nS, nC})
                    
                    hThisClump = iptgetapi(hClumpPoly{nS, nC}(i));
                    clumpOutline{scanNum, colorNum}{i} = hThisClump.getPosition();
                end
            end
        end
        
        save([param.dataSaveDirectory filesep 'clumpOutline' filesep 'clump.mat'], 'clumpOutline');
    end


    function loadGutCenter_Callback(hObject, eventdata)
        if(isfield(param, 'centerLineAll'))
            hLine = findobj('Tag', 'gutCenter');
            delete(hLine);
            
            multipleOutline = get(hMultipleOutline, 'Checked');
            
            switch multipleOutline
                case 'off'
                    line = param.centerLine;
                case 'on'
                    scanNum = get(hScanSlider, 'Value');
                    scanNum = int16(scanNum);
                    line = param.centerLineAll{scanNum};
            end
            
            h = impoly(imageRegion, line, 'Closed', false);
            set(h, 'Tag', 'gutCenter');
            
            hLine = iptgetapi(h);
            hLine.setColor([1 0 0]);
            
        
        end
        
    end
  
%%%%%%%%%%%%%Code to initialize the display of all data
 
    function []= initializeDisplay(varargin)
        
        if nargin==0
            %Load in new parameters
            [data,param] = loadParameters;
        end
        
        %Set z values
        if(isfield(param.regionExtent, 'Z'))
            zMax = length([param.regionExtent.Z]);
        else
            zMax = zMin +1;
        end
       
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
        
        %Color map for bounding rectangles.
        cMap = rand(totalNumRegions,3);
        
        
        %Update the table for max and min z values.
        if(isfield(param.regionExtent, 'crop'))
            dataTable = param.regionExtent.crop.z;
            set(hRegTable, 'Data', dataTable);
            for i=1:totalNumRegions
                rnames{i} = i;
            end
            set(hRegTable, 'RowName', rnames);
            
        end
        

    end

    function imF = denoiseImage(im)
                 
        %Denoise the image by filtering with a gaussian filter with a sigma
        %equal to the width of the PSF
        %sigma = 0.22*wavelength/NA...I think I got all the terms right.
        hG = fspecial('Gaussian', ceil(7*0.66),0.66);
        imF = imfilter(im, hG);
        
    end

%Function to get a desired image for either display or for saving
    function varargout = getRegisteredImage(scanNum, color, zNum, im, data, param )

        %Check to see if we're going to be showing a projection instead
        switch projectionType
            case 'none'
        
                  if(strcmp(get(hMenuOverlapImages, 'Checked'), 'on'));
                     
                      im = registerSingleImage(scanNum,param.color{1}, zNum,im, data,param);
                      for nC=2:length(param.color)
                          im = im+registerSingleImage(scanNum,param.color{nC}, zNum,im, data,param);
                      end
                  else
                  
                      im = registerSingleImage(scanNum,color, zNum,im, data,param);
                      
                  end
                %Optionally denoise image
                if strcmp(get(hMenuDenoise, 'Checked'),'on')
                    im = denoiseImage(im);
                end
                %Get rid of really bright pixels. WARNING: if the image is bright
                %to begin with this will mess things up. This approach is somewhat
                %crude. What we should really be doing is in nicer fashion.
                im(im(:)>50000) = 0;
        
            case 'mip'
                 set(hIm, 'Visible', 'off');drawnow;
                param.dataSaveDirectory = [param.directoryName filesep 'gutOutline'];
                %If we're going to overlap the colors then load in all
                %colors
                
                %If we've done some z-cropping then recalculate the
                %projection.
                if(length(zCropBox)<scanNum)
                    recalcProj = false;
                else
                    if(~isempty(zCropBox{scanNum}))
                        recalcProj = true;
                    else
                        recalcProj = false;
                    end
                end
                
                if(strcmp(get(hMenuOverlapImages, 'Checked'), 'on'));
                    im = selectProjection(param, 'mip', 'true', scanNum,param.color{1}, zNum,recalcProj);
                    for nC=2:length(param.color)
                        im = im+selectProjection(param, 'mip', 'true', scanNum,param.color{nC}, zNum,recalcProj);
                    end
                    
                else
                    %'true'-> autoload the maximum intensity projection if it
                    %has already been calculated.
                    param.dataSaveDirectory = [param.directoryName filesep 'gutOutline'];
                    im = selectProjection(param, 'mip', 'true', scanNum,color, zNum,recalcProj);
                    
                end
                
                %Check to see if we're doing a z-cropping procedure. If so,
                %update the regions that we're cropping to
              %mlj: NOTE temporarilly removed to use this code for
              %calculating the background instead
                %  im = removeZCroppedRegions(im);
              
            case 'multiZSlice'
                %Display multiple z-slices on top of each other-like a
                %mini-MIP
                

                  if(strcmp(get(hMenuOverlapImages, 'Checked'), 'on'));
                      
                      im = registerSingleImage(scanNum,param.color{1}, zNum,im, data,param);
                      for nC=2:length(param.color)
                          im = im+registerSingleImage(scanNum,param.color{nC}, zNum,im, data,param);
                      end
                      for numZslices = 1:multiZSliceMax
                          nextIm = registerSingleImage(scanNum,param.color{1}, zNum+numZSlices,im, data,param);
                          for nC=2:length(param.color)
                              nextIm = im+registerSingleImage(scanNum,param.color{nC}, zNum+numZSlices,im, data,param);
                          end
                          im = max(im, nextIm);
                      end
                  else
                      im = registerSingleImage(scanNum,color, zNum,im, data,param);
                      for numZSlices = 1:multiZSliceMax
                          nextIm = registerSingleImage(scanNum,color, zNum+numZSlices,im, data,param);
                          numZSlices
                      end
                      im = max(im, nextIm);
                  
                  end
                %Optionally denoise image
                if strcmp(get(hMenuDenoise, 'Checked'),'on')
                    im = denoiseImage(im);
                end
                %Get rid of really bright pixels. WARNING: if the image is bright
                %to begin with this will mess things up. This approach is somewhat
                %crude. What we should really be doing is in nicer fashion.
                im(im(:)>50000) = 0;
                
                
        end
        
        
        if(strcmp(get(hMenuShowSegmentation, 'Checked'), 'on'))
            displaySegmentation(scanNum, colorNum, segmentationType,f);
        end
        
        if(strcmp(get(hMenuShowFoundCoarseRegions, 'Checked'), 'on'))
           inputVar = load([param.dataSaveDirectory filesep 'coarseData.mat']);
           colorNum = get(hColorSlider, 'Value');
           colorNum = ceil(colorNum);
           colorNum = int16(colorNum);
           coarseData = inputVar.coarseData{scanNum, colorNum};
           
           %Find spots that have a non-zero population and throw a solid
           %circle on the image at those points
           coarseData = coarseData(1,:)>0;
           
           cL = param.centerLineAll{scanNum};
           cL = cL(coarseData,:);
           
           p = findobj('Tag', 'coarseAnalysis');
           delete(p);
           hold on
           p = plot(cL(:,1),cL(:,2) ,'o', 'Color', [0.2 0.4 1], 'MarkerSize', 10);
           hold off
           set(p, 'Tag', 'coarseAnalysis')
           
        end
        
        %If a single crop region (not region specific crop boxes) for the
        %whole image has been selected, then crop down to this size.
        if( isfield(param.regionExtent, 'singleCrop'))
            if(~isempty(param.regionExtent.singleCrop))
                im = imcrop(im, param.regionExtent.singleCrop);
            end
        end
         
        %If we're manually registering things then also update the cell
        %structure that contains the individual regions
        if strcmp(get(hMenuRegisterManual, 'Checked'),'on')
            getIndividualRegions();
        end
        
        switch nargout
            case 0
                set(hIm, 'CData', im);
                    
            case 1
                %Used for saving potentially modified images to a new
                %folder
                varargout{1} = im;
        end        
        set(hIm, 'Visible', 'on');

        if(overlapBugs==true)
           displayOverlappedBugs(); 
        end
        
        
        %Update spots that were manually added to the images
        if(strcmp(get(hMenuSpot, 'Checked'),'on'))
           displayFoundSpots(); 
        end
        
        
    end

%%% Functions for fast z-cropping of the time series
function varZCrop_Callback(gcbo, eventdata, handles)
%     %Testing the smoothing function here
%     for i=1:6
%         pos(i,1:2) = round(zCrop{i}.region(2:3));
%         pos(i,3) = imAllmip{1,3,2}(pos(i,1), pos(i,2));
%     end
%     imSize = size(imAllmip{1,3,2});
%     xnodes = 1:50:imSize(1); ynodes = 1:50:imSize(2);
%     g = gridfit(pos(:,1),pos(:,2),pos(:,3),xnodes,ynodes, 'Smoothness', 1);
%     
%     
%     b = 0;
    
%     %From the tag on the image find out which color and image we clicked on
%     tag = get(gcbo, 'Tag');
%     mipColor = str2num(tag(5));
%     zDepth = str2num(tag(7));

    %Find out how full our array is 
    
    %Save the position in the figure that was clicked on
    pos =  get(gca, 'Currentpoint'); pos = pos(1,1:2);
    zCrop{end+1}.pos = pos;
   
   %By default we'll set the max and min value to be the top and bottom of
   %the image stack..we should be able to be more intelligent about this.
   
%    if(zDepth==3)
%        zCrop{end}.z = 3;
%    elseif(zDepth==1)
%       zCrop{end}.z = 1;
%    elseif(zDepth==2)
%        zCrop{end}.z = 2;
%    end

   %Find which regions this point is in
   overlap = zeros(totalNumRegions,2);
   for nR=1:totalNumRegions
       %x position
       regOverlap(nR,1,1) = param.regionExtent.XY{colorNum}(nR,1);
       regOverlap(nR,1,2) = regOverlap(nR,1,1)+param.regionExtent.XY{colorNum}(nR,3);
       
       %y position
       regOverlap(nR,2,1) = param.regionExtent.XY{colorNum}(nR,2);
       regOverlap(nR,2,2) = regOverlap(nR,2,1)+param.regionExtent.XY{colorNum}(nR,4);
   
       
       %See if the position that we clicked on is in the range of one of
       %these regions.
       if(zCrop{end}.pos(2)>regOverlap(nR,1,1) &&...
               zCrop{end}.pos(2)<regOverlap(nR,1,2))
           overlap(nR,1) = 1;
       end
       
       if(zCrop{end}.pos(1)>regOverlap(nR,2,1) &&...
               zCrop{end}.pos(1)<regOverlap(nR,2,2))
           overlap(nR,2) = 1;
       end    
   end
   
   %Save a list of all the regions that are in the region clicked on. If we
   %clicked outside of all regions then don't update anything
   
   overlap = sum(overlap,2);
   zCrop{end}.region = find(overlap==2, length(overlap));

   if(length(find(overlap==2))>0)
       %Update the axes ticks to show where we put down a marker
       minY = 1;
       maxY = size(get(gcbo, 'CData'),1);
       yArr = minY:1:maxY;
       
       zCrop{end}.handle =  line(pos(1)*ones(length(yArr),1),yArr);
       set(zCrop{end}.handle, 'LineWidth', 0.1);
       
       %Find the position in the different region where we clicked
       %on the image
       for j=1:length(find(overlap==2))
           thisR = zCrop{end}.region(j,1);
          zCrop{end}.region(j,2) = zCrop{end}.pos(2)-regOverlap(thisR,1,1);
          zCrop{end}.region(j,3) = zCrop{end}.pos(1)-regOverlap(thisR,2,1);
           
       end
       
       
   else
       zCrop{end} = [];
       return
       
   end
   
   %Get the height in the z-direction where we put down this line
   zCrop{end}.height = int16(get(hZSlider, 'Value'));
   
   %Enable the mouse to allow us to scroll through this image
   set(fGui, 'WindowScrollWheelFcn', {@mouse_Callback,gcbo});
   
    
end

function mouse_Callback(varargin)
counter = varargin{2}.VerticalScrollCount;

%Find out which color and image we clicked on
tag = get(varargin{3}, 'Tag');
tag
mipColor = str2num(tag(5));
zDepth = str2num(tag(7));

thisR = zCrop{1,end};
cropRange = param.regionExtent.crop.z;
origCrop = param.regionExtentOrig.crop.z;

for i=1:size(thisR.region,1)
    nR = thisR.region(i,1);
    %For each region increment the cropping range in z-if we clicked on the
    %top image change the maximum z-depth, if we clicked on the bottom
    %image change the minimum z-depth.

    if(zDepth==3)
        if(cropRange(nR,2)-counter<=origCrop(nR,2))
            cropRange(nR,2) = cropRange(nR,2)-counter;
        end
    elseif(zDepth==1)
        if(cropRange(nR,1)-counter>=origCrop(nR,1))
            cropRange(nR,1) = cropRange(nR,1)-counter;
        end
    end
        
    
end

%Turn off any previous timers that we opened.
prevTimer = timerfind('Tag', 'cropTimer');
delete(prevTimer);

T = timer('ExecutionMode', 'fixedDelay', 'Tag', 'cropTimer', ...
    'TasksToExecute', 2,'TimerFcn', @updateZCrop, 'Period', 2);
start(T);
param.regionExtent.crop.z = cropRange;

%Update the z crop height table
set(hRegTable, 'Data', param.regionExtent.crop.z);
drawnow;
end


    function updateZCrop(~,~)
        
        %The timer automatically runs this function when first produced-we
        %only want it to run after 1 sec.
        thisTimer = timerfind('Tag', 'cropTimer');
        if(get(thisTimer, 'TasksExecuted')<2)
            return
        end
        displayAllMIP();
        
    end

    function displayAllMIP()
        cropRange = param.regionExtent.crop.z;
        origCrop = param.regionExtentOrig.crop.z;
        
        %Update the MIP for the quick z-cropping code
        totalNumColors = 2;
        for nC=1:totalNumColors
            for i=1:3
                
                for nR=1:totalNumRegions
                    %+1 to deal with Rick's stupid starting at 0 comp-sci thing
                    minZ = param.regionExtent.Z(cropRange(nR,1),nR)+1;
                    maxZ = param.regionExtent.Z(cropRange(nR,2),nR)+1;
                    
                    totalMinZ = param.regionExtent.Z(origCrop(nR,1),nR)+1;
                    totalMaxZ = param.regionExtent.Z(origCrop(nR,2),nR)+1;
                    
                    
                    switch i
                        case 1
                            if(totalMinZ==minZ)
                                imAllmip{nC,nR} = zeros(size(imAll{nC,nR}),size(imAll{nC,nR},2),'uint16');
                            else
                                imAllmip{nC,nR} = max(imAll{nC,nR}(:,:,totalMinZ:minZ),[],3);
                            end
                        case 2
                            imAllmip{nC,nR} = max(imAll{nC,nR}(:,:,minZ:maxZ),[],3);
                        case 3
                            if(totalMaxZ==maxZ)
                                imAllmip{nC,nR} = zeros(size(imAll{nC,nR},1),size(imAll{nC,nR},2), 'uint16');
                            else
                                imAllmip{nC,nR} = max(imAll{nC,nR}(:,:,maxZ:totalMaxZ),[],3);
                            end
                    end
                end
                im = registerSingleImage(imAllmip, param.color{nC},param);
                set(imZmip{nC,i}, 'CData', im);
                
                fprintf(1, '.');
            end
        end
        fprintf(1, '\n');
        
    end

%Crop the image using the markers put down by the user
    function varZCrop
        zCropPos = cell(0,0);
        
    end

    function [scanNum, colorNum] = getScanAndColor()
        
        
        scanNum = get(hScanSlider, 'Value');
        scanNum = int16(scanNum);
        
        colorNum = get(hColorSlider, 'Value');
        colorNum = ceil(colorNum);
        colorNum = int16(colorNum);
        
    end

end

function param = calcCroppedRegion(param)

%Make a mask the size of the total registered image

im = zeros(param.regionExtent.regImSize);
imCropRect = im;

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

end


function [data, param] = loadParameters(varargin)
switch nargin
    case 0
        dirName = uigetdir(pwd, 'Pick a directory to show the registered images from.');
    case  1
        dirName = varargin{1};
end
if(dirName==0)
    %User pressed cancel-exit program
    data = 'error';
    param = 'error';
    return;
end

paramFile = [dirName, filesep, 'gutOutline', filesep, 'param.mat'];
paramFileExist = exist(paramFile, 'file');
dataFile = [dirName, filesep, 'gutOutline', filesep, 'data.mat'];

dataFileExist = exist(dataFile, 'file');
%If work has been done on this file already, load in the results

%Go to the directory above this one-useful for quickly
%going through different fish.
cd([pwd filesep '..']);

paramFileExist
switch paramFileExist
    case 2
        disp('Parameters for this scan have already been (partially?) calculated. Loading them into the workspace.');
        
        paramTemp = load(paramFile);
        param = paramTemp.param;
        if(dataFileExist==2)
            dataTemp = load(dataFile);
            data = dataTemp.data;
        else
            data = ''; %We don't use it anyway...we need to cull this from our code!
        end
        %Check to see if the directory listed in the param
        %variable matches the directory we choose-if not
        %this suggests that the volume name has been
        %changes. If this is the case prompt the user to
        %see if they want to change the name of the
        %directory or quit
        
        if(~strcmp(param.directoryName, dirName))
            answer = inputdlg('The directory name in the param variable does not match the selected directory! Do you want to change the directory name and save (1), change the directory name and dont save (2) or quit the program (3)?');
            answer = answer{1};
            answer = str2num(answer);
            
            switch answer
                case 1
                    param.directoryName = dirName;
                    if(isfield(param, 'dataSaveDirectory'))
                        param.dataSaveDirectory = [param.directoryName filesep 'gutOutline'];
                    end
                    saveParamFile = true;
                case 2 
                    param.directoryName = dirName;
                    saveParamFile = false;
                case 3
                    return
                    
            end
        end
        
        
        
    case 0
        
        parameterFile = [dirName, filesep, 'ExperimentData.mat'];
        %Load in information about this scan...this information should be
        %passed in, or stored in one place on the computer.
        param.micronPerPixel = 0.1625; %For the 40X objective.
        
        param.imSize = [2160 2560];
        
        
        
        
        expData = load(parameterFile);
        param.expData = expData.parameters;
        param.expData.timeData = expData.timeData;
        
        param.directoryName = dirName;
        
        %Load in the number of scans. Default will be for all of the
        %scans...might want to make this an interactive thing at some point.
        param.scans = 1:param.expData.totalNumberScans;
        %Number of regions in be analyzed. Hardcoded to be all of them
        param.regions = 'all';
        
        %Find all the colors in the scan. Semi-clumsy b/c
        %the expData file doesn't contain a nice list of
        %colors used.
        allColors = {param.expData.Scan.color};
        
        param.color = [];
        
        %See if 488 nm is present;
        isGreen = strcmp(allColors, '488 nm: GFP');
        
        nColor = length(param.color);
        
        if(sum(isGreen)>0)
            param.color= {'488nm'};
        end
        
        nColor = length(param.color);
        %See if 568 nm is present;
        isGreen = strcmp(allColors, '568 nm: RFP');
        
        if(sum(isGreen)>0)
            if(nColor>0)
                param.color(nColor+1)= {'568nm'};
            else
                
                param.color= {'568nm'};
            end
        end
        
        %For the parameters above construct a structure that will contain all the
        %results of this calculation.
        
        data = '';%I think we can slowly remove this variable from the code.
        
        disp('Parameters succesfully loaded.');
        
        
        % Calculate the overlap between different regions
        
        fprintf(2,'Calculating information needed to register the images...');
        [data,param] = registerImagesXYData('original', data,param);
        
        %Only register in z-direction if we've ssved the
        %full 3-d scans
        if(~isfield(param.expData, 'saveScan')||strcmp(param.expData.saveScan,'true'))
            [data,param] = registerImagesZData('original', data,param);
        end
        
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


%Set data save directory if not done already
if(~isfield(param, 'dataSaveDirectory'))
    param.dataSaveDirectory = [param.directoryName filesep 'gutOutline'];
end


%Save the calculated parameters, unless they've been
%calculated before.
saveParamFile = true;
if(dataFileExist~=2 &&saveParamFile ==true)
    save(paramFile, 'param');
end

end

%For a given polygon, smooth out the polygon using spline interpolation
function poly = splineSmoothPolygon(poly)

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

end


