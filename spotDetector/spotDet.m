function varargout = spotDet(img, nBands, dthreshold, postProcLevel)

if nargin<2
nBands=4;
end
if nargin<3
    dthreshold = 5;
end
if nargin<4
    postProcLevel = 1;
end

maxI = max(img(:));
minI = min(img(:));
[ny nx] = size(img);

%===================================================
% Iterative filtering from significant coefficients
%===================================================
imgDenoised=cv.significantCoefficientDenoising(img,nBands);
imgDenoised=double(imgDenoised);

res = img - imgDenoised; % residuals
%sigma_res0 = std(res(:));

%delta = 1;

%Keep on iterating algorithm until the difference in the result is below
%some threshold (0.002 is probably an arbitrary choice)
%n = 1;

%frameInfo = 0;

%Ignore all iterations and output the first pass-it's pretty good!
resDenoised = cv.significantCoefficientDenoising(res, nBands);
resDenoised = double(resDenoised);
imgDenoised = imgDenoised + resDenoised; % add significant residuals
%********************************************************************

if(nargout==1)
   varargout{1} = imgDenoised; 
   return
end


% New Method for transforming image
% W = zeros(size(img,1), size(img,2), S + 1);
% [W(:,:,1), W(:,:,2), W(:,:,3), W(:,:,4), W(:,:,5), junk] = cv.awtC(imgDenoised, S);
% % Old Method for transforming image
% %W=awt(imgDenoised, S);
% 
% imgMSP = abs(prod(W(:,:,1:S),3));

%===================================================
% Multiscale product of wavelet coefficients
%===================================================
imgMSP=cv.awtC(imgDenoised,nBands);
%********************************************************************

%===================================================
% Binary mask
%===================================================
% Establish thresholds
[imAvg, imStd] = localAvgStd2D(imgDenoised, 55);

mask = zeros(ny,nx);
%In the second argument, why no reference to the std of imgDenoised? Is it
%because values away from the std. have already been cut off by the
%iterative procedure used?
mask((imgDenoised >= imAvg+0.5*imStd) & (imgDenoised.*double(imgMSP) >= mean(imgDenoised(:)))) = 1;

% Morphological postprocessing
mask = bwmorph(mask, 'clean'); % remove isolated pixels
mask = bwmorph(mask, 'fill'); % fill isolated holes
mask = bwmorph(mask, 'thicken');
mask = bwmorph(mask, 'spur'); % remove single pixels 8-attached to clusters
mask = bwmorph(mask, 'spur');
mask = bwmorph(mask, 'clean');

mask = bwareaopen(mask, 70);

if(nargout==2)
   varargout{1} = imgDenoised;
   varargout{2} = mask;
end

end