%Implements a graph cut based image segmentation algorithm
%
%Code wraps around a MATLAB wrapper (maxflow.m written by Michael
%Rubinstein) for a Max-flow/min-cut algorithm that implements
%Boykob-Kolmogorov's algorithm.
%
%-Might have to alter Rubinstein's code a bit to fully use features of the
%underlying algorithm...we'll what happens when we get to that point.
%
% USAGE graphCut()
%       graphCut(im);
%       graphCut(im, maskSource, maskSink);
%       graphCut(im, maskSource, maskSink, intenHist);
%       graphCut(im, maskSource, maskSink, intenHist, lambda, bkgNoise);
%       graphCut(im, maskSource, maskSink, intenHist, lambda, bkgNoise, dim);


%Written by: Matthew Jemielita, July 13, 2012

function varargout = graphCut(varargin)


%Default dimension 
dim = 2;

%Before doing anything with more complicated images, let's use a simple
%test image
if(nargin==0)
height = 100;
width = 100;

im = rand(height,width);
im(50:60, 50:60) = im(50:60,50:60)+1;

end

if(nargin==1)
    im = varargin{1};
    
    figure; imshow(im,[]);
    
    %Put down a boundary outside the opercle
    hPolyOut = impoly(gca, 'Closed', true);
    posOut = wait(hPolyOut);
    maskSink = ~poly2mask(posOut(:,1), posOut(:,2), size(im,1), size(im,2));
    
    %Put a marker inside the opercle
    hPolyIn = impoly(gca, 'Closed', true);
    posIn = wait(hPolyIn);
    maskSource = poly2mask(posIn(:,1), posIn(:,2), size(im,1), size(im,2));
    
        %Weights for segmentation
    lambda = 0.001;
    bkgNoise = 0.01;
        %Use inside marker to estimate the background intensity inside the opercle
    %(should do this slightly different in the future)
    isSource = find(maskSource==1);
    isSink = find(maskSink==1);
    [sourceHist, sinkHist] = regionIntensityEstimation(im, isSource, isSink);

end

if(nargin>=3)
    im = varargin{1};
    maskSource = varargin{2};
    maskSink = varargin{3};
    
    %Use inside marker to estimate the background intensity inside the opercle
    %(should do this slightly different in the future)
    isSource = find(maskSource==1);
    isSink = find(maskSink==1);
end

if(nargin==3)    
   
    %Based on pixel intensities inside and outside regions of interest, get a
    %probability distribution for a given pixel's intensity to be in the source
    %or sink.
    [sourceHist, sinkHist] = regionIntensityEstimation(im, isSource, isSink);

    %Weights for segmentation
    lambda = 0.01;
    bkgNoise = 0.01;
    
end
if(nargin==4)
    intenEst = varargin{4};
    sinkHist{1} = intenEst{1,1};
    sinkHist{2} = intenEst{1,2};
    
    sourceHist{1} = intenEst{2,1};
    sourceHist{2} = intenEst{2,2};
    
    %Weights for segmentation
    lambda = .1;   
    bkgNoise = .1;     
end

if(nargin==6)
    intenEst = varargin{4};
    sinkHist = intenEst{1,:};
    sourceHist = intenEst{2,:};
    
    %Weights for segmentation
    lambda = varargin{5};
    bkgNoise = varargin{6};
    
   
end

if(nargin==7)
    intenEst = varargin{4};
    sinkHist = intenEst{1,:};
    sourceHist = intenEst{2,:};
    
    %Weights for segmentation
    lambda = varargin{5};
    bkgNoise = varargin{6};
   
    dim = varargin{7};
    
    
end

%Construct a graph

im = mat2gray(im);

switch dim
    case 2
        [height, width] = size(im);
        N = height*width;
        E = edges4connected(height,width);

    case 3
        [height, width, depth] = size(im);
        N = height*width*depth;
        E = edges4connected(height,width,depth);

end

V = assignBoundaryPenalty(E,im,bkgNoise, 'undirected');

A = sparse(E(:,1),E(:,2),V,N,N,4*N);

%Set terminal weights.
%Note: this will in the future we a user-chosen region, or  predict based
%on previous images in the time series.

%1+maximum cost for any intensity pixel-pixel link on the image.
%Used to assign the cost of a pixel to be in the source/sink when we've
%declared to be in the sink/source. This should guarantee that that
%particular link is cut.
K = 1+max(V(:));
%Need to find an optimal value for lambda. For opercles it seems like a
%rather low value is appropriate

T = setRegionPenalty(isSource, isSink, sourceHist, sinkHist,im,K,lambda);

[flow, labels] = maxflow(A,T);
labels = reshape(labels, [height width]);

