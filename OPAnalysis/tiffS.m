%Function to cycle through a series of tiff images



function [] = tiffS(im)

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



%As a first pass let's see if a simple thresholding does the trick
thresh = graythresh(im);
imT = im>thresh;
imT = double(imT);

%imT = cleanup3dMarkers(imT);

imT = bwlabeln(imT>0);

%Only keep the regions that intersect the line that we drew through the
%center of the opercle.

xx = pos(1,1) + (1:1000)*(pos(2,1)-pos(1,1))/1000;
yy = pos(1,2) + (1:1000)*(pos(2,2)-pos(1,2))/1000;

b = 0;

    function imOut = onlyOP(imT, xx, yy)
        xx = round(xx);yy = round(yy);
        
        imT2 = imT>0;
        
        ind = sub2ind([size(imT,1), size(imT,2)],yy,xx);
        temp = zeros(size(imT,1), size(imT,2));
        temp(ind) = 1;
        
        temp = repmat(temp, [1,1,maxN]);
        
        imT2 = imT2+temp; %Find the intersection points with this line
        
        ind = find(imT2(:)==2);
        
        val = imT(ind);
        val = unique(val);
        
        inter = ismember(imT, val);
        
        imT(~inter) = 0;
        
        imOut = imT;
        
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
                imT = onlyOP(imT, xx, yy);
                %Force the opercle to be the only region segmented.
                
            case 'm'
                %measure the narrowest and widest part of the opercle
                %Remove certain regions from the image markers
                prompt={'Enter the region number to remove from the markers'};
                name='Region removing';
                numlines=1;
                defaultanswer='';
                answer=inputdlg(prompt,name,numlines,defaultanswer); 
                b = 0;
                
               
        end
        
        

    end


    function outIm = segmentIm(im)
       
       outIm =imT(:,:,index);
        
    end


end