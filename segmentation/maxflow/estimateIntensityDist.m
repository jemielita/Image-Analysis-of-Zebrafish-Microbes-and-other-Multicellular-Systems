%Estimate the probability of a certain pixel being in the background or
%foreground using Bayes' Theorem
%
% P(I|'region') = P('region'|I)P(I) / P('region')
%
% This function is designed to do a binary segmentation on time series
% data (e.g. Opercle chang over time). The properly segmented image at the
% previous and next time step provide an estimate of P(I) and
% P('region'|I).
% Data will be used from all adjacent time points for which the images have
% been segmented.
%
% Author: Matthew Jemielita, July 19, 2012

function bayesIntenProb = estimateIntensityDist(imSeg, thisIm, bkgVal)
maxS = size(imSeg,1);
minS = 1;
numBoxes = 50;

%% Get the cropped image of the region of interest
currentIm = imcrop(imSeg{thisIm,5}, imSeg{thisIm,2});
%Get intensity distribution for all points in current image
allInten = currentIm(:);

inten = 0:0.02:1; %List of intensities at which we'll get a distribution

[probInten, inten] = hist(allInten,inten);

%probInten := P(I) in the function comments above
probInten = probInten/sum(probInten(:));
probInten = [probInten; inten];
    

%% Estimator if no previous segmentation has been done around the time point in question
if((thisIm==minS && isempty(imSeg{thisIm+1,5}) ) || ...
        (thisIm==maxS && isempty(imSeg{thisIm-1,5})) ||...
        (isempty(imSeg{thisIm-1,5}) && isempty(imSeg{thisIm+1,5}))  )
    
    %If we've placed down markers on this image use those to assign a
    %probability of being in the object or background
    currentIm = imSeg{thisIm,5};
    
    isObjInd = imSeg{thisIm,3};
    isObj = currentIm(isObjInd);
    
    isBkgInd = imSeg{thisIm,4};
    isBkg = currentIm(isBkgInd);
        
    probIntenBkg = hist(isBkg, inten);
   
    probIntenObj = hist(isObj, inten);
   
    
    %Make it so that dim and bright pixels are respectively binned with the
    %background and object-this ansatz won't work for some types of
    %segmentation.
    probIntenBkg(inten<bkgVal(1)+bkgVal(3)*bkgVal(2)) = max(probIntenBkg);

    ind = find(probIntenObj==max(probIntenObj));
    
    probIntenObj(inten>inten(ind)) = max(probIntenObj);

    %If these probabilities are zero then set the probability to be
    %uniform for all intensity values.
    if(sum(probIntenBkg)==0)
       probIntenBkg(:) = 1; 
       disp('No background markers placed: assigning a uniform probability');
    end
    probIntenBkg = probIntenBkg/sum(probIntenBkg);
    
    if(sum(probIntenObj)==0)
       probIntenObj(:) = 1; 
       disp('No object markers placed: assigning a uniform probability');
    end
    probIntenObj = probIntenObj/sum(probIntenObj);
    
    
    %Set maximum cost to be associated with any region to be 1.
    probIntenObj = (1/max(probIntenObj))*probIntenObj; 
    probIntenBkg = (1/max(probIntenBkg))*probIntenBkg; 
    %bayesIntenProbVal(1,:) = probInten(1,:).*probIntenBkg;
    %bayesIntenProbVal(2,:) = probInten(1,:).*probIntenObj;
    
    %Dropping out probInten so that low pixel values get assigned to bkg
    %appropriately.
    bayesIntenProbVal(1,:) = probIntenBkg;
    bayesIntenProbVal(2,:) = probIntenObj;
    
    bayesIntenProb{1,:} = {bayesIntenProbVal(1,:), inten};
    bayesIntenProb{2,:} = {bayesIntenProbVal(2,:), inten};
    
    %Normalizing prob. dist.
   % bayesIntenProb{1,:} = {bayesIntenProbVal(1,:)/sum(bayesIntenProbVal(1,:)), inten};
    %bayesIntenProb{2,:} = {bayesIntenProbVal(2,:)/sum(bayesIntenProbVal(2,:)), inten};
    
    return
end

