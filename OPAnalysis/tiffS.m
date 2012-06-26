%Function to cycle through a series of tiff images



function [] = tiffS(varargin)



if nargin==1
    im = mat2gray(varargin{1});
    imPath = pwd;
end

if nargin==0
    [imLoc, pathN] = uigetfile('.TIF', 'Select the image stack to load in.');
    imPath = [pathN imLoc];
    imL  = imfinfo(imPath, 'tif');
    
    im = zeros(imL(1).Height, imL(1).Width, size(imL,1));
    
    for i=1:size(imL,1)
        im(:,:,i) = imread(imPath, i);
    end
end

%Where we'll save all the marker regions.
saveDir = '~/Documents/opercle/confocal_20min_fish3/';
%saveDir = pathN;
imPathBase = '/Volumes/pat/80_percent_103111/80_percent_lapse_real__w1Yoko GFP_s4_t';
nextIm = 1;

saveFile = saveDir;


im = mat2gray(im);

h_fig = figure;
set(h_fig,'KeyPressFcn',{@key_Callback,h_fig});
set(h_fig, 'WindowScrollWheelFcn', {@mouse_Callback, h_fig});

minN = 1;
maxN = size(im,3);
index = 1;

origAxes = subplot(1,2,1);
hIm = imshow(im(:,:,1),[]);
origT = title(index);

segAxes = subplot(1,2,2);
segIm = imshow(im(:,:,1),[]);


imT = im;

%What fraction of the Otsu threshold to use.
threshScale = 1;
threshOffset = 0;
%hLine = imline(origAxes);
%pos = wait(hLine);

maxN = 50;

polyZ = cell(maxN,1);
hPoly = '';
topIndex = 50;
bottomIndex = 1;

title(segAxes, ['Top: ', num2str(topIndex)]);

fN = [saveDir 'OP_Scan', sprintf('%03d', 1), '.mat'];
%Load the already thresholded images if we can.
try
    imT = load(fN);
    imT = imT.imT;
catch
    imT = roughSegment(im);
end
%Only keep the regions that intersect the line that we drew through the
%center of the opercle.
% 
% xx = pos(1,1) + (1:1000)*(pos(2,1)-pos(1,1))/1000;
% yy = pos(1,2) + (1:1000)*(pos(2,2)-pos(1,2))/1000;

b = 0;

hImC = imcontrast(hIm);
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
        
        %imT = cleanup3dMarkers(imT);
        
        imOut = bwlabeln(imOut>0);
    end
    function zDown
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
                    hPoly = impoly(segAxes, polyZ{index}, 'Closed', true);
                else
                    hPoly = impoly(segAxes, polyZ{index-1}, 'Closed', true);
                end
            end
            index = index-1;
            set(hIm, 'CData', im(:,:,index));
            set(origT, 'string',num2str(index));
            
            
            temp = segmentIm(im(:,:,index));
            imOut = overlayIm(im(:,:,index), temp>0);
            set(segIm, 'CData', imOut);
            
            
        end
                 
    end

    function zUp
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
                    hPoly = impoly(segAxes, polyZ{index}, 'Closed', true);
                else
                    hPoly = impoly(segAxes, polyZ{index+1}, 'Closed', true);
                end
            end
            
            index = index+1;
            set(hIm, 'CData', im(:,:,index));
            set(origT, 'string', num2str(index));
            
            
            temp = segmentIm(im(:,:,index));
            imOut = overlayIm(im(:,:,index), temp>0);
            
            set(segIm, 'CData', imOut);
            
        end
        
        
    end
    function imOut = onlyOP(imIn, xx, yy)
        xx = round(xx);yy = round(yy);
        
        imT2 = imIn>0;
        
        ind = sub2ind([size(imIn,1), size(imIn,2)],yy,xx);
        temp = zeros(size(imIn,1), size(imIn,2));
        temp(ind) = 1;
        
        temp = repmat(temp, [1,1,maxN]);
        
        imT2 = imT2+temp; %Find the intersection points with this line
        
        ind = find(imT2(:)==2);
        
        val = imIn(ind);
        val = unique(val);
        
        inter = ismember(imIn, val);
        
        imIn(~inter) = 0;
        
        imOut = imIn;
        
    end
    function key_Callback(varargin)

        val = varargin{1,2}.Key;

        switch val
            
            case '1'
                %Delete current polygon and load in the one from the
                %previous index instead. Useful when the fish has shifted.
                 delete(hPoly);

                    hPoly = impoly(segAxes, polyZ{index-1}, 'Closed', true);
                    
            case '2'
                  %Delete current polygon and load in the one from the
                %previous index instead. Useful when the fish has shifted.
                 delete(hPoly);

                    hPoly = impoly(segAxes, polyZ{index+1}, 'Closed', true);
                
                    
            case 't'
               topIndex = index;
               title(segAxes, ['Bottom: ', num2str(bottomIndex), '   Top: ', num2str(topIndex)]);

            case 'b'
                bottomIndex = index;
                title(segAxes, ['Bottom: ', num2str(bottomIndex), '   Top: ', num2str(topIndex)]);
                 
            case 'leftarrow'
                zDown();
      
                
            case 'rightarrow'
                zUp();
                
            case 'p'
                polyZ = cell(maxN,1);

                    delete(hPoly)
  
                    hPoly = impoly(segAxes,'Closed', true);
                    position = wait(hPoly);
                    polyZ{index} = position;
                 
            case 's'
                
                for i=1:maxN
                    if(~isempty(polyZ{i}))
                        mask = poly2mask(polyZ{i}(:,1), polyZ{i}(:,2), imL(2).Height, imL(1).Width);
                        imT(:,:,i) = imT(:,:,i).*mask;
                    end
                end
                imT = imT>0;
