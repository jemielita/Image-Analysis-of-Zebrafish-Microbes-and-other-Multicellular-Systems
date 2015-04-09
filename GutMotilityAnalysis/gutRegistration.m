% Function which registers images only among a subset of translations
% symmetric about the center by a linear total size of sizeToSearch
%
% Inputs: im1: reference, fixed image
%         im2: moving image
%         sizeToSearch: number representing the size of the side of a box
%         in which to search for a correlation
%
% Outputs: im3: registered image

function im3 = gutRegistration(im1, im2, im2Fake, sizeToSearch)

% Initialize variables
halfS=round(sizeToSearch/2);

% Do correlation search
corrT=normxcorr2(im2Fake,im1);

% Make subset correlation map equal in size to original image
imCenter = floor(size(im2)./2);
corrCenter = size(im1);
sCorrT = corrT([false(1,imCenter(1)) true(1,corrCenter(1))], ...
        [false(1,imCenter(2)) true(1,corrCenter(2))]); % Opaque but good
    
% Search for max only in subspace of sizeToSearch (symmetric around center)
corrRs=[false(1,imCenter(1)-halfS) true(1,sizeToSearch)];
corrCs=[false(1,imCenter(2)-halfS) true(1,sizeToSearch)];
%sCorrT(corrRs, corrCs)=min(sCorrT(:));
%[xC,yC]=find(sCorrT==max(max(sCorrT(corrRs, corrCs))));
[rCT,cCT]=find(sCorrT(corrRs,corrCs)==max(max(sCorrT(corrRs, corrCs))));
r=rCT-halfS;
c=cCT-halfS;

tMat=[1,0,0;0,1,0;c,r,1];
reT=affine2d(tMat);
im3=imwarp(im2,reT,'OutputView',imref2d(size(im1)));

end