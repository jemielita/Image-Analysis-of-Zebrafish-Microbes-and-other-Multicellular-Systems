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
    imLoc = 'sp7_mef2ca_lapse_w1Yoko GFP_s14_t1.TIF';
    pathN = 'F:\Jemielita\For_Matt_070512\mutant_fish14_060112\';
 
%    [imLoc, pathN] = uigetfile('.TIF', 'Select the first image to load in.');
    imPath = [pathN imLoc];
    
    %Get string base of these images, and the first scan number
    thisIm = regexp(imLoc, '\d+(?=.TIF)');
    
    baseIm = imLoc(1:thisIm-1);
    thisIm = imLoc(thisIm:end-4);
    thisIm = str2num(thisIm);
    minIm = thisIm;
   
    imLocEnd = 'sp7_mef2ca_lapse_w1Yoko GFP_s14_t50.TIF';
    pathNEnd = 'F:\Jemielita\For_Matt_070512\mutant_fish14_060112\';
    
 %   [imLocEnd, pathNEnd] = uigetfile('.TIF', 'Select the last image in this stack.', ...
  %      imPath);
    imPathEnd = [pathNEnd imLocEnd];
    
    imEnd = regexp(imLocEnd, '\d+(?=.TIF)');
    
    maxIm = imLocEnd(imEnd:end-4);
    maxIm = str2num(maxIm);
    
   % saveDir = uigetdir(pathN, 'Select directory to save segmented opercles.');
    %saveBase = inputdlg('Base name for saved opercles', '', 1, {baseIm});
    
    saveDir = 'F:\temp';
    saveBase = 'sp7_mef2ca_lapse_w1Yoko GFP_s14_t';
    
    
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
    
    
    %Create cell array that will contain the segmented region. Code will be
    %built so that we can in the future do 3D segmentation instead of 2D
    %segmentation.
    %imSeg{i,1} = segmented image (2D or 3D);
    %imSeg{i,2} = cropping rectangle
    %imSeg{i,3} = image index of points inside opercle
    %imSeg{i,4} = image index of points outside opercle
    imSeg = cell(maxIm-minIm+1, 5);
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

displayMIP = false;
hMenuFile = uimenu('Label', 'Display');
hMIP = uimenu(hMenuFile, 'Label', 'Display MIP', 'Callback', @displayMIP_Callback, 'Checked', 'off');

%Create figure window for original and segmented images
hAxes(1) = subplot(1,2,1);
hIm = imshow(imMIP,[]);
origT = title(index);

hAxes(2) = subplot(1,2,2);
hSegImage = imshow(imMIP,[]);

%This will be useful if we ever deal with zooming in a decent way
linkaxes(hAxes, 'xy');

%Parameters used for doing course segmentation
%What fraction of the Otsu threshold to use.
threshScale = 1;
threshOffset = 0;
%hLine = imline(origAxes);
%pos = wait(hLine);


%How much we will dilate the line we draw to mark the opercle and the
%background
lineWidth = 3;

% Polygon used to outline opercle-need to tweak a little bit with current
% segmentation scheme
polyZ = cell(maxN,1);
hPoly = '';
topIndex = maxN;
bottomIndex = 1;

title(hAxes(2), ['Top: ', num2str(topIndex)]);

fN = [saveDir 'OP_Scan', sprintf('%03d', 1), '.mat'];
%Load the already thresholded images if we can.
try
    imSeg{thisIm,1} = load(fN);
    imSeg{thisIm,1} = imSeg.imSeg;
catch
    imSeg{thisIm,1} = roughSegment(im);
end




%Create a cropping rectangle around the opercle, to limit the region that
%we do any segmentation.
hRect = imrect(hAxes(1));

    function mouse_Callback(varargin)
        counter = varargin{2}.VerticalScrollCount;
        if(counter==-1)
            zUp();
        elseif(counter==1)
            zDown();
        end
       
    end
    function imOut = roughSegment(imIn)
        %As a first pass let's see if a simple thresholding does the trick
        thresh = graythresh(imIn);
        imOut = imIn>threshScale*thresh + threshOffset;
        imOut = double(imOut);
        
        %imSeg = cleanup3dMarkers(imSeg);
        
        imOut = bwlabeln(imOut>0);
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
                    updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP);

                end
                
            case 'rightarrow'
                if(thisIm~=maxIm)
                    imSeg = saveRectLoc(imSeg, hRect, thisIm);
                    thisIm = thisIm+1;
                    [isOpercle, isBackground,im, imOrig, imMIP] = loadImage(isOpercle, isBackground);
                    
                    loadRectLoc(hRect, thisIm);
                    
                    displayNewImage();
                    updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP);

                end

                %%%%%% Keys used by the user to select regions inside %%%%
                %%%%%% and outside the opercle                        %%%%
            case 'o'
                
                %                 %Change the threshold for Otsu
                %                 threshScale = input('New Threshold');
                %
                %Will now instead be used to draw where the opercle is
                drawLine('opercle');
                updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index,displayMIP);
            case 'b'
                %Add a line to show where the background is
                drawLine('background');
                updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP);
                
            case '1'
                %Delete current polygon and load in the one from the
                %previous index instead. Useful when the fish has shifted.
                delete(hPoly);
                
                hPoly = impoly(hAxes(2), polyZ{index-1}, 'Closed', true);
                
            case '2'
                %Delete current polygon and load in the one from the
                %previous index instead. Useful when the fish has shifted.
                delete(hPoly);
                
                hPoly = impoly(hAxes(2), polyZ{index+1}, 'Closed', true);
                
                %For now we won't use these because I want to use the 'b'
                %key to set the background and because we're focusing on 2d
                %segmentation here.
