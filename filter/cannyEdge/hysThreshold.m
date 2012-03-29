%Cleans up the edge detection by partitioning data into a high and low
%threshold and then iteratively applying morphological operators.

function [hIm] = hysThreshold(localMax, highThresh, lowThresh)
 %   figure; imshow(localMax>highThresh);
%    figure; imshow((localMax>lowThresh)-(localMax>highThresh))

hIm = localMax>highThresh;
lIm = (localMax>lowThresh)-(localMax>highThresh);

%Get a label matrix for the high threshold and low threshold regions

hLabel =bwlabel(hIm);
lLabel = bwlabel(lIm);

%Dilate the hIm and then look for an intersection with lIm;

%Use a small structuring element
se = strel('square',10);

%See if the dilated high threshold image intersects with any low
%thresholded regions. If so connect them.


for i=1:100
    dilIm = imdilate(hIm,se);
    intIm = dilIm.*lIm;
    %Find all the regions in lLabel that contain these pixels.
    newRegion = intIm.*lLabel;
    
    %If there aren't any new regions picked up, break.
    if(sum(newRegion(:))==0)
        disp(i)
        break
    end
    %Append these regions to hIm and repeat
    hIm = hIm+newRegion;
   
    index = find(newRegion>0);
    lIm(index) = 0;
    %lIm = lIm-newRegion; %Remove these regions from the low threshold region
    imshow(newRegion>0);
    title(sum(newRegion(:)))
    pause(0.5)
end

end