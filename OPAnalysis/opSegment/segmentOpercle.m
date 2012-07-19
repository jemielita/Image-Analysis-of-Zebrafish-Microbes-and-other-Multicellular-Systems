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
typeSeg = '2d';

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
    
    [imLocEnd, pathNEnd] = uigetfile('.TIF', 'Select the last image in this stack.');
    imPathEnd = [pathNEnd imLocEnd];
    
    imEnd = regexp(imLocEnd, '\d+(?=.TIF)');
    
    maxIm = imLocEnd(imEnd:end-4);
    maxIm = str2num(maxIm);
    
    saveDir = uigetdir(pathN, 'Select directory to save segmented opercles.');
    saveBase = inputdlg('Base name for saved opercles', '', 1, {baseIm});
    
    imL  = imfinfo(imPath, 'tif');
    im = zeros(imL(1).Height, imL(1).Width, size(imL,1));
    
    %Number of images in this stack
    minN = 1;
    maxN = size(imL,1);
    index = minN;
    
    %Load in first image stack
    loadImage();
    
end

%Calculate maximum intensity projection of this image stack
imMIP = max(im,[],3);

h_fig = figure;

set(h_fig,'KeyPressFcn',{@key_Callback,h_fig});
set(h_fig, 'WindowScrollWheelFcn', {@mouse_Callback, h_fig});

%Create cell array that will contain the segmented region. Code will be
%built so that we can in the future do 3D segmentation instead of 2D
%segmentation.
%imSeg{i,1} = segmented image (2D or 3D);
%imSeg{i,2} = cropping rectangle
%imSeg{i,3} = image index of points inside opercle
%imSeg{i,4} = image index of points outside opercle
imSeg = cell(maxIm-minIm+1, 4);

%Create figure window for original and segmented images
hAxes(1) = subplot(1,2,1);
hIm = imshow(im(:,:,1),[]);
origT = title(index);

hAxes(2) = subplot(1,2,2);
hSegImage = imshow(im(:,:,1),[]);

%This will be useful if we ever deal with zooming in a decent way
linkaxes(hAxes, 'xy');

%Parameters used for doing course segmentation
%What fraction of the Otsu threshold to use.
threshScale = 1;
threshOffset = 0;
%hLine = imline(origAxes);
%pos = wait(hLine);


