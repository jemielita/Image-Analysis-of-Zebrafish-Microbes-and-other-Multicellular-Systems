function [mask, centerLine] = curveMask(BW,line,param, type)

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
    
    for mComp=1:size(mask,3)
        isOverlap = unique(thisMask.*mask(:,:,mComp)>0);
        
        if(ismember(1, abs(isOverlap)))
            %Regions overlap, skip this mask for now,
            if(mComp<size(mask,3))
                continue %Continue comparing masks if you're not at the end of the array of masks.
            else
                mask(:,:,mComp+1) = thisMask; %Enlarge the array storing the masks.
            end
            
        else
            mask(:,:,mComp) = thisMask + mask(:,:,mComp);
            break
        end
        
    end
        
end

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
    function pos = getOrthVect(xx, yy, type,i)
        
        switch lower(type)
            
            case 'rectangle'
                x = xx(i)-xx(i-1);
                y = yy(i)-yy(i-1);
                xI = x+1;
                yI = y+2;
                
                Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
                
                xVal(1,:) = xx(i)+ Orth(1)*(100)*[-1, 1];
                yVal(1,:) = yy(i)+ Orth(2)*(100)*[-1,1];
                
                xVal(2,:) = xx(i+1)+ Orth(1)*(100)*[-1, 1];
                yVal(2,:) = yy(i+1)+ Orth(2)*(100)*[-1,1];
                
                
            case 'curved'
                x = xx(i)-xx(i-1);
                y = yy(i)-yy(i-1);
                xI = x+1;
                yI = y+2;
                
                Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
                
                xVal(1,:) = xx(i)+ Orth(1)*(100)*[-1, 1];
                yVal(1,:) = yy(i)+ Orth(2)*(100)*[-1,1];
                
                
                x = xx(i+1)-xx(i);
                y = yy(i+1)-yy(i);
                xI = x+1;
                yI = y+2;
                
                Orth = [xI yI] - ((x*xI + yI*y)/(x^2 +y^2))*[x y];
                
                
                xVal(2,:) = xx(i+1)+ Orth(1)*(100)*[-1, 1];
                yVal(2,:) = yy(i+1)+ Orth(2)*(100)*[-1,1];
                
                
        end
        
        pos = [xVal(1,1), yVal(1,1); xVal(1,2), yVal(1,2); xVal(2,2), yVal(2,2);...
            xVal(2,1), yVal(2,1)];
    end
