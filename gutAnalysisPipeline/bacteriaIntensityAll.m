%bacteriaIntensity: For a given set of fish scanned in which bacteria were
%outlined combine together the resulting bacterial intensities to get
%better statistics.
%
%Note: should also do checks to see if the distributions of intensities are
%reasonably consistent across time and between fish
%
% USAGE
%[bacInten, bacCutoff] = bacteriaIntensityAll(paramAll, maxInten, stepInten, numColor,plotResults)
%
% INPUT: paramAll: cell array containing a number of different param files
% to draw our analysis from
%        maxInten: maximum intensity for the histogram of bacterial
%        intensities
%        stepInten: step size for our histogram of bacterial intensities
%        numColor: number of colors to be analyzed
%        plotResults: show the bacteria in this cropping region and allow
%        the user to alter the number of bacteria in the image
%
% OUTPUT: bacInten: histogram of bacteria intensities
%         bacCutoff: intensity bin locations for bacInten
%         
%
% AUTHOR Matthew Jemielita, Novemer 13, 2012

function [bacSum,bacInten, bacCutoff,bacMat,bacScan,bacHist,paramAll] =  bacteriaIntensityAll(paramAll, maxInten, stepInten, numColor,plotResults)

%For every param file in the cell array of param files
bacCutoff = 100:stepInten:maxInten;
bacInten = cell(numColor,1);

bacMat =cell(numColor,1);
bacMat{1} = nan*zeros(length(bacCutoff),100);
bacMat{2} = bacMat{1};
bacHist = bacMat;

bacSum = cell(2,1);
m = 1;
%Handle to imcontrast, which might be used
if(plotResults==true)
    hFig = figure;
    hAxis = axes('Parent', hFig);
    hIm = imshow(rand(100,100), 'Parent', hAxis);
    
    %Move the box out of the way a bit
    hPos = get(hFig, 'Position');
    set(hFig, 'Position', [hPos(1)-400, hPos(2), hPos(3), hPos(4)]);
    
    hCon = imcontrast(hFig);
end

for nC=1:numColor
    n= 1;
    m=1;
    for nP = 1:length(paramAll)
        param = paramAll{nP};
        
        if(~isfield(param, 'bacInten'));
            continue;
        end
        %Go through every color and scan file
        if(isempty(param.bacInten))
            continue;
        end

        for nS =1:size(param.bacInten,1)
            if(isempty(param.bacInten{nS, nC}))
                continue;
            end
            for nB = 1:length(param.bacInten{nS,nC})
                %Load in image of this bacteria
                
                imVar.scanNum = nS; imVar.color = param.color{nC};
                
                thisIm = load3dVolume(param, imVar, 'crop', param.bacInten{nS, nC}(nB).rect);
                numBact = param.bacInten{nS,nC}(nB).numBac;
                
                
                if(plotResults==true)
                    set(hIm, 'CData', max(thisIm,[],3));
                    title([param.directoryName]);
                    xlabel(sprintf(['_ Number bacteria ',num2str(param.bacInten{nS,nC}(nB).numBac), ' ',param.color{nC}]));
                    
                    answer = inputdlg('How many bacteria are in this box (-1 to adjust contrast)?', 'Bacteria count', ...
                        1, {num2str(numBact)});
                    numBact = str2num(answer{1});
                    
                    %Update the param file
                    param.bacInten{nS,nC}(nB).numBac = numBact;
                    if(numBact == -1)
                        %Allow user to adjust image contrast and count
                        %bacteria again
                        pause
                        answer = inputdlg('How many bacteria are in this box (-1 to adjust contrast)?', 'Bacteria count', ...
                            1, {num2str(numBact)});
                        numBact = str2num(answer{1});
                        
                        param.bacInten{nS,nC}(nB).numBac = numBact;
                    elseif(numBact == 0)
                       %There was an error in outlining bacteria-not using
                       %this one
                       disp('No bacteria!');
                       continue;
 
                    end
                end
               
                %For each of these bacteria see how well the background is
                %described by camera noise.
                %Quick and dirty way of doing this: see if the bottom 50%
                %of the pixels are within a given number of standard
                %deviations of camera background.
                camBkg =[103.10,102.27];
                if(numBact~=0)
                    bacSum{nC}(m) = sum(thisIm(:))-size(thisIm,1)*size(thisIm,2)*size(thisIm,3)*camBkg(nC);
                    bacSum{nC}(m) = bacSum{nC}(m)/numBact;
                    m = m+1;
                end
%               imSum = sum(thisIm,3);
%               figure; imshow(mat2gray(sum(thisIm,3)),[]); imcontrast;
%               figure; hist(double(mat2gray(imSum(:))),200);
%               
%               close all
              
                
                
                
               %Total intensity of this bacteria for a given cutoff lower
               %pixel intensity
                for nCut=1:length(bacCutoff)
                    bacMat{nC}(nCut,n) = sum(thisIm(thisIm>bacCutoff(nCut)))/numBact;
                end
                bacHist{nC}(:,n) = hist(double(thisIm(:)), bacCutoff)/numBact;
                bacScan{nC}(n) = nS;
                n = n+1;
                
            end
        end
        
        %Update the param file
       paramAll{nP} = param; 
    end
    
    bacInten{nC} = nanmean(bacMat{nC},2);
   

end


if(plotResults==true)
    close(hFig);
end
end