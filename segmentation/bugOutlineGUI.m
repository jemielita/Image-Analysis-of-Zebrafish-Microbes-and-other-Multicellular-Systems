%bugOutlineGUI: Display location of found bacteria in a 3D stack.



function [] = bugOutlineGUI(im, rProp, param, nS, nR,varargin)

switch nargin
    case 5
        remInd = []; %Indices to remove
        addPos = []; %Position to add new bacteria
    case 6
        remInd = varargin{1};
        addPos = [];
    case 7
        remInd = varargin{1};
        addPos = varargin{2};
end
    
%Get z and xy list of bacteria locations
loc = [rProp.Centroid]; loc = reshape(loc, 3, length(rProp));

z = loc(3,:); xy = loc(1:2, :);

hFig = figure('Name', 'Identify the bacteria game!', 'Menubar', 'none', 'Tag', 'fGui',...
    'Visible', 'on', 'Position', [50 50 1500 900], 'Color',[0.925, 0.914, 0.847]);


%Drop down menus
hMenuFile = uimenu('Label', 'File');
hMenuSave = uimenu(hMenuFile, 'Label', 'Save bacteria data', 'Callback', @saveData_Callback);
hMenuDisplay = uimenu( 'Label', 'Display');
hMenuContrast = uimenu(hMenuDisplay, 'Label', 'Adjust image contrast', 'Callback', @adjustContrast_Callback);

hMenuPointPickDropDown = uimenu('Label', 'Pick points');
hMenuPointPick = uimenu(hMenuPointPickDropDown, ...
    'Label', 'Remove falsely labelled points',...
    'Callback', @removePoints_Callback, 'Checked', 'off');
hMenuUndo = uimenu(hMenuPointPickDropDown, ...
    'Label', 'Undo last point',...
    'Callback', @undoLastPoint_Callback, 'Checked', 'off');
hMenuHidePoints = uimenu(hMenuPointPickDropDown, ...
    'Label', 'Hide removed points', ...
    'Callback', @hideRemovedPoints, 'Checked', 'off');
hMenuPointPick = uimenu(hMenuPointPickDropDown, ...
    'Label', 'Add Points',...
    'Callback', @addPoints_Callback, 'Checked', 'off', 'Separator', 'on');
hMenuUndoAdd = uimenu(hMenuPointPickDropDown, ...
    'Label', 'Undo last added point',...
    'Callback', @undoLastPointAdded_Callback, 'Checked', 'off');

hPoint = '';
hPointAPI = '';

minZ = 1;
maxZ = size(im,3);
zNum = minZ;

xOffset = param.regionExtent.indivReg(nS, nR, 1);
yOffset = param.regionExtent.indivReg(nS, nR,2);

%Display image
hImPanel = uipanel('Parent', hFig, 'BackgroundColor', 'white', 'Position', [0.01, .18, .98, .8],...
    'Units', 'Normalized');
imageRegion = axes('Parent', hImPanel,'Tag', 'imageRegion', 'Position', [0, 0 , 1,1], 'Visible', 'on',...
    'XTick', [], 'YTick', [], 'DrawMode', 'fast');


hIm = imshow(im(:,:,minZ),'Parent', imageRegion);

meshIm = zeros(size(im,1), size(im,2));
meshIm(round(size(im,1)/2), :) = 1;
meshIm(:, round(size(im,2)/2)) = 1;
meshIm = bwmorph(meshIm, 'dilate');
meshIm = bwmorph(meshIm, 'dilate');


set(imageRegion, 'CLim', [0 1000]);
hold on


%Plot the points on the first z level 
hP = plot(1:2, 1:2, 'o', 'MarkerSize', 10, 'Color', [0 0 1]);
hPRemove = plot(1:2, 1:2, 'o', 'MarkerSize', 10, 'Color', [1 0 0]);
hPAdd = plot(1:2, 1:2, 'o', 'MarkerSize', 10, 'Color', [0 1 0]);

updatePoints(hP, hPRemove,hPAdd, zNum);

%Handle to image contrast toolbar
hContrast = imcontrast(imageRegion);





zStepSmall = 1.0/(maxZ- minZ);
zStepBig = 15.0/(maxZ-minZ);

