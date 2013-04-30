% [frameInfo imgDenoised] = detectSpotsWT(img, S, dthreshold, postProcLevel)
%
% Performs detection of local intensity clusters through a combination of 
% multiscale products and denoising by iterative filtering from
% significant coefficients:
% Olivo-Marin, "Extraction of spots in biological images using multiscale products," Pattern Recoginition 35, pp. 1989-1996, 2002.
% Starck et al., "Image Processing and Data Analysis," Section 2.3.4, p. 73
%
% INPUTS:   img             : input image (2D array)
%           {S}             : postprocessing level.
%           {dthreshold}    : minimum allowed distance of secondary maxima in large clusters
%           {postProcLevel} : morphological post processing level for mask 

% Parts of this function are based on code by Henry Jaqaman.
% Francois Aguet, March 2010

function [frameInfo imgDenoised] = spotDetector(img, S, dthreshold, postProcLevel)

if nargin<2
    S = 4;
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

%Create arrays on GPU for processing images

%Moving img onto the GPU
img = gpuArray(img);

W = gpuArray(zeros(size(img,1), size(img,2), S+1));
mask = gpuArray(zeros(size(img)));
result = gpuArray(zeros(size(img)));

imgDenoised = significantCoefficientDenoising(img, S,result, mask,W);

res = img - imgDenoised; % residuals
sigma_res0 = std(res(:));

delta = 1;

%Keep on iterating algorithm until the difference in the result is below
%some threshold (0.002 is probably an arbitrary choice)
n = 1;

frameInfo = 0;

%Ignore all iterations and output the first pass-it's pretty good!
resDenoised = significantCoefficientDenoising(res, S,result, mask,W);
imgDenoised = imgDenoised + resDenoised; % add significant residuals

end

%=======================
% Subfunctions
%=======================
    function result = significantCoefficientDenoising(img, S,result, mask,W)
        
       % mask = zeros(size(img));
       % result = zeros(size(img));
        W = awt(img, S,W);
     %   W = awt_test(img, S,W);
        mask(:) = 0;
        result(:) = 0;
        for s = 1:S
            %   result(:) = 0;
            regInd = gpuArray(find(~isnan(W(:,:,s))));
            
            tmp1 = W(:,:,s); tmp = tmp1(regInd);
            
            %tmp(isnan(tmp)) = [];  tmp1(isnan(tmp1)) = 0;
            
            
            %tmp(~regMask) =[]; tmp1(~regMask) = 0;
            
            normV =length(tmp(:));
            meanV = sum(tmp(:))/normV;
            
            stdV = sqrt(1/normV)*norm(tmp(:)-meanV);
            mask(abs(tmp1) >= 3*stdV) = 1;
            result = result + tmp1.*mask;
            
            %     nansum(result(:))
            
            %   result(:) = 0;
           
% %Using masks
% tmp1 = W(:,:,s); tmp = tmp1;
%         %    tmp(isnan(tmp)) = [];  tmp1(isnan(tmp1)) = 0;
%          %   tmp(regMask) =[]; tmp1(regMask) = 0;
%           
%             
%             
%             normV =length(tmp(regInd));
%             meanV = sum(tmp(regInd))/normV;
% 
%             stdV = sqrt(1/normV)*sqrt(sum(( tmp(regInd)-meanV).^2)  );
%             mask(abs(tmp) >= 3*stdV) = 1;
%             result = result + tmp1.*mask;
%             nansum(result(:))
%            figure; imshow(result,[]); title('Sped-up code');
%                        result(:) = 0;

           %Original code
%            
%            tmp = W(:,:,s);
%             mask(abs(tmp) >= 3*nanstd(tmp(:))) = 1;
%             result = result + tmp.*mask;
         %   nansum(result(:))
%            %figure; imshow(result,[]); title('Original code');
        end
        
    end