%% Get the pixel intensity that correspond to background and objects
if(thisIm~=minS &&~isempty(imSeg{thisIm-1,5}))
    isObj = imSeg{thisIm-1,1};
    isObj = imcrop(isObj, imSeg{thisIm-1,2});
    
    isBkg  = ~isObj;
    
    prevIm = imSeg{thisIm-1,5};
    prevIm = imcrop(prevIm, imSeg{thisIm-1,2});
        
    objInten = prevIm(isObj);
    bkgInten = prevIm(isBkg);
    
    %Get number of pixels in background and object
    numObj(1) = sum(isObj(:)>0);
    numBkg(1) = sum(isBkg(:)>0);
else
    objInten = [];
    bkgInten = [];
    
    numObj(1) = NaN;
    numBkg(1) = NaN;
end

if(thisIm~=maxS && ~isempty(imSeg{thisIm+1,5}))
    isObj = imSeg{thisIm+1,1};
    isObj = imcrop(isObj, imSeg{thisIm+1,2});

    isBkg  = ~isObj;
    
    nextIm = imSeg{thisIm+1,5};
    nextIm = imcrop(nextIm, imSeg{thisIm+1,2});
   
    objInten = [objInten; nextIm(isObj)];
    bkgInten = [bkgInten; nextIm(isBkg)];
    
    %Get number of pixels in background and object
    numObj(2) = sum(isObj(:)>0);
    numBkg(2) = sum(isBkg(:)>0);
else
    numObj(2) = NaN;
    numBkg(2) = NaN;
end
%These two probabilities give P('region'|I) in the notes to the function
%above
probIntenBkg = hist(bkgInten, inten);

%Find any entries that correspond to intensities less than mean + std
%deviation of camera background noise. Set these entries equal to the
%maximum probability for this distribution.  This is an attempt to deal
%with uneven illumination in the sample


probIntenBkg(inten<bkgVal(1)+bkgVal(3)*bkgVal(2)) = max(probIntenBkg);

probIntenBkg = [probIntenBkg/sum(probIntenBkg(:)) ; inten];

probIntenObj = hist(objInten, inten);
probIntenObj = [probIntenObj/sum(probIntenObj(:)) ; inten];


%% Get the probability of a pixel being in the background or objet
%Based on the number of pixels that correspond to the region and background
%This gives P('region') in the header to this function.
numPixels = numObj+numBkg;
probBkgAll = numBkg./numPixels;

probBkg = nanmean(probBkgAll);

probObjAll = numObj./numPixels;
probObj = nanmean(probObjAll);

%% Calculate P(I|'region') for the image we're looking at


%for i=1:length(onlyInten)
%   ind(i) = find( abs(onlyInten(i)-probIntenBkg(2,:))==min(abs(onlyInten(i)-probIntenBkg(2,:)))); 
%end
indBkg = cell2mat(arrayfun(@(inten)(...
    find(min(abs(inten-probIntenBkg(2,:))) == abs(inten-probIntenBkg(2,:)) )  ),...
    inten, 'UniformOutput', false));

indObj = cell2mat(arrayfun(@(inten)(...
    find(min(abs(inten-probIntenObj(2,:))) == abs(inten-probIntenObj(2,:)) )  ),...
    inten, 'UniformOutput', false));
 
 bayesIntenProbVal(1,:) = (probInten(1,:)/probBkg).*(probIntenBkg(1,indBkg));
 bayesIntenProbVal(2,:) = (probInten(1,:)/probObj).*(probIntenObj(1,indObj));


%Normalizing prob. dist.
bayesIntenProb{1,:} = {bayesIntenProbVal(1,:)/sum(bayesIntenProbVal(1,:)), inten};
bayesIntenProb{2,:} = {bayesIntenProbVal(2,:)/sum(bayesIntenProbVal(2,:)), inten};

%Doing a simpler calculation of the probability distribution-this stuff
%above is nice, but the result will be biased by the size of the cropping
%window etc..

%Normalizing height of each distribution to each other (note: thiswi

ind = find(probIntenObj(1,:)==max(probIntenObj(1,:)), 1,'last');
probIntenObj(1,inten>inten(ind)) = max(probIntenObj(1,:));


ind = find(probIntenBkg(1,:)==max(probIntenBkg(1,:)),1,'first');
probIntenBkg(1,inten<inten(ind)) = max(probIntenBkg(1,:));


%Set maximum cost to be associated with any region to be 1.
probIntenObj(1,:) = (1/max(probIntenObj(1,:)))*probIntenObj(1,:);
probIntenBkg(1,:) = (1/max(probIntenBkg(1,:)))*probIntenBkg(1,:);

bayesIntenProb{1,:} = {probIntenBkg(1,:), inten};
bayesIntenProb{2,:} = {probIntenObj(1,:), inten};


end