%                 
%                 posApi = iptgetapi(hLine);
%                 pos = posApi.getPosition();
%                 
%                 xx = pos(1,1) + (1:1000)*(pos(2,1)-pos(1,1))/1000;
%                 yy = pos(1,2) + (1:1000)*(pos(2,2)-pos(1,2))/1000;
% 
%                 
%                 imT = roughSegment(imT);
%                 imT = onlyOP(imT, xx, yy);
%                 %Force the opercle to be the only region segmented.
                 %Remove all regions above and equal to this one
                for iT = topIndex:size(imT,3)
                    imT(:,:,iT) = zeros(size(imT(:,:,iT)));
                end
                
                for iT = 1:bottomIndex;
                    imT(:,:,iT) = zeros(size(imT(:,:,iT)));
                end
                
                    
                
                
                
                temp = segmentIm(im(:,:,index));
                imOut = overlayIm(im(:,:,index), temp>0);
                
                set(segIm, 'CData', imOut);
                
                disp('Segmentation done!');
                
            case 'm'
                %measure the narrowest and widest part of the opercle
                %Remove certain regions from the image markers
                prompt={'Enter the region number to remove from the markers'};
                name='Region removing';
                numlines=1;
                defaultanswer='';
                answer=inputdlg(prompt,name,numlines,defaultanswer); 
                b = 0;
               
                
            case 'o'
                %Change the threshold for Otsu
                threshScale = input('New Threshold');
            case 'l'
                threshOffset = input('Offset for threshold');
            case 'c'
                %Coursely segment the images
                imT = roughSegment(im);
                
            case 'a'
                %Set the top image to be 51-so that up to the top is saved
                topIndex = 51;
                title(segAxes, ['Bottom: ', num2str(bottomIndex), '   Top: ', num2str(topIndex)]);
                               
            case 'f' %Load new images and save previous ones
                
                
                %Save markers made for this image
                
               % outM = ['OP_Scan', imLoc(end-11:end-9)];
             outM = ['OP_Scan', imLoc(end-6:end-4)];
               fn = [saveFile outM '.mat'];
                evalC = ['save(' ,'''' , fn , ''' ,' ,' ''imT'', ''polyZ'' )'];
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
                    imT = load(fN);
                    imT = imT.imT;
                catch
                    imT = roughSegment(im);
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
                
                temp = segmentIm(im(:,:,index));
                imOut = overlayIm(im(:,:,index), temp>0);
                
                set(segIm, 'CData', imOut);
                  
                delete(hPoly)
                hPoly = impoly(segAxes, polyZ{index}, 'Closed', true);
        
                
                
            case 'd'
                %Save markers made for this image
                b= 0;
                
                outM = imLoc(1:end-4);
                fn = [saveFile outM '.mat'];
                evalC = ['save(' ,'''' , fn , ''' ,' ,' ''imT'' )'];
                eval(evalC);
                b = 0;
                
                disp('saving done!');
                
                
            case 'v'
                
                for vI=1:size(imL,1)
                    set(hIm, 'CData', im(:,:,vI));
                    set(origT, 'string', num2str(vI));
                    
                    temp = segmentIm(im(:,:,vI));
                    imOut = overlayIm(im(:,:,vI), temp>0);
                    
                    set(segIm, 'CData', imOut);
                    
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
                    
                    imT = im;
                    
                    set(hIm, 'CData', im(:,:,index));
                    set(origT, 'string', num2str(index));
                    
                    temp = segmentIm(im(:,:,index));
                    imOut = overlayIm(im(:,:,index), temp>0);
                    
                    set(segIm, 'CData', imOut);
                    
                    
                    %Then segment the images
                    posApi = iptgetapi(hLine);
                    pos = posApi.getPosition();
                    
                    xx = pos(1,1) + (1:1000)*(pos(2,1)-pos(1,1))/1000;
                    yy = pos(1,2) + (1:1000)*(pos(2,2)-pos(1,2))/1000;
                    
                    
                    imT = roughSegment(imT);
                    imT = onlyOP(imT, xx, yy);
                    %Force the opercle to be the only region segmented.
                    
                    temp = segmentIm(im(:,:,index));
                    imOut = overlayIm(im(:,:,index), temp>0);
                    
                    set(segIm, 'CData', imOut);
                    
                    %And save the result
                    outM = imLoc(1:end-4);
                    fn = [saveFile outM '.mat'];
                    evalC = ['save(' ,'''' , fn , ''' ,' ,' ''imT'' )'];
                    eval(evalC);
                    b = 0;
                    
                    
                end
                
                
        end
        
        

    end


    function outIm = segmentIm(im)
       
       outIm =imT(:,:,index);
        
    end


end