%selectMarkers.m
%
%Scan through a time series of markers and clean them up. In particular
%remove false markers.
%
%

function [] = selectMarkers(varargin)

if nargin>=2
    markerDir = varargin{1};
    imDir = varargin{2};
end

if nargin<=1
    markerDir = uigetdir('C:\Jemielita\markers', 'Select directory to load markers from');  
    imDir = uigetdir('C:\Users\lsmAnalysis\SVI\Images', 'Select directory to load images from');
end

minS =1;

if nargin==3
    minS = varargin{3};
end
if nargin==1
    minS = varargin{1};
end
   
maxS = 144;

sIndex = minS;

fnBase = 'OP_Scan';
fnRoot = '_cmle.mat';
imRoot = '_cmle.tif';

fN = [markerDir filesep fnBase sprintf('%03d', minS) fnRoot];

%Load in the markers
mO = load(fN);
mO = mO.imT;




%Load in the images
imPath = [imDir filesep fnBase sprintf('%03d', minS), imRoot];

imL  = imfinfo(imPath, 'tif');

im = zeros(imL(1).Height, imL(2).Width, size(imL,1));

for i=1:size(imL,1)
    im(:,:,i) = imread(imPath, i);
end
im = mat2gray(im);
minN = 1;
maxN = size(im,3);

%Setup the GUI
fGui = figure('Name', 'Adjust markers', 'Menubar', 'none', 'Tag', 'fGui',...
    'Visible', 'on', 'Position', [50, 50, 500, 900], 'Color', [0.925, 0.914, 0.847]);
hImPanel = uipanel('BackgroundColor', 'white', 'Position', [0.01, .18, .98, .8],...
    'Units', 'Normalized');
imageRegion = axes('Parent', hImPanel,'Tag', 'imageRegion', 'Position', [0, 0 , 1,1], 'Visible', 'on',...
    'XTick', [], 'YTick', [], 'DrawMode', 'fast');

%Add in key press features so we can navigate through the markers
set(fGui,'KeyPressFcn',{@key_Callback,fGui});
%set(fGui, 'WindowButtonDownFcn', @mousePositionCallback);

%Show the images
index = 1;

%mD will contain mask regions that will be deleted.
mD = zeros(size(mO));

%mD2 will contain mask regions that have been deleted in other 
mD2 = zeros(size(mO));

imOut = overlayIm(im(:,:,index), mO(:,:,index), mD(:,:,index), mD2(:,:,index));
imOut = mat2gray(imOut);
hIm = imshow(imOut, [],'Parent', imageRegion);
origT = title(['scan #: ', sIndex, '  z-slice: ', index]);
%imcontrast;


%Clean up the markers a bit

mO = mO>0;
for i=minN:maxN
    mO(:,:,i) = bwmorph(mO(:,:,i), 'clean');
    mO(:,:,i) = bwmorph(mO(:,:,i), 'open');
    mO(:,:,i) = bwareaopen(mO(:,:,i), 20);%Remove objects smaller than this.
    
end


