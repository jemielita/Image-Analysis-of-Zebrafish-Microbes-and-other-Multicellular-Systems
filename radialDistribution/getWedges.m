%


function wedges = getWedges(radialMask, radialIm, param, varargin)

%Reading in the variables
if nargin ==3
   L = bwlabel(radialMask);
   props = regionprops(L);
   center = props.Centroid;
   numWedges = 12;
end

if nargin==4
    center = varargin{1};
    numWedges = 12; %Default to 12 wedges
end

if nargin==5
    center = varargin{1};
    numWedges = varargin{2};
end
     
%Creating the wedges
theta = (2*pi/numWedges)*(1:numWedges);


%Looping through all the wedges, get a line for edge of the wedges that is
%as large as the image itself.

for i=1:numWedges
    length = 1;
    posX(i) = center(1);
    posY(i) = center(2);
    
    while((posX(i)>0 && posX(i)<=size(radialMask,1)) &&(posY(i)>0 &&...
            posY(i)<size(radialMask,2)))
        
        posX(i) = center(1)+length*cos(theta(i));
        posY(i) = center(2)+length*sin(theta(i));
        length = length+1;
    end
    %Get the previous position
    posX(i) = center(1) +(length-2)*cos(theta(i));
    posY(i) = center(2) + (length-2)*sin(theta(i));
    
end


%Now go through each of these wedges and add to a label matrix for it.

wedges = zeros(size(radialMask));

for i=1:numWedges
    if i==1
       j = numWedges; 
    else
        j = i-1;
    end
    
    posXW = [posX(j),posX(i), center(1)];
    posYW = [posY(j), posY(i),center(2)];
    
    wedgeMask = poly2mask(posXW, posYW, size(radialMask,1), size(radialMask,2));
    wedgeMask = logical(wedgeMask.*radialMask);
    
    wedges(wedgeMask) = i;
    
end


end