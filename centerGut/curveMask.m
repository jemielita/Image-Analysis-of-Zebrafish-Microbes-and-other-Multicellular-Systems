%curveMask: For a given mask, and  line that runs down the center of it,
%calculate 

function mask = curveMask(BW,line,~, type)

xx = line(:,1);
yy = line(:,2);

%Try to allocate a relatively big array to begin with (to avoid having to reallocate mid-stride.
%If that doesn't work because of memory issues then start with a small one.

try
    mask = zeros(size(BW,1), size(BW,2),5);
catch err 
    mask = zeros(size(BW,1), size(BW,2),1);
end

fprintf(2,'Creating Masks ');
count = 0;
tic;
lastMaskInd = 2;
for i=2:length(xx)-1
    fprintf(2, '.');
    %Find the orthogonal vector using Gram-Schmidt orthogonalization
    pos = getOrthVect(xx, yy, type,i);
    
    thisMask = poly2mask(pos(:,1), pos(:,2), size(BW,1), size(BW,2));
    
    %Cut off any part of the mask outside the outlined region
    thisMask = thisMask.*BW;
    
    thisMask = i*thisMask; %Uniquely label each mask
    %See if this mask doesn't overlap with any of the previously found
    %masks. If it doesn't then add this mask to that array, if not put it
    %into a new array.
   
    maskInd = [setdiff(1:size(mask,3), lastMaskInd), lastMaskInd];
    
    for mComp=1:size(mask,3)
        
        %See if this region overlaps with regions in any of the array of
        %masks. Compare with the mask array containing the previous array
        %last-this is the most mask that it will overlap with.
        thisInd = maskInd(mComp);
       % thisInd = mComp;
        isOverlap = sum(sum(thisMask.*mask(:,:,thisInd)>0));
        count = count+1;
        if(isOverlap~=0)
            %Regions overlap, skip this mask for now,
            if(mComp<size(mask,3))
                continue %Continue comparing masks if you're not at the end of the array of masks.
            else
                mask(:,:,mComp+1) = thisMask; %Enlarge the array storing the masks.
            end            
        else
            mask(:,:,thisInd) = thisMask + mask(:,:,thisInd);
            lastMaskInd = thisInd;
            break
        end      
    end
  
        
end
toc
fprintf(2,'done!\n');
%Remove any arrays in mask that don't contain regions.
while(~any(mask(:,:,end)>0))
    mask(:,:,end) = [];
end

end

%Get the orthogonal vectors to the points on the line. Can be called in one
%of two values.
%if type is 'rectangle', then each mask region will be a box that is
%perpendicular to line at position 'i' along the curve.
%If type is 'curved' then each region will be the area between the line
%perpendicular to the line at position 'i' and 'i+1' along the curve. For
%straight regions these two calls should return the same value, however, in
%curved regions they will not.
   