%             case 't'
%                 topIndex = index;
%                 title(hAxes(2), ['Bottom: ', num2str(bottomIndex), '   Top: ', num2str(topIndex)]);
%                 
%             case 'b'
%                 bottomIndex = index;
%                 title(hAxes(2), ['Bottom: ', num2str(bottomIndex), '   Top: ', num2str(topIndex)]);
%                 
            case 'p'
                polyZ = cell(maxN,1);
                
                delete(hPoly)
                
                hPoly = impoly(hAxes(2),'Closed', true);
                position = wait(hPoly);
                polyZ{index} = position;
                
            case 's'                
                imSeg = segmentImage(imMIP, imSeg, thisIm, isOpercle, isBackground,hRect, '2d');
                
%                 for i=1:maxN
%                     if(~isempty(polyZ{i}))
%                         mask = poly2mask(polyZ{i}(:,1), polyZ{i}(:,2), imL(2).Height, imL(1).Width);
%                         imSeg(:,:,i) = imSeg(:,:,i).*mask;
%                     end
%                 end
%                 imSeg = imSeg>0;
%                 
%                 %Force the opercle to be the only region segmented.
%                 %Remove all regions above and equal to this one
%                 for iT = topIndex:size(imSeg,3)
%                     imSeg(:,:,iT) = zeros(size(imSeg(:,:,iT)));
%                 end
%                 
%                 for iT = 1:bottomIndex;
%                     imSeg(:,:,iT) = zeros(size(imSeg(:,:,iT)));
%                 end
                
                updateSegImage(imMIP , im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index,displayMIP);
                
       
            case 'l'
                threshOffset = input('Offset for threshold');
            case 'c'
                %Coursely segment the images
                imSeg = roughSegment(im);
                
            case 'a'
                %Set the top image to be maxN-so that all z-slices through
                %the top are saved.
                topIndex = maxN+1;
                title(hAxes(2), ['Bottom: ', num2str(bottomIndex), '   Top: ', num2str(topIndex)]);
                     
                
            case 'f' 
                %Filter the image stack-used for testing what filters we
                %should be using
                [im, imMIP] = filterImage(imOrig);
                
                displayNewImage();
                updateSegImage(imMIP, im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index,displayMIP);
                
                
            case 'd'
                %Save markers made for this image
                b= 0;
                
                outM = imLoc(1:end-4);
                fn = [saveFile outM '.mat'];
                evalC = ['save(' ,'''' , fn , ''' ,' ,' ''imSeg'' )'];
                eval(evalC);
                b = 0;
                
                disp('saving done!');
                
                
            case 'v'
                
                for vI=1:size(imL,1)
                    set(hIm, 'CData', im(:,:,vI));
                    set(origT, 'string', num2str(vI));
                    
                    temp = segmentImage(im(:,:,vI));
                    imOut = overlayImage(im(:,:,vI), temp>0);
                    
                    set(hSegImage, 'CData', imOut);
                    
                    pause(0.5);
                end
                
           
            case '`'
                thisIm = 47;
                while(thisIm<145)
                    thisIm = thisIm+1;
                    %Segment all of these images!
                    %(The results are somewhat rough after awhile anyway)
                    %Load in a new set of images
                    nextIm = str2num(imPath(end-11:end-9));
                    nextIm = nextIm+1;
                    imPathNew = [imPath(1:end-12), sprintf('%03d', nextIm), imPath(end-8:end)];
                    
                    %                 [imLoc, pathN] = uigetfile('.tif', 'Select the image stack to load in.',imPathNew);
                    %                 imPath = [pathN imLoc];
                    %                 imL  = imfinfo(imPath, 'tif');
                    
                    %Don't bother prompting the user-let's just wizz through
                    %these.
                    imPath  = imPathNew;
                    im = zeros(imL(1).Height, imL(2).Width, size(imL,1));
                    
                    imLoc = imPath(end-18:end);
                    
                    for i=1:size(imL,1)
                        im(:,:,i) = imread(imPath, i);
                    end
                    
                    im = mat2gray(im);
                    
                    imSeg = im;
                    
                    set(hIm, 'CData', im(:,:,index));
                    set(origT, 'string', num2str(index));
                    
                    temp = segmentImage(im(:,:,index));
                    imOut = overlayImage(im(:,:,index), temp>0);
                    
                    set(hSegImage, 'CData', imOut);
                    
                    
                    %Then segment the images
                    posApi = iptgetapi(hLine);
                    pos = posApi.getPosition();
                    
                    xx = pos(1,1) + (1:1000)*(pos(2,1)-pos(1,1))/1000;
                    yy = pos(1,2) + (1:1000)*(pos(2,2)-pos(1,2))/1000;
                    
                    
                    imSeg = roughSegment(imSeg);
                    imSeg = onlyOP(imSeg, xx, yy);
                    %Force the opercle to be the only region segmented.
                    
                    temp = segmentImage(im(:,:,index));
                    imOut = overlayImage(im(:,:,index), temp>0);
                    
                    set(hSegImage, 'CData', imOut);
                    
                    %And save the result
                    outM = imLoc(1:end-4);
                    fn = [saveFile outM '.mat'];
                    evalC = ['save(' ,'''' , fn , ''' ,' ,' ''imSeg'' )'];
                    eval(evalC);
                    b = 0;
                                        
                end
                                
        end 
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
                   
                   updateSegImage(imMIP , im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP);

               end
           case 'rightarrow'
               if(thisIm~=maxIm)
                  thisIm = thisIm+1;
                  [isOpercle, isBackground,im, imOrig, imMIP]  = loadImage(isOpercle, isBackground);
                  set(hImCrop, 'CData', max(im,3));

                  updateSegImage(imMIP ,im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage, index, displayMIP);

               end
               
               
       end
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
        
        updateSegImage(imMIP , im, imSeg, thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP);

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


