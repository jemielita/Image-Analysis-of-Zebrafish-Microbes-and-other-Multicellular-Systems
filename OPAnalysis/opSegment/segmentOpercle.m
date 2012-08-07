%Function to cycle through a series of tiff images of opercles and properly
%segment them. 
%
%Image stacks must have the following format in order to be recognized by
%the program:
% (baseName)(number)(.TIF)
% ex: 'sp7_mef2ca_lapse_w1Yoko GFP_s14_t1.TIF'
%number must be written without any leading zeros (e.g.  12 not 012)
%
function [] = segmentOpercle(varargin)

%Hard code in what type of segmentation we're doing: '2d' or '3d'
typeSeg = '3d';

isGlobalCropped = 'false';
%need to throw this all in an honest to god gui

if nargin==1
    im = mat2gray(varargin{1});
    imPath = pwd;
end

if nargin==0

    [imLoc, pathN] = uigetfile('.TIF', 'Select the first image to load in.');
    imPath = [pathN imLoc];
    
    %Get string base of these images, and the first scan number
    thisIm = regexp(imLoc, '\d+(?=.TIF)');
    
    baseIm = imLoc(1:thisIm-1);
    thisIm = imLoc(thisIm:end-4);
    thisIm = str2num(thisIm);
    minIm = thisIm;
   
       [imLocEnd, pathNEnd] = uigetfile('.TIF', 'Select the last image in this stack.', ...
          imPath);
    imPathEnd = [pathNEnd imLocEnd];
    
    imEnd = regexp(imLocEnd, '\d+(?=.TIF)');
    
    maxIm = imLocEnd(imEnd:end-4);
    maxIm = str2num(maxIm);
    
    saveDir = uigetdir(pathN, 'Select directory to save segmented opercles.');
    saveBase = inputdlg('Base name for saved opercles', '', 1, {baseIm});
   
    imL  = imfinfo(imPath, 'tif');
    im = zeros(imL(1).Height, imL(1).Width, size(imL,1));
    
    %For filtering images
    imOrig = im;
    
    %Number of images in this stack
    minN = 1;
    maxN = size(imL,1);
    index = minN;
    
    %%%%%%%%%% Masks used to mark the opercle and the background
    isOpercle = zeros(size(im,1), size(im,2));
    isBackground = zeros(size(im,1), size(im,2));
    
    %See if we've already done some segmention on this region and load the
    %region
    loadSeg = inputdlg('Load previously segmented opercles: (1) no, (2) individually, (3) group',...
        '', 1, {'1'});
    loadSeg = str2num(loadSeg{1});
    
    switch loadSeg
        case 1
            
            %Create cell array that will contain the segmented region. Code will be
            %built so that we can in the future do 3D segmentation instead of 2D
            %segmentation.
            %imSeg{i,1} = segmented image (2D or 3D);
            %imSeg{i,2} = cropping rectangle
            %imSeg{i,3} = image index of points inside opercle
            %imSeg{i,4} = image index of points outside opercle
            %imSeg{i,5} = maximum intensity projection of the opercle at this time
            %point
            %imSeg{i,6} = structure tha contains all the region properties that we
            %want to calculate for the opercle.
            imSeg = cell(maxIm-minIm+1, 6);
        case 2
            imSeg = cell(maxIm-minIm+1,6);
           
           segDir = dir(saveDir);
           
           for i=1:size(segDir,1)
              name = segDir(i).name;
              
              %See if this particular file shares a name root with saveBase
              
              isFile = regexp(name, saveBase);
              if(isFile==1)
                  
                  imNum = regexp(name, '\d+(?=.mat)', 'match');
                  if(isempty(imNum))
                      continue%Cheap way to avoid potential ALL.mat entries
                  end
                  
                  imNum = str2num(imNum{1});
                  
                  thisCell = load([saveDir filesep name]);
                  thisCell = thisCell.thisCell;
                  
                  for j=1:size(thisCell,2)
                     imSeg{imNum,j} = thisCell{j}; 
                      
                  end
                  
              else 
                  continue
              end
           end
                      
       case 3
              allLoc = [saveDir filesep saveBase 'ALL.mat'];
              imSeg = load(allLoc, 'imSeg');
              imSeg = imSeg.imSeg;
       otherwise
           disp('Load segmentation error: Input must be either 1, 2, or 3!');
           return;
   end
           
    imMIP = [];
    
    %Load in first image stack
    [~,~,im, imOrig, imMIP] = loadImage(isOpercle, isBackground);
    
    %Calculate maximum intensity projection of this image stack
    imMIP = max(im,[],3);
    