hPoint = [];

 function key_Callback(varargin)

        val = varargin{1,2}.Key;
        
        switch val
            case 'leftarrow'
                %The left arrow key was pressed
                if(index~=1)
                    index = index-1;
                    
                    imOut = overlayIm(im(:,:,index), mO(:,:,index), mD(:,:,index), mD2(:,:,index));
                    imOut = mat2gray(imOut);
                    set(hIm, 'CData', imOut);
                    
                    newTitle = ['scan #: ', num2str(sIndex), '  z-slice: ', num2str(index)];
                    set(origT, 'string',newTitle);
                    
                end
            case 'rightarrow'
                %The right arrow key was pressed
                if(index~=maxN)
                    index = index+1;
                    
                    imOut = overlayIm(im(:,:,index), mO(:,:,index), mD(:,:,index), mD2(:,:,index));
                    imOut = mat2gray(imOut);
                    set(hIm, 'CData', imOut);
                    
                    newTitle = ['scan #: ', num2str(sIndex), '  z-slice: ', num2str(index)];
                    set(origT, 'string',newTitle);
                end
                
            case 'uparrow'
                
                if(sIndex<=maxS)
                
                    %Save the result from the previous adjustment of
                    %markers
                    
                  %Save the troubled markers and the original markers-can
                  %then be combined together later on.
                    saveFile = [markerDir filesep fnBase sprintf('%03d', sIndex) 'adjusted.mat'];
                    evalC = ['save(' ,'''' , saveFile , ''' ,' ,' ''mO'', ''mD'' )'];
                    eval(evalC);
                    
                    %Clear out imD so we can adjust it in the next frame
                    mD(:) = 0;
                    
                    sIndex = sIndex+1;
                    fN = [markerDir filesep fnBase sprintf('%03d', sIndex) fnRoot];
                    
                    %Load in the markers
                    mO = load(fN);
                    mO = mO.imT;
                    
                    %Load in the images
                    imPath = [imDir filesep fnBase sprintf('%03d', sIndex), imRoot];
                    
                    imL  = imfinfo(imPath, 'tif');
                    
                    im = zeros(imL(1).Height, imL(2).Width, size(imL,1));
                    
                    for i=1:size(imL,1)
                        im(:,:,i) = imread(imPath, i);
                    end
                    im = mat2gray(im);
                    
                end
                
                
                %                 %Highlight regions in this new image stack that have already been labelled as false markers
                %                 mD2(:) = 0;
                %                 for i=minN:maxN
                %                     indPrev = find(mD(:,:,i)>0);
                %
                %                     L = bwlabel(mO(:,:,i)>0);
                %                     LOverlap = L(indPrev);
                %                     L2 = L;
                %                     L2(ismember(L(:), LOverlap(:))) = 1;
                %                     mD2(:,:,i) = L2;
                %                 end
                %                 mD(:) = 0;
                
                
                %Clean up these markers
                mO = mO>0;
                for i=minN:maxN
                    mO(:,:,i) = bwmorph(mO(:,:,i), 'clean');
                    mO(:,:,i) = bwmorph(mO(:,:,i), 'open');
                    mO(:,:,i) = bwareaopen(mO(:,:,i), 50);%Remove objects smaller than this.
                end


                imOut = overlayIm(im(:,:,index), mO(:,:,index), mD(:,:,index), mD2(:,:,index));
                imOut = mat2gray(imOut);
                set(hIm, 'CData', imOut);
                
                newTitle = ['scan #: ', num2str(sIndex), '  z-slice: ', num2str(index)];
                set(origT, 'string',newTitle);
                
            case 'downarrow'
                
                %Let's disable going down for now.
                if(sIndex==-10)
                    
                    %Save the troubled markers and the original markers-can
                    %then be combined together later on.
                    saveFile = [markerDir filesep fnBase sprintf('%03d', sIndex) 'adjusted.mat'];
                    evalC = ['save(' ,'''' , saveFile , ''' ,' ,' ''mO'', ''mD'' )'];
                    eval(evalC);
                    
                    %Clear out imD so we can adjust it in the next frame
                    mD(:) = 0;
                    
                    
                    %Find overlapping regions with previously found markers
                    %and color these a different color
                    
                    sIndex = sIndex-1;
                    fN = [markerDir filesep fnBase sprintf('%03d', sIndex) fnRoot];
                    
                    %Load in the markers
                    mO = load(fN);
                    mO = mO.imT;
                    
                    %Load in the images
                    imPath = [imDir filesep fnBase sprintf('%03d', sIndex), imRoot];
                    
                    imL  = imfinfo(imPath, 'tif');
                    
                    im = zeros(imL(1).Height, imL(2).Width, size(imL,1));
                    
                    for i=1:size(imL,1)
                        im(:,:,i) = imread(imPath, i);
                    end
                    im = mat2gray(im);
                    
                    %This code is somewhat unwieldy...we'll just do it by
                    %hand in each frame
                    %                     %Highlight regions in this new image stack that have already been labelled as false markers
                    %                     mD2(:) = 0;
                    %                     for i=minN:maxN
                    %                        indPrev = find(mD(:,:,i)>0);
                    %
                    %                        L = bwlabel(mO(:,:,i)>0);
                    %                        LOverlap = L(indPrev);
                    %                        L(:) = 0;
                    %                        L(ismember(L(:), LOverlap(:))) = 1;
                    %                        mD2(:,:,i) = L;
                    %                     end
                    %                     mD(:) = 0;
                    
                    
                    %Clean up these markers
                    
                    mO = mO>0;
                    for i=minN:maxN
                        mO(:,:,i) = bwmorph(mO(:,:,i), 'clean');
                        mO(:,:,i) = bwmorph(mO(:,:,i), 'open');
                        mO(:,:,i) = bwareaopen(mO(:,:,i), 20);%Remove objects smaller than this.
                    end


                end
                
                
                imOut = overlayIm(im(:,:,index), mO(:,:,index), mD(:,:,index), mD2(:,:,index));
                imOut = mat2gray(imOut);
                set(hIm, 'CData', imOut);
                
                newTitle = ['scan #: ', num2str(sIndex), '  z-slice: ', num2str(index)];
                set(origT, 'string',newTitle);
               
                
            case 'p'
               addPoint;

                
        end
        
                
 end


    function [] = mousePositionCallback(hObject, ~)
     
        position=get(hObject,'CurrentPoint');
        
        position = round(position);
        
        %Find intersection between this point and points on the
        %image
        [y,x] = find(mO(:,:,index) >0);
        val = cat(2,x,y);
        ind = ismember(val, position, 'rows');
        
        %Color regions that have been clicked blue
        try
            
            L = bwlabel(mO(:,:,index)>0);
            indReg = find(L==L(val(ind,2), val(ind,1)));
            L(:) = 0;
            L(indReg) = 1;
            
            mD(:,:,index) = mD(:,:,index) + L;
        catch
            
        end
        imOut = overlayIm(im(:,:,index), mO(:,:,index), mD(:,:,index),mD2(:,:,index));
        imOut = mat2gray(imOut);
        set(hIm, 'CData', imOut);
        
%         handle = findobj('Tag', 'impoint');
%         delete(handle);
%         delete(hPoint);
        
        
        
    end
    
    function [] = addPoint()
        %Add a point to the image that will be used to remove
        %garbage markers
        hPoint = impoint;
        position = wait(hPoint);
       
        position = round(position);
         %Find intersection between this point and points on the
        %image
        [y,x] = find(mO(:,:,index) >0);
        val = cat(2,x,y);
        ind = ismember(val, position, 'rows');
        
        %Color regions that have been clicked blue
        try
            
            L = bwlabel(mO(:,:,index)>0);
            indReg = find(L==L(val(ind,2), val(ind,1)));
            L(:) = 0;
            L(indReg) = 1;
            
            mD(:,:,index) = mD(:,:,index) + L;
        catch
            
        end
        imOut = overlayIm(im(:,:,index), mO(:,:,index), mD(:,:,index),mD2(:,:,index));
        imOut = mat2gray(imOut);
        set(hIm, 'CData', imOut);
        
        handle = findobj('Tag', 'impoint');
        delete(handle);
        delete(hPoint);
        addPoint;
    end




end