%%%%%%%%%% Masks used to mark the opercle and the background
isOpercle = zeros(size(imMIP));
isBackground = zeros(size(imMIP));

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
            loadImage();
            set(hImCrop, 'CData', sum(im,3));
            
        end
    end
    
    function zDownCrop()
        %When cropping the images just scan through the stack
       if(thisIm~=minIm)
           thisIm = thisIm-1;
           loadImage();
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
                    saveRectLoc(hRect, thisIm);
                    thisIm = thisIm-1;
                    loadImage();
                    
                    loadRectLoc(hRect,thisIm);
                    %segmentImage('initial');
                    
                    displayNewImage();  
                end
                
            case 'rightarrow'
                if(thisIm~=maxIm)
                    saveRectLoc(hRect, thisIm);
                    thisIm = thisIm+1;
                    loadImage();
                    
                    loadRectLoc(hRect, thisIm);
                    %segmentImage('initial');
                    
                    displayNewImage();
                end

                %%%%%% Keys used by the user to select regions inside %%%%
                %%%%%% and outside the opercle                        %%%%
            case 'o'
                
                %                 %Change the threshold for Otsu
                %                 threshScale = input('New Threshold');
                %
                %Will now instead be used to draw where the opercle is
                drawLine('opercle');
                updateSegImage()
            case 'b'
                %Add a line to show where the background is
                drawLine('background');
                updateSegImage()
                
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
                segmentImage(imSeg);
                
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
                
                updateSegImage();
                
                disp('Segmentation done!');
       
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
                               
            case 'f' %Load new images and save previous ones
                               
                %Save markers made for this image
                
                % outM = ['OP_Scan', imLoc(end-11:end-9)];
                outM = ['OP_Scan', imLoc(end-6:end-4)];
                fn = [saveFile outM '.mat'];
                evalC = ['save(' ,'''' , fn , ''' ,' ,' ''imSeg'', ''polyZ'' )'];
                eval(evalC);
                
                disp('saving done!');
                
                %Load in a new set of images
                %    nextIm = str2num(imPath(end-5:end-4));
                %  nextIm = nextIm +7;
                %        nextIm = str2num(imPath(end-11:end-9));
                nextIm = nextIm+7;
                %  nextIm = 8;
                % imPathNew = [imPath(1:end-6), num2str(nextIm), '.TIF'];
                imPathNew = [imPathBase num2str(nextIm) '.TIF'];
                %                 imPathNew = [imPath(1:end-7), sprintf('%03d',nextIm), imPath(end-3:end)];
                %imPathNew = [imPath(1:end-12), sprintf('%03d', nextIm), imPath(end-8:end)];
                disp(imPathNew);
                %                 [imLoc, pathN] = uigetfile('.tif', 'Select the image stack to load in.',imPathNew);
                %                 imPath = [pathN imLoc];
                %                 imL  = imfinfo(imPath, 'tif');
                
                %Don't bother prompting the user-let's just whizz through
                %these.
                imPath  = imPathNew;
                im = zeros(imL(1).Height, imL(2).Width, size(imL,1));
                
                imLoc = imPath(end-18:end);
                
                for i=1:size(imL,1)
                    im(:,:,i) = imread(imPath, i);
                end
                
                im = mat2gray(im);
                
                
                fN = [saveDir 'OP_Scan', sprintf('%03d', nextIm), '.mat'];
                %Load the already thresholded images if we can.
                try
                    imSeg = load(fN);
                    imSeg = imSeg.imSeg;
                catch
                    imSeg = roughSegment(im);
                end
                
                %Go to just below the previous bottom index on the last
                %scan
                if(bottomIndex~=1)
                    index = bottomIndex-1;
                else
                    index = bottomIndex;
                end
                
                set(hIm, 'CData', im(:,:,index));
                set(origT, 'string', num2str(index));
                
                temp = segmentImage(im(:,:,index));
                imOut = overlayImage(im(:,:,index), temp>0);
                
                set(hSegImage, 'CData', imOut);
                  
                delete(hPoly)
                hPoly = impoly(hAxes(2), polyZ{index}, 'Closed', true);
        
                
                
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
                   loadImage();
                   set(hImCrop, 'CData', max(im,3));
               end
           case 'rightarrow'
               if(thisIm~=maxIm)
                  thisIm = thisIm+1;
                  loadImage();
                  set(hImCrop, 'CData', max(im,3));
               end
               
               
       end
    end

    function loadImage()
        %Load in a new image stack
        imPath = [pathN baseIm num2str(thisIm) '.TIF'];
        switch isGlobalCropped
            case 'false'
                for i=1:maxN
                    im(:,:,i) = imread(imPath, 'Index', i);
                end
                
                %temporary cludge-every z slice is now the maximum
                %intensity projection
                imSegemp = max(im,[],3);
                im = repmat(imSegemp, [1 1 maxN]);
                
                b = 0;
                
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
        
        %Calculate maximum intensity projection if we're doing 2D
        %segmentation.
        if(strcmp(typeSeg, '2d'))
            imMIP = max(im,[],3);
        end
        
   
    end

    function displayNewImage()
        
        switch typeSeg
            case '3d'
                set(hIm, 'CData', im(:,:,index));
                set(origT, 'string', num2str(index));
                
                segMask = imSeg{thisIm,1}(:,:,index);
                imOut = overlayImage(im(:,:,index), segMask>0);
                
                set(hSegImage, 'CData', imOut);
                
            case '2d'
                %For the 2d case we will only update the segmented region
                %after we've messed around for a bit
                set(hIm, 'CData', imMIP);
                set(origT, 'string', 'MIP');
                
                set(hSegImage, 'CData', imMIP);
        end
           
    end

    function updateSegImage()
       
        switch typeSeg         
            case '3d'
                segMask = imSeg{thisIm,1}(:,:,index);
                imOut = overlayImageage(im(:,:,index), temp>0, isOpercle, isBackground);
            case '2d'
                if(isempty(imSeg{thisIm,1}))
                    segIm{thisIm,1} = zeros(size(im,1), size(im,2));
                end
                    
                segMask = segIm{thisIm, 1};
                imOut = overlayImage(imMIP, segMask>0, isOpercle, isBackground);
        end

        set(hSegImage, 'CData', imOut);
        
    end

%Save current location of the cropping rectangle
    function saveRectLoc(hRect, thisIm)
        hPos = iptgetapi(hRect);
        imSeg{thisIm, 2} = round(hPos.getPosition());
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

%Important function: this is what we'll use to actually segment the image
%for a given set of markers, etc.
    function imSeg = segmentImage(imSeg)
       saveRectLoc(hRect, thisIm);
       
        switch typeSeg
            case '2d'
                %Crop the image down to the mask
                imC = imcrop(imMIP, imSeg{thisIm,2});
                
                %Load in labels of regions inside the opercle/background
                imO = imcrop(isOpercle, imSeg{thisIm,2});
                imB = imcrop(isBackground, imSeg{thisIm,2});
                imB(1:end,1:2) = 1;
                imB(1:end,end-1:end) = 1;
                imB(1:2, 1:end) = 1;
                imB(end-1:end,1:end)= 1;
                
                imGraph = graphCut(imC, imO, imB);
                
                %Update segmented opercle in cropped region of the image
                xInit = imSeg{thisIm,2}(1);
                yInit = imSeg{thisIm,2}(2);
                xFinal = xInit + imSeg{thisIm,2}(3);
                yFinal = yInit + imSeg{thisIm,2}(4);
                
                imSeg{thisIm,1} = zeros(size(im,1), size(im,2));
                imSeg{thisIm,1}(yInit:yFinal, xInit:xFinal) = imGraph;
                
            case '3d'
                outIm = imSeg(:,:,index);
        
        end
    end
end