end

h_fig = figure('Name', '2D time series segmentation', 'Menubar', 'none', 'Tag', 'fGuiOpercle',...
    'Visible', 'on', 'Position', [50, 50, 1500, 600], 'Color', [0.925, 0.914, 0.847]);

set(h_fig,'KeyPressFcn',{@key_Callback,h_fig});
set(h_fig, 'WindowScrollWheelFcn', {@mouse_Callback, h_fig});


autoSave = true;
hMenuFile = uimenu('Label', 'File');
hSaveAll = uimenu(hMenuFile, 'Label', 'Save all data', 'Callback', @saveData_Callback);
hSaveAuto = uimenu(hMenuFile, 'Label', 'Auto save', 'Checked', 'on', 'Callback', @saveDataAuto_Callback);


displayMIP = true;
hMenuDisp = uimenu('Label', 'Display');
hMIP = uimenu(hMenuDisp, 'Label', 'Display MIP', 'Callback', @displayMIP_Callback, 'Checked', 'off');
displayFeatures = true;
hDisplayFeatures = uimenu(hMenuDisp, 'Label', 'Display region Features', ...
    'Callback', @displayRegFeatures_Callback, 'Checked', 'on');

%Sliders for controlling segementation parameters

hManipPanel = uipanel('Parent', h_fig, 'Units', 'Normalized', ...
    'Position', [0.01 0.05 0.1 0.95], 'Title', 'Segmentation Parameters');

lMin = 0; lMax = 1;
lStepSmall = 0.05; lStepBig = 0.1;
lambda = 0.5;
hLText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.01 0.95 0.3 0.05],...
    'Style', 'text', 'String', 'Lambda');
hLTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.32 0.97 0.65 0.03],...
    'Style', 'edit', 'Tag', 'lambdaEdit', 'String', lambda, 'Callback', @lambda_Callback);

bkgCutoff = 0.1;
hBkgText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.01 0.85 0.3 0.05],...
    'Style', 'text', 'String', 'Bkg. cutoff');
hBkgTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.32 0.87 0.65 0.03],...
    'Style', 'edit', 'Tag', 'lambdaEdit', 'String', bkgCutoff, 'Callback', @hBkgText_Callback);

objCutoff = 0.9;
hObjText = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.01 0.75 0.3 0.05],...
    'Style', 'text', 'String', 'Obj. cutoff');
hObjTextEdit = uicontrol('Parent', hManipPanel, 'Units', 'Normalized', 'Position', [0.32 0.77 0.65 0.03],...
    'Style', 'edit', 'Tag', 'lambdaEdit', 'String', objCutoff, 'Callback', @hObjText_Callback);

%Structure to hold all segementation variables
segParam.lambda = lambda;
segParam.objCutoff = objCutoff;
segParam.bkgCutoff = bkgCutoff;

%Create figure window for original and segmented images
hAxes(1) = subplot(1,2,1);
hIm = imshow(imMIP,[]);
origT = title(index);

hAxes(2) = subplot(1,2,2);
hSegImage = imshow(imMIP,[]);

%This will be useful if we ever deal with zooming in a decent way
linkaxes(hAxes, 'xy');

%Create a cropping rectangle around the opercle, to limit the region that
%we do any segmentation.
hRect = imrect(hAxes(1));


