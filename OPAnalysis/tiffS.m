%Function to cycle through a series of tiff images



function [] = tiffS(varargin)

%Where we'll save all the marker regions.
saveDir = 'C:\jemielita\markers\';

saveFile = saveDir;

if nargin==1
    im = mat2gray(varargin{1});
    imPath = pwd;
end

if nargin==0
    [imLoc, pathN] = uigetfile('.tif', 'Select the image stack to load in.');
    imPath = [pathN imLoc];
    imL  = imfinfo(imPath, 'tif');
    
    im = zeros(imL(1).Height, imL(2).Width, size(imL,1));
    
    for i=1:size(imL,1)
        im(:,:,i) = imread(imPath, i);
    end

end

im = mat2gray(im);

h_fig = figure;
set(h_fig,'KeyPressFcn',{@key_Callback,h_fig});

minN = 1;
maxN = size(im,3);
index = 1;

origAxes = subplot(1,2,1);
hIm = imshow(im(:,:,1),[]);
origT = title(index);

segAxes = subplot(1,2,2);
segIm = imshow(im(:,:,1),[]);

imcontrast;

imT = im;

hLine = imline(origAxes);
pos = wait(hLine);

imT = roughSegment(im);

%Only keep the regions that intersect the line that we drew through the
%center of the opercle.

xx = pos(1,1) + (1:1000)*(pos(2,1)-pos(1,1))/1000;
yy = pos(1,2) + (1:1000)*(pos(2,2)-pos(1,2))/1000;

b = 0;

    function imOut = roughSegment(imIn)
        %As a first pass let's see if a simple thresholding does the trick
        thresh = graythresh(imIn);
        imOut = imIn>thresh;
        imOut = double(imOut);
        
        %imT = cleanup3dMarkers(imT);
        
        imOut = bwlabeln(imOut>0);
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
            case 'leftarrow'
                %The left arrow key was pressed
                if(index~=1)
                    index = index-1;
                    set(hIm, 'CData', im(:,:,index));
                    set(origT, 'string',num2str(index));
                   
                   
                   temp = segmentIm(im(:,:,index));
                   imOut = overlayIm(im(:,:,index), temp>0);
                   set(segIm, 'CData', imOut);
                end
            case 'rightarrow'
                %The right arrow key was pressed
                if(index~=maxN)
                    index = index+1;
                    set(hIm, 'CData', im(:,:,index));
                    set(origT, 'string', num2str(index));
                    
                    
                    temp = segmentIm(im(:,:,index));
                    imOut = overlayIm(im(:,:,index), temp>0);
                   
                    set(segIm, 'CData', imOut);
                end
                
            case 's'
                
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
                
                
            case 'm'
                %measure the narrowest and widest part of the opercle
                %Remove certain regions from the image markers
                prompt={'Enter the region number to remove from the markers'};
                name='Region removing';
                numlines=1;
                defaultanswer='';
                answer=inputdlg(prompt,name,numlines,defaultanswer); 
                b = 0;
               
            case 'c'
                %Coursely segment the images
                imT = roughSegment(im);
               
            case 'l'
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
                
                    
                
                
            case 'd'
                %Save markers made for this image
                b= 0;
                
                outM = imLoc(1:end-4);
                fn = [saveFile outM '.mat'];
                evalC = ['save(' ,'''' , fn , ''' ,' ,' ''imT'' )'];
                eval(evalC);
                b = 0;
                
                
           
            case 'a'
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