hZSlider = uicontrol('Parent', hFig, 'Units', 'Normalized', ...
    'Position', [0.05 0.05 0.8 0.05], 'Style', 'slider', 'Min', minZ, ...
    'Max', maxZ, 'SliderStep', [zStepSmall zStepBig], 'Value', zNum, 'Callback', @zSliderCallback);











% Callback functions
    function zSliderCallback(hObject, eventData)
        zNum = get(hZSlider, 'Value');
        zNum = round(zNum);
        set(hZSlider, 'Value',zNum); 
        
        updateImage(zNum);
        updatePoints(hP,hPRemove, hPAdd,zNum);
    end

    function saveData_Callback(hObject, eventdata)
        [FileName,PathName] = uiputfile('Where to save the data');
        
        save([PathName filesep FileName], 'addPos', 'remInd');
    end


    function adjustContrast_Callback(hObject, eventdata)
        hContrast = imcontrast(imageRegion);
        
    end

    function updateImage(zNum)
        temp = double(im(:,:,zNum)) + double(1000*meshIm);
        
        temp = double(im(:,:,zNum));
        set(hIm, 'CData', temp);
    end

    function updatePoints(hP, hPRemove, hPAdd, zNum)
        
        ind = find(abs(z-zNum)<5);
        
        thisRem = intersect(ind, remInd);
        thisInd = setdiff(ind, remInd);
        
        set(hP, 'XData', xy(1,thisInd)+yOffset);
        set(hP, 'YData', xy(2, thisInd)+xOffset);      
        
        
        set(hPRemove, 'XData', xy(1,thisRem)+yOffset);
        set(hPRemove, 'YData', xy(2, thisRem)+xOffset);   
     
        if(~isempty(addPos))
            addInd = find(abs(addPos(:,3)-zNum)<1);
            set(hPAdd, 'XData', addPos(addInd,1));
            set(hPAdd, 'YData', addPos(addInd,2));
        end
     
        
    end

    function removePoints_Callback(hObject, eventdata)
        isChecked = get(hObject, 'Checked');
        if(strcmp(isChecked, 'on'))
            set(hObject, 'Checked', 'off');
            delete(hPoint);
        else
            set(hObject, 'Checked', 'on');
        end
        
        while strcmp(get(hObject, 'Checked'), 'on')
            zNum = get(hZSlider, 'Value');
            zNum = round(zNum);
            hPoint = impoint(imageRegion);
            
            zNum
            position = wait(hPoint);
            
            delete(hPoint);
            %Find closest estimated bacteria to this point
            ind = find(abs(z-zNum)<1);
            ind = setdiff(ind, remInd);
            distB = sqrt((xy(1,ind)+yOffset-position(1)).^2 + (xy(2,ind)+xOffset-position(2)).^2);
            
            [~,thisInd2] = min(distB);
            
            thisInd = ind(thisInd2);
            remInd = [remInd, thisInd];
            updatePoints(hP,hPRemove, hPAdd, zNum);

        end
        
        
    end

    function undoLastPoint_Callback(hObject, eventdata)
       remInd(end) = [];
       updatePoints(hP, hPRemove, hPAdd, zNum);
    end

    function hideRemovedPoints(hObject,eventdata)
       isChecked = get(hObject, 'Checked');
        if(strcmp(isChecked, 'on'))
            set(hObject, 'Checked', 'off');
            set(hPRemove, 'Visible', 'on');
        
        else
            set(hObject, 'Checked', 'on');
            set(hPRemove, 'Visible', 'off');
        end
        
        
    end
    function undoLastPointAdded_Callback(hObject, eventdata)
       addPos(end,:) = [];
       updatePoints(hP,hPRemove, hPAdd, zNum);
       
    end

    function addPoints_Callback(hObject, eventdata)
        isChecked = get(hObject, 'Checked');
        if(strcmp(isChecked, 'on'))
            set(hObject, 'Checked', 'off');
            delete(hPoint);
        else
            set(hObject, 'Checked', 'on');
        end
        
        while strcmp(get(hObject, 'Checked'), 'on')
            zNum = get(hZSlider, 'Value');
            zNum = round(zNum);
            hPoint = impoint(imageRegion);
            
            position = wait(hPoint);
            
            delete(hPoint);
            addPos = [addPos; [position, zNum]];
            
            updatePoints(hP,hPRemove, hPAdd, zNum);
            
        end
        
    end

end