

minThresh= 1000;
maxThresh = 5000;

%Get mask for pixels above the maximum threshold
imSeg = im>maxThresh;
imSeg = 2*imSeg + double(im>minThresh);


%Linking together regions
for nS = 2:size(im,3)-1 
   [r,c] = find(imSeg(:,:,nS-1)+imSeg(:,:,nS+1)==2);
   
   imSeg 
    
    
end