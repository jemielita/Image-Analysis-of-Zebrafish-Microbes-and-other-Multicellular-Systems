function val = opercleRatio(varargin)

if nargin==4
    minS = varargin{1};
    maxS = varargin{2};
    filePath = varargin{3};
    orient = varargin{4}; 
end

if nargin==1

    perim = varargin{1}; 
if(isempty(perim))
    val(1:4) = NaN;
    return;
end
    %single input function used to run through multiple averaging windows
    sP = length(perim);
    %  val  = zeros(4,1);
    [val(1), val(3)] = max(perim(1:floor(sP/2)));
    [val(2), val(4)] = min(perim(val(3)+1:floor(2*sP/3)));
    val(4) = val(4) +val(3);
    return
end



val = zeros(maxS-minS, 2);

for i=minS:maxS
    convex = load([filePath filesep 'OP_Scan', sprintf('%03d', i), 'convex.mat']);
    %  outline = load(['OP_Scan', sprintf('%03d', i), 'perim.mat']);
    try
        perim = convex.perim;
        sP = length(perim);
       
        if(orient == 1)
            %Flip perim-the front and back of the opercle were flipped.
           perim = flipud(perim); 
        end
         maxVal = max(perim(1:floor(sP/2)));
        %Find the min value later
        index = find(perim==maxVal);
        minVal = min(perim(index+1:floor(2*sP/3)));
        
        val(i, 1) = maxVal;
        val(i,2) = minVal;
    catch
        val(i,1) = -1;
        val(i,2) = -1;
    end
    
end

end