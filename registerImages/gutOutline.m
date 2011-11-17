
function gutOutline(im, param, data)

%%%%%%%%%%%%%%
% GUI Elements
%%%%%%%%%%%%%%

%Variables that we'll use in this GUI
zMin = 1;

%Put this back in in a second.
zMax = length([param.registerImZ]);
zNum = zMin;
zLast = zNum; %The last z level we went to.

%Counter that we'll use to tell what slice we're on.

global polyPosition;
polyPosition = cell(zMax-zMin, 1);

zStepSmall = 1.0/(zMax-zMin);
zStepBig = 15.0/(zMax-zMin);
    %%%%%%%%%%%%%%%%
    % The GUI window
    fGui = figure('Name', 'Play the Outline the Gut Game!', 'Menubar', 'none', 'Tag', 'fGui',...
        'Visible', 'off', 'Position', [50, 50, 1350, 950], 'Color', [0.925, 0.914, 0.847]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    % AXES to DISPLAY IMAGES
    imageRegion = axes('Tag', 'imageRegion', 'Position', [.05, .15, .90, .8], 'Visible', 'on',...
        'XTick', [], 'YTick', [], 'DrawMode', 'fast');
    hZText = uicontrol('Parent', fGui, 'Units', 'Normalized', 'Position', [0.02 0.05 0.06 0.02],...
        'Style', 'text', 'String', 'Z Depth');
    hZTextEdit = uicontrol('Parent', fGui, 'Units', 'Normalized', 'Position', [0.09 0.05 0.03 0.02],...
        'Style', 'text', 'String', zMin);
    hZSlider = uicontrol('Parent', fGui,'Units', 'Normalized', 'Position', [.13 0.05 0.3 0.01],...
        'Style', 'slider', 'Min', zMin, 'Max', zMax, 'SliderStep', [zStepSmall zStepBig], 'Value', 1,...
        'Callback', @zSlider_Callback);
    
    
%%%%%%%%%%%
% GUI Setup
%%%%%%%%%%%
    
    % Display GUI
    set([fGui,  hZSlider, imageRegion],...
        'Units', 'normalized');
 
    movegui(fGui, 'center');
    set(fGui, 'Visible', 'on');
    
    %Pad the axes to keep imcontrast happy.
    imshow(im(:,:,zMin), [],'Parent', imageRegion);
    hContrast = imcontrast(imageRegion);
    
    %Start drawing the boundaries!
    hPoly = impoly;
    addNewPositionCallback(hPoly,@updatePosition);
    
  
    
    
    
 %%Callback Functions
    function [] = updatePosition(position)
       polyPosition{zNum} = position; 
    end
    function zSlider_Callback(hObject, eventData)
        zNum = get(hZSlider, 'Value');
        zNum = ceil(zNum);
        zNum = int16(zNum);
        
        %Update the displayed z level.
        set(hZTextEdit, 'String', zNum);
                
        hIm = imshow(im(:,:,zNum),[], 'Parent', imageRegion);
        hContrast = imcontrast(hIm);
        
        if(isempty(polyPosition{zLast}))
            hPoly = impoly(imageRegion);
        else
            for i=zLast+1:zNum
                polyPosition{i}= polyPosition{zLast};
            end
            hPoly = impoly(imageRegion, polyPosition{zLast});
        end
        
        addNewPositionCallback(hPoly,@updatePosition);

        
        %Update the previous examined Z slice
        zLast = zNum;
    end
    
end