%%%%%% Callback funtions for various buttons on the screen and generic
%%%%%% mouse and keyboard callbacks
    function mouse_Callback(varargin)
        counter = varargin{2}.VerticalScrollCount;
        if(counter==-1)
            zUp();
        elseif(counter==1)
            zDown();
        end
       
    end

    function lambda_Callback(hObject, eventdata)
        lambda = get(hLTextEdit, 'String');
        lambda = str2num(lambda);
        
        segParam.lambda = lambda;
        
    end

    function hBkgText_Callback(varargin, eventdata)
        bkgCutoff = get(hBkgTextEdit, 'String');
        bkgCutoff = str2num(bkgCutoff);
        
        segParam.bkgCutoff = bkgCutoff;
        
        
    end

    function hObjText_Callback(varargin, eventdata)
        objCutoff = get(hobjTextEdit, 'String');
        objCutoff = str2num(objCutoff);
        
        segParam.objCutoff = objCutoff;
        
    end

    function saveData_Callback(hObject, eventdata)
        saveType = inputdlg('Save segmented regions individually (1) or combined (2)', '', 1,{'2'});
        saveType = str2num(saveType{1});
        saveSegmentation(saveType);
    end

    function saveDataAuto_Callback(~,~)       
        isCheck = get(hSaveAuto, 'Checked');
        if(strcmp(isCheck, 'off'))
            set(hSaveAuto, 'Checked', 'on');
            autoSave = true;
            %Save the current image segmentation
            saveSegmentation(3);
        else
            set(hMIP, 'Checked', 'off');
            autoSave = false;
        end
   
    end
        
    function saveSegmentation(saveType)
        fprintf(1, 'Saving data...');
        switch saveType
            case 1
                %Save all segmented regions, each in its own mat file
                for N=minIm:maxIm
                    fprintf(1, '.');
                    for i=1:size(imSeg,2);
                        thisCell{i} = segIm{N,i};
                    end
                    save([saveDir filesep saveBase{1} fprintf('%03d', N) '.mat'],...
                        'thisCell');
                end
                
            case 2
                %Save all segmented regions to one mat file
                save([saveDir filesep saveBase{1} 'ALL.mat'], 'imSeg');
            case 3
                %Save this segmented frame-usefull for backing up work
                %while we're segmenting
                fprintf(1, '.');
                for i=1:size(imSeg,2);
                    thisCell{i} = imSeg{thisIm,i};
                end
                save([saveDir filesep saveBase{1} sprintf('%03d', thisIm), '.mat'],...
                    'thisCell');
                
            otherwise
                disp('Erorr saving: Input must be either 1,2, or 3!');
        end
        fprintf(1, 'done!\n');
        
    end
    function key_Callback(varargin)
        
        val = varargin{1,2}.Key;
        
        key_segmentCallback(val);
        %
        %         switch isGlobalCropped
        %             case 'true'
        %                 key_segmentCallback(val);
        %             case 'false'
        %                 key_cropCallback(val);
        %         end
        
    end

    function key_segmentCallback(val)

        switch val
            
            %%%%%% Keys used to move through z stacks and scans %%%%%%%%
            case 'downarrow'
                zDown();
                
            case 'uparrow'
                zUp();
                
            case 'leftarrow'
                if(thisIm~=minIm)
                    imSeg = saveRectLoc(imSeg, hRect, thisIm);
                    thisIm = thisIm-1;
                    [isOpercle, isBackground,im,imOrig, imMIP] = loadImage(isOpercle, isBackground);
                    
                    loadRectLoc(hRect,thisIm);
                    %segmentImage('initial');
                    
                    displayNewImage();  
                    updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP,displayFeatures);

                end
                
            case 'rightarrow'
                if(thisIm~=maxIm)
                    imSeg = saveRectLoc(imSeg, hRect, thisIm);
                    thisIm = thisIm+1;
                    [isOpercle, isBackground,im, imOrig, imMIP] = loadImage(isOpercle, isBackground);
                    
                    loadRectLoc(hRect, thisIm);
                    
                    displayNewImage();
                    updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP,displayFeatures);

                end

                %%%%%% Keys used by the user to select regions inside %%%%
                %%%%%% and outside the opercle                        %%%%
            case 'o'
      
                %Will now instead be used to draw where the opercle is
                drawLine('opercle');
                updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index,displayMIP,displayFeatures);
            case 'b'
                %Add a line to show where the background is
                drawLine('background');
                updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP,displayFeatures);
           
            case 's'                
                imSeg = segmentImage(imMIP, imSeg, thisIm, isOpercle, isBackground,hRect, '2d', segParam);
                
                %Calculate properties of the segmented regions
                imSeg = calcRegProps(imSeg, thisIm);
                updateSegImage(imMIP , im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index,displayMIP,displayFeatures);
       
                if(autoSave==true)
                    saveSegmentation(3);
                end
                                
            case 'f' 
                %Filter the image stack-used for testing what filters we
                %should be using
                [im, imMIP] = filterImage(imOrig,hRect);
                
                displayNewImage();
                updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index,displayMIP,displayFeatures);
                
            case 'delete'
                %Remove opercle and background mask
                isOpercle(:) = 0;
                isBackground(:) = 0;
                updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index,displayMIP,displayFeatures);
                
                %Update imSeg
                imSeg{thisIm,3} = [];
                imSeg{thisIm,4} = [];                               
        end 
    end
    function drawLine(regionType)
        hLine = imfreehand(hAxes(2), 'Closed', false);
        
        hApi = iptgetapi(hLine);
        posInit = hApi.getPosition();
        
        %Spline interpolating these points to smooth out the curve before
        %dilating it.
        t = cumsum(sqrt([0,diff(posInit(:,1)')].^2 + [0,diff(posInit(:,2)')].^2));
        %Find x and y positions as a function of arc length
        polyFit(:,1) = spline(t, posInit(:,1), t);
        polyFit(:,2) = spline(t, posInit(:,2), t);
        
        %Interpolate curve to make it less jaggedy, arbitrarily we'll
        %set the number of points to be 50.
        stepSize = 1;
        
        poly(:,2) = interp1(t, polyFit(:,2),min(t):stepSize:max(t),'spline', 'extrap');
        poly(:,1) = interp1(t, polyFit(:,1),min(t):stepSize:max(t), 'spline', 'extrap');
        