displayData = false;
if(displayData==true)
figure;  imshow(4*double(labels)+3*im+maskSource,[]);

figure; imshow(im,[]);
alphamask(bwperim(maskSource),[1 0 0]);
alphamask(bwperim(double(labels)),[0 1 0]);
end
if(nargout==1)
    varargout{1} = labels;
end

end

function [sourceHist, sinkHist] = regionIntensityEstimation(im, isSource, isSink)

%Return the probability of a pixel being within a certain intensity range
%if it's in the source.
[sourceHistProb, sourceHistVal]= hist(double(im(isSource)),50);
sourceHist = sourceHistProb/sum(sourceHistProb(:));
sourceHist = {sourceHist, sourceHistVal};

%If it's in the sink: 

%Use the region in isSink to set the background pixel-not really an optimal
%way to do it if there is extra fluorescence signals out there
[sinkHistProb, sinkHistVal]= hist(double(im(isSink)),50);
sinkHist = sinkHistProb/sum(sinkHistProb(:));
sinkHist = {sinkHist, sinkHistVal};

end

function T = setRegionPenalty(isSource, isSink, sourceHist, sinkHist,im,K, lambda)
%Create sparse array that contains these points
numElIm = length(im(:));
%Assign the cost of assigning any given pixel i to either regions 1 or 2.
%T(i,region) = cost of assigning to region
%Two sources of this cose:
%1) Pixel has been hard coded to be in the source (1) or sink(2)
%2) Pixel cost based on intensity distribution

sourceCost = zeros(length(im(:)),1)+eps;
sinkCost = sourceCost;

%Penalties for being in source or sink
sourceCost(isSink) = K;
sinkCost(isSource) = K;

%Find pixels that are not in the source or sink
pixelInd = setdiff(1:numElIm, [isSource;isSink]);

%Estimate whether pixel is drawn from background (sink) pixel intensity or region
%(source) pixel intensity
pixelInten = im(pixelInd);

%% Probability that a given pixel is in the source

%Index in sourceHist that each pixel intensity is closest to.
indexSource= cell2mat(arrayfun(@(pixelInten)find(...
    abs(pixelInten-sourceHist{2})==min(abs(pixelInten-sourceHist{2})),...
    1,'first'), ...
    pixelInten,'UniformOutput', false));
%Probability that the pixel would have that intensity if it's in the source
probSource = cell2mat(arrayfun(@(indexSource)sourceHist{1}(indexSource),...
 indexSource,'UniformOutput', false));
%take the -log(probSource); to follow the background estimation used in:
%"Graph cuts and efficient N-D Image segmentation"
probSource = -log(probSource);

%% Probability that a given pixel is in the sink
%Index in sinkHist that each pixel intensity is closest to.
indexSink = cell2mat(arrayfun(@(pixelInten)find(...
    abs(pixelInten-sinkHist{2})==min(abs(pixelInten-sinkHist{2})),...
    1,'first'), ...
    pixelInten,'UniformOutput', false));
%Probability that the pixel would have that intensity if it's in the source
probSink = cell2mat(arrayfun(@(indexSink)sinkHist{1}(indexSink),...
 indexSink,'UniformOutput', false));
%take the -log(probSource); to follow the background estimation used in:
%"Graph cuts and efficient N-D Image segmentation"
probSink = -log(probSink);


%% Assign cost for pixels being attached to source or sink based on intensity
sourceCost(pixelInd) = lambda*probSource;
sinkCost(pixelInd) = lambda*probSink;

%% Assign all costs to sparse array
%Array size = 2*number of elements in image (2*numElIm)
%Assign cost to sparse array of size = 2*number of elements in image (2*numElIm)
%Elements 1:numElIm cost of being attached to source
%Elements numElIm+1:2*numElIm cost of being attached to sink
T = sparse([1:numElIm, 1:numElIm], [1*ones(numElIm,1); 2*ones(numElIm,1)],...
    [sourceCost; sinkCost]);

end

function V = assignBoundaryPenalty(E,im, bkgNoise, weightType)

%Harsh penalty for difference in pixel difference > bkgNoise, but very small if
%pixel difference < bkgNoise. Need to measure this noise.

%For a directed graph

switch weightType
    
    case 'directed'
        intenDiff = im(E(:,1))-im(E(:,2));
        V = ones(size(intenDiff,1),1);
        V(intenDiff>0) = exp(-(1./bkgNoise^2)*(im(E(intenDiff>0,1))-im(E(intenDiff>0,2)) ).^2  );
    case 'undirected'
         V = exp(-(1./bkgNoise^2)*(im(E(:,1))-im(E(:,2)) ).^2  );
end


end