end

%Save current location of the cropping rectangle
 function imSeg = saveRectLoc(imSeg, hRect, thisIm)
        hPos = iptgetapi(hRect);
        imSeg{thisIm, 2} = round(hPos.getPosition());
    end
 function updateSegImage(imMIP, im, imSeg,thisIm, isOpercle, isBackground, typeSeg, hSegImage,index, displayMIP)
       
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

        set(hSegImage, 'CData', imOut);
        
 end
 
    
%Important function: this is what we'll use to actually segment the image
%for a given set of markers, etc.
 function imSeg = segmentImage(im, imSeg, thisIm, isOpercle, ...
     isBackground, hRect, typeSeg, bkgVal)
       imSeg = saveRectLoc(imSeg, hRect, thisIm);
       
       
       %We'll default to 2d segmentation
       typeSegT = '2d';
        switch typeSegT
            case '2d'
                %Crop the image down to the mask
                imC = imcrop(im, imSeg{thisIm,2});
                
                %Load in labels of regions inside the opercle/background
                imO = imcrop(isOpercle, imSeg{thisIm,2});
                imB = imcrop(isBackground, imSeg{thisIm,2});
                imB(1:end,1:2) = 1;
                imB(1:end,end-1:end) = 1;
                imB(1:2, 1:end) = 1;
                imB(end-1:end,1:end)= 1;
                         
                %Save the MIP to be used in estimating the probability of
                %pixels being in background/foreground
                imSeg{thisIm,5} = im;
                
                %Save current pixel location of all points inside and
                %outside the opercle
                imSeg{thisIm,3} = find(isOpercle==1);
                imSeg{thisIm,4} = find(isBackground==1);
                
                %Estimate the probability of any given pixel being in the
                %foreground/background
                
                %This should be set higher up in the code.
                %We'll use this to adjust the probability distribution of
                %pixels being in the background in case the background is
                %somewhat high in the cropped region
                
                
                bkgVal(1) = mean(im(isBackground>0)); %mean of background noise
                bkgVal(2) = std(im(isBackground>0)); %std deviation
                bkgVal(3) = 0.1; %Number of standard deviations above mean to set high in probability distribution
                
                intenEst = estimateIntensityDist(imSeg, thisIm, bkgVal);
                imGraph = graphCut(imC, imO, imB, intenEst);
                
             %   imGraph = ~imGraph; %Why isn't this coming out appropriately?
                                
                %Remove regions with fewer than 100 pixels...need to set
                %this further up in the code
                minPixelNum = 100;
                imGraph = bwareaopen(imGraph,minPixelNum);
                
                %Remove regions stuck to the boundary of the image
                imGraph = imclearborder(imGraph);
                
                %Update segmented opercle in cropped region of the image
                xInit = imSeg{thisIm,2}(1);
                yInit = imSeg{thisIm,2}(2);
                xFinal = xInit + imSeg{thisIm,2}(3);
                yFinal = yInit + imSeg{thisIm,2}(4);
                
                imSeg{thisIm,1} = zeros(size(im,1), size(im,2));
                imSeg{thisIm,1}(yInit:yFinal, xInit:xFinal) = imGraph;
                
                %Convert to logical
                imSeg{thisIm,1} = imSeg{thisIm,1}>0;


            case '3d'
                outIm = imSeg(:,:,index);
        
        end
 end
    
 
 %Filter the 3d image
 function [im, imMIP] = filterImage(im)
 fprintf(1, 'Filtering image...');
 im = medfilt3(im);
 
 %Bilateral filter
 sigmaS = 5;
 sigmaR = 15;
 samS = 5;
 samR = 15;
 %im=bilateral3(im, sigmaS,0.1*sigmaS,sigmaR,samS,samR);

 
 imMIP = max(im, [],3);
 fprintf(1, 'done!\n');
 end