%         %Redefining poly
%         poly = cat(2, polyT(:,1), polyT(:,2));
        poly = round(poly);
        
        ind = sub2ind([size(im,1), size(im,2)], poly(:,2), poly(:,1));
        
        mask = zeros(size(im,1), size(im,2));
        mask(ind) = 1;
        lineWidth= 3;
        
        se = strel('disk', lineWidth);
        
        mask = imdilate(mask, se);
        
        switch regionType
            case 'opercle'
                isOpercle = isOpercle + mask;
            case 'background'
                isBackground = isBackground + mask;
        end   
                
        delete(hLine);
    end


    function key_cropCallback(val)
       switch val
           case 'uparrow'
               zUpCrop();
           case 'downarrow'
               zDownCrop();
           case 'leftarrow'
               if(thisIm~=minIm)
                   thisIm = thisIm-1;
                   [isOpercle, isBackground,im,imOrig, imMIP] = loadImage(isOpercle, isBackground);
                   set(hImCrop, 'CData', max(im,3));
                   
                   updateSegImage(imMIP , im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP,displayFeatures);

               end
           case 'rightarrow'
               if(thisIm~=maxIm)
                  thisIm = thisIm+1;
                  [isOpercle, isBackground,im, imOrig, imMIP]  = loadImage(isOpercle, isBackground);
                  set(hImCrop, 'CData', max(im,3));

                  updateSegImage(imMIP ,im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage, index, displayMIP,displayFeatures);

               end
               
               
       end
    end

    function zDown
        
        %Don't scan through z-stack if we're only looking at a 2d
        %projection
        if(strcmp(typeSeg, '2d'))
            return
        end
        
        %The left arrow key was pressed
        if(index~=1)
            if(~isempty(hPoly))
                
                %Get the position of the polygon for this level...we'll
                %save this and use to to further remove extraneous
                %regions from the segmented opercle.
                posApi = iptgetapi(hPoly);
                polyZ{index} = posApi.getPosition();
                
                delete(hPoly);
                if(isempty(polyZ{index-1}))
                    hPoly = impoly(hAxes(2), polyZ{index}, 'Closed', true);
                else
                    hPoly = impoly(hAxes(2), polyZ{index-1}, 'Closed', true);
                end
            end
            index = index-1;
         
            displayNewImage();
         
        end
                 
    end

    function zUp
        
        %Don't scan through z-stack if we're only looking at a 2d
        %projection
        if(strcmp(typeSeg, '2d'))
            return
        end
        
        %The right arrow key was pressed
        if(index==maxN &&~isempty(hPoly))
            posApi = iptgetapi(hPoly);
            polyZ{index} = posApi.getPosition();
        end
        if(index~=maxN)
            
            if(~isempty(hPoly))
                
                %Get the position of the polygon for the previous level...we'll
                %save this and use to to further remove extraneous
                %regions from the segmented opercle.
                posApi = iptgetapi(hPoly);
                polyZ{index} = posApi.getPosition();
                
                delete(hPoly)
                if(isempty(polyZ{index+1}))
                    hPoly = impoly(hAxes(2), polyZ{index}, 'Closed', true);
                else
                    hPoly = impoly(hAxes(2), polyZ{index+1}, 'Closed', true);
                end
            end
            
            index = index+1;
            displayNewImage();
                        
        end
        
        
    end

    function zUpCrop()      
        %When cropping the images just scan through the stack
        if(thisIm~=maxIm)
            thisIm = thisIm+1;
            [isOpercle,isBackground,im, imOrig, imMIP] = loadImage(isOpercle, isBackground);

            set(hImCrop, 'CData', sum(im,3));
            
        end
    end
    
    function zDownCrop()
        %When cropping the images just scan through the stack
       if(thisIm~=minIm)
           thisIm = thisIm-1;
           [isOpercle,isBackground,im,imOrig,imMIP] = loadImage(isOpercle, isBackground);

           set(hImCrop, 'CData', sum(im,3));
           
       end
    end
       
    function imOut = onlyOP(imIn, xx, yy)
        xx = round(xx);yy = round(yy);
        
        imSeg2 = imIn>0;
        
        ind = sub2ind([size(imIn,1), size(imIn,2)],yy,xx);
        temp = zeros(size(imIn,1), size(imIn,2));
        temp(ind) = 1;
        
        temp = repmat(temp, [1,1,maxN]);
        
        imSeg2 = imSeg2+temp; %Find the intersection points with this line
        
        ind = find(imSeg2(:)==2);
        
        val = imIn(ind);
        val = unique(val);
        
        inter = ismember(imIn, val);
        
        imIn(~inter) = 0;
        
        imOut = imIn;
        
    end
    
    function displayRegFeatures_Callback(hObject, eventdata)
        
        isCheck = get(hDisplayFeatures, 'Checked');
        if(strcmp(isCheck, 'off'))
            set(hDisplayFeatures, 'Checked', 'on');
            displayFeatures = true;
            
        else
            set(hDisplayFeatures, 'Checked', 'off');
            displayFeatures = false;
        end
        updateSegImage(imMIP , im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index,displayMIP,displayFeatures);

        
    end

    function displayMIP_Callback(hObject, eventdata)
      
        isCheck = get(hMIP, 'Checked');
        if(strcmp(isCheck, 'off'))
            set(hMIP, 'Checked', 'on');
            displayMIP = true;
            
        else
            set(hMIP, 'Checked', 'off');
            displayMIP = false;
        end
        
        updateSegImage(imMIP , im, imSeg, thisIm, isOpercle, isBackground,...
            typeSeg, hSegImage,index, displayMIP,displayFeatures);
        displayNewImage();

    end

    function [isOpercle, isBackground,im,imOrig, imMIP] = loadImage(isOpercle, isBackground)
        %Load in a new image stack
        imPath = [pathN baseIm num2str(thisIm) '.TIF'];
        switch isGlobalCropped
            case 'false'
                for i=1:maxN
                    im(:,:,i) = imread(imPath, 'Index', i);
                end
                
                
                %Not particularly elegant: if we're doing a 2d segmentation
                %only display the maximum intensity projection-need to fix
                %this up so that we can do filtering on the images
                %effectively.
                if(strcmp(typeSeg, '2d'))
                    temporary cludge-every z slice is now the maximum
                    intensity projection
                    imSegemp = max(im,[],3);
                    im = repmat(imSegemp, [1 1 maxN]);
                    
                end                
            case 'true'
                xMin = hCropRect(1);
                yMin = hCropRect(2);
                xMax = xMin + hCropRect(3);
                yMax = yMin + hCropRect(4);
                for i=1:maxN
                    im(:,:,i) = imread(imPath, 'Index', i, ...
                        'PixelRegion', {[yMin, yMax],[xMin, xMax]});
                end
                
        end
        im = mat2gray(im);
        
        %Calculate maximum intensity projection.
        imMIP = max(im,[],3);
        
        
        %Load a new mask of isOpercle and isBackground
        isOpercle(:) = 0;
        if(sum(imSeg{thisIm,3})>0)
            isOpercle(imSeg{thisIm,3}) = 1;
        end
        isBackground(:) = 0;
        if(sum(imSeg{thisIm,4})>0)
            isBackground(imSeg{thisIm,4}) = 1;
        end
   
        %Make copy of im so that we can filter it repeatedly
        imOrig = im;
        
    end

    function displayNewImage()       
        switch typeSeg
            case '3d'
                if(displayMIP==false)
                    set(hIm, 'CData', imOrig(:,:,index));
                else
                    set(hIm, 'CData', max(imOrig,[],3));
                end
                set(origT, 'string', ['time: ',num2str(thisIm), '   z-slice: ', num2str(index)]);
                
                if(~isempty(imSeg{thisIm,1}))
                    
                    if(length(size(imSeg{thisIm,1}))==3)
                        segMask = imSeg{thisIm,1}(:,:,index);
                    elseif(length(size(imSeg{thisIm,1}))==2)
                        segMask = imSeg{thisIm,1};
                    end
                    
                else
                    segMask = zeros(512,512);
                end
                
                if(displayMIP==false)
                    imOut = overlayImage(im(:,:,index), segMask>0);
                else
                    imOut = overlayImage(imMIP, segMask>0);
                end
                set(hSegImage, 'CData', imOut);
                
            case '2d'
                %For the 2d case we will only update the segmented region
                %after we've messed around for a bit
                set(hIm, 'CData', imMIP);
                set(origT, 'string', 'MIP');
                
                set(hSegImage, 'CData', imMIP);
                
                title(hAxes(1), ['MIP, time step: ', num2str(thisIm)]);

        end
           
    end

