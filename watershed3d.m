%Combine togethere 2D segmented regions into 3D regions. This is a first
%pass at doing this-ideally we would also incorporate temporal information.

function L = watershed3d(im, markers)

L = zeros(size(markers));

for i=1:53
    T = imimposemin(im(:,:,i), markers(:,:,i));
    L(:,:,i) = watershed(T);  
end

L(:,:,i) = double(L(:,:,i)>0);%Make the image into binary.
%Link together all the 3d regions.

L = link3dRegions(L,markers);



end

function L = link3dRegions(L,markers)

bw = zeros(size(L));
for i=1:53
    slice = L(:,:,i);
    cc = bwconncomp(L(:,:,i));
    
    numEl = zeros(size(cc.PixelIdxList,2),1);
    for n =1:size(cc.PixelIdxList,2)
        numEl(n) = length(cc.PixelIdxList{n});
    end
    
    %Save this panel as a binary image-1's for regions that correspond to
    %our regions, 0's everywhere else
    maxReg = find(numEl ==max(numEl)); %Remove background pixels. We're assuming here that the background is just
    %the largest regions. This is potentially dangerous. Should also use
    %the intensity of the regions.
    index = cc.PixelIdxList{maxReg};
    slice(index) = 0;
    
    %Add in the marker region in case it was removed (which would happen if
    %the marker happened to be larger than a neutrophil)
    slice = slice+markers(:,:,i);
    
    slice = slice>0;
    
    bw(:,:,i) = slice;
    
end


%Get all the connected components in this 3D volume
L = bwlabeln(bw);

end