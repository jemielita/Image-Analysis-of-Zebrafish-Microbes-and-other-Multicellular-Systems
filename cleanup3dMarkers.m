function markers = cleanup3dMarkers(imT)

%For a given set of thresholded regions that will be used as markers clean
%them up a bit.

for i=1:size(imT,3)
    %Use binary closure on the image to clean up the edges
    imT(:,:,i) = bwmorph(imT(:,:,i), 'close');
    %Remove regions with fewer than 10 pixels
    imT(:,:,i) = bwareaopen(imT(:,:,i), 10);
    
    %Fill interior pixels
    imT(:,:,i) = bwmorph(imT(:,:,i), 'fill');
    
    
end

%Only include regions that are part of a structure extending over several
%z-slices
numS = 3;

%First find regions that overlap with regions above and below them. We'll
%build the other regions on top of this.

%I think this code works...though I it didn't seem like I had to debug it
%(so there's probably a problem hiding away somewhere)
markers = zeros(size(imT));
temp = zeros(size(imT,1), size(imT,2));

for i=2:size(imT,3)-1;
    
   
   prevSlice = (imT(:,:,i-1)==1) + (imT(:,:,i)==1);
   
   nextSlice = (imT(:,:,i+1)==1) + (imT(:,:,i)==1);
   
   indexPrev = find(prevSlice==2);
   indexNext = find(nextSlice==2);
   
   %Compare the indices to those found for these three slices. Save regions
   %that are in all three planes.
   
   ccP = bwconncomp(imT(:,:,i-1)==1);
   ccN = bwconncomp(imT(:,:,i+1)==1);
   cc = bwconncomp(imT(:,:,i)==1);
   
   for nReg = 1:size(cc.PixelIdxList,2)
       %If this is non-empty then there is overlap with the previous region
       overP = ismember(cc.PixelIdxList{nReg}, indexPrev);
       overP = sum(overP);
       
       overN = ismember(cc.PixelIdxList{nReg}, indexNext);
       overN = sum(overN);
       
       if(overP*overN>0) %If there is overlap with both the previous and next region, save the result
          temp(cc.PixelIdxList{nReg})=1;
          markers(:,:,i) = markers(:,:,i) + temp;
          temp(:) =0;
          
          %Also include regions from the above and below regions...there
          %should be a non for-loop way of doing this.
          for nRegP = 1:size(ccP.PixelIdxList,2)
             oP = ismember(ccP.PixelIdxList{nRegP}, cc.PixelIdxList{nReg});
             if(sum(oP)>0)
                 temp(ccP.PixelIdxList{nRegP}) = 1;
                 markers(:,:,i-1) = markers(:,:,i-1)+ temp;
                 temp(:) = 0; 
             end
             
          end
          
          for nRegN = 1:size(ccN.PixelIdxList,2)
              oN = ismember(ccN.PixelIdxList{nRegN}, cc.PixelIdxList{nReg});
              if(sum(oN)>0)
                  temp(ccN.PixelIdxList{nRegN}) = 1;
                  markers(:,:,i+1) = markers(:,:,i+1) + temp;
                  temp(:) = 0;
              end
          end
          
          
          
       end
   end
   
   thisSlice = 4*imT(:,:,i-1)+2*imT(:,:,i+1)+ imT(:,:,i);
   %sleazy way of checking for overlap: overlapped regions will be where
   %1+2 = 3 and 1+4 = 5;
   
   prevS = thisSlice==5;
   nextS = thisSlice==3;
    
end



%Now remove any 3D regions that are touching the sides of the images in the
%x, y, or z direction

L = bwlabeln(markers);
%Remove all regions within 20 pixels of the boundary in the xy and in the last slice in the z direction
%-could maybe go for
%more. The goal is to prevent the creation of markers that might lead to
%regions touching the boundary. At the end we will also check for these
%types of regions.
index = 0; %This element will always be there to begin with
temp = L(1:20,:,:);
index = unique([index unique(temp)']);

temp = L(end-19:end,:,:);
index = [index unique(temp)'];

temp = L(:,1:20,:);
index = [index unique(temp)'];

temp = L(:,end-19:end,:);
index = [index unique(temp)'];

temp = L(:,:,1);
index = [index unique(temp)'];

temp = L(:,:,end);
index = [index unique(temp)'];

%Now remove all these elements
index = unique(index);

for i=1:length(index);
    removeIndex = find(L(:)==index(i));
    markers(removeIndex) = 0;
end



end
    