%Load previously found location of the cropping rectangle
    function loadRectLoc(hRect, thisIm)
        newRect = imSeg{thisIm,2};
        if(~isempty(newRect))
            hPos = iptgetapi(hRect);
            hPos.setPosition(imSeg{thisIm,2});
        end
              
    end
      

end

%Save current location of the cropping rectangle
 function imSeg = saveRectLoc(imSeg, hRect, thisIm)
        hPos = iptgetapi(hRect);
        imSeg{thisIm, 2} = round(hPos.getPosition());
    end
 function updateSegImage(imMIP, im, imSeg,thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP,displayFeatures)
       
        switch typeSeg         
            case '3d'                  
                if(~isempty(imSeg{thisIm,1}))
                    %Load in either the 3D or 2D segmentation
                    if(length(size(imSeg{thisIm,1}))==3)
                        segMask = imSeg{thisIm,1}(:,:,index);
                    elseif(length(size(imSeg{thisIm,1}))==2)
                        segMask = imSeg{thisIm,1};
                    end
                else
                    segMask = zeros(512,512);
                end  
                
                imOut = overlayImage(imMIP, segMask>0, isOpercle, isBackground);
                
            case '2d'
                if(isempty(imSeg{thisIm,1}))
                    imSeg{thisIm,1} = zeros(size(im,1), size(im,2));
                end
                
                segMask = imSeg{thisIm, 1};
                imOut = overlayImage(imMIP, segMask>0, isOpercle, isBackground);
        end

        
        %Display results of the segmentation desired-useful for checking
        %that the segmentation was done correctly.
        if(displayFeatures==true)
            imFeat = featuresMask(imSeg, thisIm);  
            imFeat = imFeat>0;
            
            R = imOut(:,:,1); G = imOut(:,:,2); B = imOut(:,:,3);
            
            R(imFeat) = (255/255);
            G(imFeat) = (104/255);
            B(imFeat) = (31/255);
            
            imOut(:,:,1) = R; imOut(:,:,2) = G; imOut(:,:,3) = B;
            
            %Make the features of the opercle show up in orange
        end
            
        set(hSegImage, 'CData', imOut);
        
 end
    
