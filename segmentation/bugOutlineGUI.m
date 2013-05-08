%bugOutlineGUI: Display location of found bacteria in a 3D stack.



function [] = bugOutlineGUI(im, rProp)

%Get z and xy list of bacteria locations
loc = [rProp.Centroid]; loc = reshape(loc, 3, length(rProp));

z = loc(3,:); xy = loc(1:2, :);


hFig = figure('Name', 'Identify the bacteria game!', 'Menubar', 'none', 'Tag', 'fGui',...
    'Visible', 'on', 'Position', [50 50 1500 900], 'Color',[0.925, 0.914, 0.847]);


hMenuDisplay = uimenu('Label', 'Display');
hMenuContrast = uimenu(hMenuDisplay, 'Label', 'Adjust image contrast', 'Callback', @adjustContrast_Callback);
minZ = 1;
maxZ = size(im,3);

%Display image
hImPanel = uipanel('Parent', hFig, 'BackgroundColor', 'white', 'Position', [0.01, .18, .98, .8],...
    'Units', 'Normalized');
imageRegion = axes('Parent', hImPanel,'Tag', 'imageRegion', 'Position', [0, 0 , 1,1], 'Visible', 'on',...
    'XTick', [], 'YTick', [], 'DrawMode', 'fast');

hIm = imshow(im(:,:,minZ),'Parent', imageRegion);
set(imageRegion, 'CLim', [0 1000]);
hold on

hP = plot(1:2, 1:2, 'Parent', imageRegion, 'o', 'MarkerSize', 10, 'Color', [0 0 1]);


%Handle to image contrast toolbar
hContrast = imcontrast(imageRegion);





zStepSmall = 1.0/(maxZ- minZ);
zStepBig = 15.0/(maxZ-minZ);

hZSlider = uicontrol('Parent', hFig, 'Units', 'Normalized', ...
    'Position', [0.05 0.05 0.8 0.05], 'Style', 'slider', 'Min', minZ, ...
    'Max', maxZ, 'SliderStep', [zStepSmall zStepBig], 'Value', minZ, 'Callback', @zSliderCallback);











% Callback functions
    function zSliderCallback(hObject, eventData)
       zNum = get(hZSlider, 'Value');
       zNum = int16(zNum);
       
       updateImage(zNum);

    end
   function adjustContrast_Callback(hObject, eventdata)
            hContrast = imcontrast(imageRegion);

   end

    function updateImage(zNum)
       set(hIm, 'CData', im(:,:,zNum)); 
    end

    function updatePlots(zNum)
        ind = abs(z-nZ)<1;
        
    end
end