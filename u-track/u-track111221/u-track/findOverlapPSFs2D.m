function [clusters,errFlag] = findOverlapPSFs2D(cands,numPixelsX,numPixelsY,...
    psfSigma,visual,imageOriginal)
%FINDOVERLAPPSFS2D clusters 2D PSFs with overlapping intensities
%
%SYNOPSIS [clusters,errFlag] = findOverlapPSFs2D(cands,numPixelsX,numPixelsY...
%    psfSigma,visual,imageOriginal)
%
%INPUT  cands        : Cands structure as output from fsmCenter.
%       numPixelsX   : Number of pixels in x direction (image coord. system).
%       numPixelsY   : Number of pixels in y direction (image coord. system).
%       psfSigma     : Standard deviation of point spread function (in pixels).
%       visual       : 1 if user wants to view results, 0 otherwise. 
%                      Optional. Default: 0.
%       imageOriginal: Image being processed, for visualization. 
%                      Needed only if visual = 1.
%
%OUTPUT clusters     : Array of clusters of maxima. Structure with fields
%             .numMaxima: Number of maxima in cluster.
%             .maximaPos: Position of each maximum (in pixels). 1st and 2nd
%                         column: x,y-coordinates in image coordinate 
%                         system; 3rd column: linear index.
%             .maximaAmp: Intensity at each maximum.
%             .pixels   : All pixels making up a cluster. 3 columns like
%                         maximaPos.
%       errFlag      : 0 if function executes normally, 1 otherwise.

%Khuloud Jaqaman, August 2005

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

errFlag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check whether correct number of input arguments was used
if nargin < 4
    disp('--findOverlapPSFs2D: Incorrect number of input arguments!');
    errFlag  = 1;
    return
end

if nargin > 4 %if user wants to plot image with clusters
    
    if visual ~= 0 && visual ~= 1
        disp('--findOverlapPSFs2D: Variable "visual" should be 0 or 1!');
        errFlag = 1;
    end
   
    if visual == 1 && nargin ~= 6
        disp('--findOverlapPSFs2D: Must input image to be plotted!');
        errFlag = 1;
    end

else
    
    visual = 0;

end

%exit if there are problems in input data
if errFlag
    disp('--findOverlapPSFs2D: Please fix input data!');
    return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Clustering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%extract positions of significant local maxima from cands
tmp = vertcat(cands.Lmax);
cands2 = tmp([cands.status]==1,2:-1:1);
tmp = (cands2(:,1)-1)*numPixelsY + cands2(:,2);
maxPos0 = zeros(numPixelsY,numPixelsX);
maxPos0(tmp) = 1;

%extract the amplitudes of the significant local maxima
tmp = vertcat(cands.amp);
candsAmp = tmp([cands.status]==1);

%generate local maximum mask 
% template = GaussMask2D(psfSigma,8*ceil(psfSigma)-1,[0 0]);
% [psfRange] = size(template,1);
% psfRange = floor(psfRange/2);
% tmpSize = round(7*psfSigma);
tmpSize = round(9*psfSigma);
tmpSize = tmpSize + (1-mod(tmpSize,2));
template = ones(tmpSize);
psfRange = floor(tmpSize/2);

%place local maximum masks in image
image = zeros(numPixelsY+2*psfRange,numPixelsX+2*psfRange);
imageAmp = zeros(numPixelsY+2*psfRange,numPixelsX+2*psfRange);
for i=1:size(cands2,1)    
    x0 = cands2(i,1)+psfRange;
    y0 = cands2(i,2)+psfRange;
    ymin = y0-psfRange;
    ymax = y0+psfRange;
    xmin = x0-psfRange;
    xmax = x0+psfRange;
    image(ymin:ymax,xmin:xmax) = image(ymin:ymax,xmin:xmax) + template;
    imageAmp(ymin:ymax,xmin:xmax) = imageAmp(ymin:ymax,xmin:xmax) + template*candsAmp(i);
end
image = image(psfRange+1:end-psfRange,psfRange+1:end-psfRange);
imageAmp = imageAmp(psfRange+1:end-psfRange,psfRange+1:end-psfRange);

% %normalize image
% imageN = image/max(image(:));
% 
% %get connectivity between PSFs
% [L,nIsland] = bwlabel(imageN>0.001);

%get connectivity between local maximum masks
[L,nIsland] = bwlabel(image>0);

% initialize clusters (SB)
clusters(1:nIsland) = struct('numMaxima',[],'maximaPos',[],'maximaAmp',[],'pixels',[]);

%find number of local maxima and their centers and amplitudes in each island
for i=1:nIsland
    
    %get pixels making up island
    [rc] = find(L(:)==i);
    
    %find initial position of PSF centers in island (in pixels)
    rcCenterL = rc(maxPos0(rc)==1);
    rcCenter = [ceil(rcCenterL/numPixelsY) mod(rcCenterL,numPixelsY)];
    
    %determine initial number of PSFs in island
    numPSF0 = size(rcCenter,1);

    %determine initial amplitudes of PSFs
    ampPSF0 = imageAmp(rcCenterL);
    
    %collect data in structure
    clusters(i).numMaxima = numPSF0;
    clusters(i).maximaPos = [rcCenter rcCenterL];
    clusters(i).maximaAmp = ampPSF0;
    clusters(i).pixels = [ceil(rc/numPixelsY) mod(rc,numPixelsY) rc];
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%visualization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if visual

    %make 3 layers out of original image (normalized)
    imageOriginal = double(imageOriginal);
    imageNorm = imageOriginal/max(imageOriginal(:));
    imageN3 = repmat(imageNorm,[1 1 3]);
    
    %get set of colors for labeling
    color = jet(nIsland);

    %label maxima (each island has a different color
    for i=1:nIsland
        for j=1:3
            imageN3(clusters(i).maximaPos(:,3)+(j-1)*numPixelsY^2)=color(i,j);
        end
    end

    %plot image
    imtool(imageN3);

end


%%%%% ~~ the end ~~ %%%%%