%Important function: this is what we'll use to actually segment the image
%for a given set of markers, etc.
 function imSeg = segmentImage(im, imSeg, thisIm, isOpercle, ...
     isBackground, hRect, typeSeg, segParam)
 
 fprintf(1, 'Segmenting opercle...');
       imSeg = saveRectLoc(imSeg, hRect, thisIm);
       
       
       %We'll default to 2d segmentation
       typeSegT = '2d';
        switch typeSegT
            case '2d'
                %Crop the image down to the mask
                imC = imcrop(im, imSeg{thisIm,2});
                
                %Save the MIP to be used in estimating the probability of
                %pixels being in background/foreground
                imSeg{thisIm,5} = im;
                

                %Use the thresholds from the user for automatically setting
                %markers
                numP = length(imC(:));
                [sortIm,ind] = sort(imC(:));
                
                autoObjInd = ind(round(segParam.objCutoff*numP):end);
                
                autoBkgInd = ind(1:round(segParam.bkgCutoff*numP));
                
                autoObj = zeros(size(imC));
                autoBkg = zeros(size(imC));
                autoObj(autoObjInd) = 1; 
                autoBkg(autoBkgInd) = 1;
                
                %Morphological closure to remove gaps
                se = strel('disk', 1);
                autoObj = imclose(autoObj, se);
                autoBkg = imclose(autoBkg, se);
                %Remove single pixel regions
                autoObj = bwmorph(autoObj, 'clean');
                autoBkg = bwmorph(autoBkg, 'clean');

                autoObjInd = find(autoObj==1);
                autoBkgInd = find(autoBkgInd==1);
                
                %Update isOpercle and isBackground using automatically
                %found markers
                xInit = imSeg{thisIm,2}(1);
                yInit = imSeg{thisIm,2}(2);
                xFinal = xInit + imSeg{thisIm,2}(3);
                yFinal = yInit + imSeg{thisIm,2}(4);
                
                isOpercle(yInit:yFinal, xInit:xFinal) = ...
                    isOpercle(yInit:yFinal, xInit:xFinal) + autoObj;
                isBackground(yInit:yFinal, xInit:xFinal) = ...
                    isBackground(yInit:yFinal, xInit:xFinal) +autoBkg;
                
                
                %Save current pixel location of all points inside and
                %outside the opercle
                
                imSeg{thisIm,3} = find(isOpercle>0);
                imSeg{thisIm,4} = find(isBackground>0);
                
                %Load in labels of regions inside the opercle/background
                imO = imcrop(isOpercle, imSeg{thisIm,2});
                imB = imcrop(isBackground, imSeg{thisIm,2});
                imB(1:end,1:2) = 1;
                imB(1:end,end-1:end) = 1;
                imB(1:2, 1:end) = 1;
                imB(end-1:end,1:end)= 1;
                

                %Estimate the probability of any given pixel being in the
                %foreground/background
                
                %This should be set higher up in the code.
                %We'll use this to adjust the probability distribution of
                %pixels being in the background in case the background is
                %somewhat high in the cropped region
                
                bkgVal(1) = mean(im(isBackground>0)); %mean of background noise
                bkgVal(2) = std(im(isBackground>0)); %std deviation
                bkgVal(3) = 0.1; %Number of standard deviations above mean to set high in probability distribution
                
                lambda = segParam.lambda;
                bkgNoise = 0.01;
                intenEst = estimateIntensityDist(imSeg, thisIm, bkgVal);
                imGraph = graphCut(imC, imO, imB, intenEst, lambda, bkgNoise);
                
               %imGraph = ~imGraph; %Why isn't this coming out appropriately?
                                
                %Remove regions with fewer than 100 pixels...need to set
                %this further up in the code
                minPixelNum = 100;
                imGraph = bwareaopen(imGraph,minPixelNum);
                
                %Remove regions stuck to the boundary of the image
                imGraph = imclearborder(imGraph);
                
                %Update segmented opercle in cropped region of the image                
                imSeg{thisIm,1} = zeros(size(im,1), size(im,2));
                imSeg{thisIm,1}(yInit:yFinal, xInit:xFinal) = imGraph;
                
                %Convert to logical
                imSeg{thisIm,1} = imSeg{thisIm,1}>0;

            case '3d'
                outIm = imSeg(:,:,index);
        
        end
        
        fprintf(1, 'done!\n');
 end
  
 %Calculate properties of each of the regions of the segmented opercle
 function imSeg = calcRegProps(imSeg, thisIm)
 
 lIm = bwlabel(imSeg{thisIm,1});
 
 regProp = regionprops(lIm, imSeg{thisIm,5}, 'Centroid','MeanIntensity',...
     'Orientation','MajorAxisLength', 'MinorAxisLength', 'Area');
 imSeg{thisIm,6} = regProp;
 
 end
 
 
 %Get a mask that shows the major axis and centroid for each of the regions
 %calculated
 function mask = featuresMask(imSeg, thisIm)
 prop = imSeg{thisIm,6};
 totNumReg = size(prop,1);
 
 mask = zeros(size(imSeg{thisIm,1}));
 thisFeat = zeros(size(imSeg{thisIm,1}));
 
 
 for nR = 1:totNumReg
     %Place a dot at the centroid of each region
     thisFeat(:) = 0;
     
     centroid = prop(nR).Centroid;
     centroid = round(centroid);
     
     thisFeat(centroid(2), centroid(1)) = 1;
     thisFeat = bwmorph(thisFeat, 'thicken',2);
     
     mask = mask+thisFeat;
     thisFeat(:) =0;
     
     
     %Draw a line along the major axis of each region
     mALength = prop(nR).MajorAxisLength; mALength = round(mALength);
     
     %Construct unrotated line
     R = -round(mALength/2):round(mALength/2);
     %Rotate the line
     theta = -prop(nR).Orientation; theta = deg2rad(theta);
     
     mA = [];
     mA(1,:) = R*cos(theta)+centroid(1);
     mA(2,:) = R*sin(theta)+centroid(2);
     
     mA = round(mA);
     %Draw this line on the mask
     ind = sub2ind(size(thisFeat), mA(2,:), mA(1,:));
     thisFeat(ind) = 1;
     thisFeat = bwmorph(thisFeat, 'dilate', 1);
     mask = mask+thisFeat;
     
 end 
 
 end
 
 
 %Filter the 3d image
 function [im, imMIP] = filterImage(im,hRect)
 fprintf(1, 'Filtering image...');
 
 %Only filtering the cropped region
 hPos = iptgetapi(hRect);
 cropR = round(hPos.getPosition());
 
 for i=1:size(im,3)
     imc(:,:,i) = imcrop(im(:,:,i), cropR);
 end
 imc = medfilt3(imc, [3 3 3]);
 
 %Updating the image-so that the cropped region has been filtered
 xInit = cropR(1);
 yInit = cropR(2);
 xFinal = xInit + cropR(3);
 yFinal = yInit + cropR(4);
 
 im(yInit:yFinal, xInit:xFinal,:) = imc;

 %Bilateral filter
 sigmaS = 5;
 sigmaR = 15;
 samS = 5;
 samR = 15;
 %im=bilateral3(im, sigmaS,0.1*sigmaS,sigmaR,samS,samR);

 
 imMIP = max(im, [],3);
 fprintf(1, 'done!\n');
 end