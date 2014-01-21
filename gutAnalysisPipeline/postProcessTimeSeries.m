%postProcessTimeSeries: Process the time series data further to produce our
%gut population numbers.
%
% USAGE postProcessTimeSeries(analysisType, scanParam, param, processType)
%
% INPUT analysisType, scanParam, and Param are the usual inputs for our
%       analysis pipeline, in a cell array.
%       processType: (optional. Default: 'all') Set of postprocessing 
%       steps to do. Currently we'll only support doing everything, but
%       more flexibility will be built in over time.
%
% AUTHOR Matthew Jemielita, January 2, 2013

function postProcessTimeSeries(analysisType, scanParam, pAll, processType)

%% Get analysis variables
%mlj: need to deal with distinction between cell array and
%individual analysis param
numFish = length(pAll);




%% Go through different processing types

for nP =1:length(processType)
   
    switch processType{nP}
        case 'spot'
            %First level of processing for bacterial spots
            pAll = processBacteriaSpots(pAll)
            
    end
end


%% Get histogram of bacterial intensities
fprintf(1, 'postProcess step 2: Verifying user-selected bacteria.\n');

numColor = 2;
%Ideally these are set by the distribution itself...
stepInten = 25; %Step size for the bacterial intensity histogram
maxInten = 5000; %Maximum intensity for bacterial intensity histogram
%If plotResults == true we can verify the number of bacteria in each of
%these images and adjust the results accordingly.
plotResults = true; 

%Update pAll with any corrected bacteria intensities.
[bacSum,bacInten, bacCutoff,bacMat, bacScan,bacHist,pAll] = ...
    bacteriaIntensityAll(pAll, maxInten, stepInten,numColor, plotResults);

bacMean = [mean(bacSum{1}) mean(bacSum{2})];


%% Get the background estimation for all the fish
%bkgInten gives the estimated background at each point along the gut,
%threshCutoff gives the appropriate index to plot in plot_gut
%Format: bkgInten{nP}{nC}{nS}
fprintf(1, 'postProcess step 3: Estimating background intensity in each fish.\n');

bkgInten = estimateBkg(pAll,'',1);

%% Assemble 1D information and regional population
fprintf(1, 'postProcess step 4: Assembling 1D gut information.\n');

bkgOffsetRatio = 1.5;%First estimate
popTot = cell(length(pAll),1); popXpos = cell(length(pAll),1); bkgDiff = cell(length(pAll),1);
for nP = 1:length(pAll)
    minS = 1;
    maxS =pAll{nP}.expData.totalNumberScans;
    [~, ~, bkgDiff{nP}] = ...
        assembleDataGutTimeSeries(pAll{nP}, 1, maxS, bacMean, bkgInten{nP}, bkgOffsetRatio,'','',2);
end
for nP=1:length(pAll)
    %   Estimate the background to subtract
    maxScan = [15,1,15,10,1]; %Maximum scan before the channel that's ~empty shows up
    emptyColor = 2;
    minS = 1;
    maxS = pAll{nP}.expData.totalNumberScans;
   % bkgOffsetRatio = getBackgroundRatio(bkgDiff, maxScan, emptyColor);
   bkgOffsetRatio =1.5;
    [popTot{nP}, popXpos{nP}, bkgDiff{nP}] = ...
        assembleDataGutTimeSeries(pAll{nP}, minS, maxS, bacMean, bkgInten{nP}, bkgOffsetRatio,'','',2);
end
% Assemble populations for different points in the gut
for nP=1:length(pAll)
   [popDiffReg{nP}, regInd{nP}] = assembleDiffRegPop(pAll{nP}, popXpos{nP});
end

%% Getting single count data
cList = [1,2];
for nP=1:length(pAll)
   [fineLine{nP}, fineLineTotal{nP}] = get1DLineSpotDetection(pAll{nP}, [pAll{nP}.dataSaveDirectory filesep 'singleBacCount'],...
       true,cList); 
   
end

%% Combine together fine and course analysis

combPoint(1) = NaN;
combPoint(2) = NaN;
combPoint(3) = NaN;
combPoint(4) = NaN;
combPoint(5) = NaN;
combPoint(6) = NaN;

%Minimum scan is the point where there are no appreciable clumps and we can
%use the fine analysis by itself. This time point is somewhat rough.
maxSList = [47, 46, 47, 47, 47, 47];
minSList = [1, 28,37, 31,25,26];


for nF= 2:6
    maxS = maxSList(nF);
    for nC = 2:2

        
        for nS = 1:maxS
            
            
            maxL = pAll{nF}.gutRegionsInd(nS,3);
            
            fineData =  fineLine{nF}{nS, nC}(1:maxL);
            courseData = popXpos{nF}{nS, 1}(1,1:maxL);
            
          
            comp = courseData(1,:)>fineData;
            
            finalPop = fineData;

            
            
            if(nS>minSList(nF))
                finalPop(comp) = courseData(1,comp);
            else
                finalPop = fineData;
            end
            finalPop = finalPop(1:maxL);           
            totPop{nF}(nS,nC) = sum(finalPop);
            combPop{nF}{nS, nC} = finalPop;
        end
    end
end
    

end


    function pAll = processBacteriaSpots(pAll)        
        %% Unpack found bacteria spots
        fprintf(1, 'postProcess: Unpacking all found bacterial spots\n');
        
        numFish = length(pAll);
        for nF=1:numFish
            bacteriaCountTimeSeries(pAll{nF}, 'firstpass', 'defaultCullProp')

        end            
            pAll{nF}.gutRegionsInd = findGutRegionMaskNumber(pAll{nF}, true);
            %Update lables for each bacteria
            findGutSliceParticle(pAll{nF});
 
    end


