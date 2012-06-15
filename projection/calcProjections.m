%Calculate the projetions for a series of scans and save the result
%NEED TO CLEAN THIS UP!!!!


function [] = calcProjections(param)
%Initially assume that we're going to do this for all the scans

%Make a location to save the data
param.dataSaveDirectory = [param.directoryName filesep 'gutOutline'];
if(~isdir(param.dataSaveDirectory))
    mkdir(param.dataSaveDirectory);
end

numColor = length(param.color);
numScans = param.expData.totalNumberScans;
for nS =1:numScans
    disp(['Calculating mip for scan ', num2str(nS)]);
    for nC=1:numColor
        imVar.color =param.color{nC};
        imVar.zNum = '';%Won't need this for mip
        imVar.scanNum = nS;
 
        im{nC} = selectProjection(param, 'mip',1, imVar);
  

       fprintf(2, '\n'); 
    end
    %Then save the result
    saveName = [param.dataSaveDirectory, filesep, 'FluoroScan_', num2str(nS),'.mat'];
    save(saveName, 'im');
end



end