%calcProjections: Calculate the projetions for a series of scans and save the result
%
%USAGE:
% 
% [] = calcProjections(param, scanList, colorList, saveDirectory,saveType)
% []= calcProjections(param)
%       Note: With this call scanList and colorList will be the maximum
%       number of scans and colors in the directory. The save directory
%       will be in the subfolder gutOutline of the save directory for all
%       the data from this scan. The save type will be 'tiff'
%INPUT: param: parameter file for a scan of a fish
%       scanList: array containing all the scans that we want to calculate
%       a maximum intensity projection for.
%       colorList: cell array containing the string for all the colors that
%       we want to analyze: e.g. '488nm', '568nm', etc.
%       saveDirectory: directory in which to save the MIPs.
%       saveType: 'tiff' or 'mat': format to save the MIP as.
%
%NOTE: This function will overwrite any MIP's found in the directory
%saveDirectory without being prompted!
%AUTHOR Matthew Jemielita, Oct 31, 2012

function [] = calcProjections(varargin)

if(nargin==1)
    param = varargin{1};
    %Initially assume that we're going to do this for all the scans
    
    %Make a location to save the data
    param.dataSaveDirectory = [param.directoryName filesep 'gutOutline'];
    if(~isdir(param.dataSaveDirectory))
        mkdir(param.dataSaveDirectory);
    end
    
    numColor = length(param.color);
    numScans = param.expData.totalNumberScans;
    scanList = 1:numScans;
    saveType  = 'tiff';
    colorList = param.color;
    
elseif(nargin==5)
    param = varargin{1};
    scanList = varargin{2};
    colorList = varargin{3};
    saveDirectory = varargin{4};
    saveType = varargin{5};
    numColor = length(colorList);
    
end
    
for i=1:length(scanList)
   nS = scanList(i);
   
    disp(['Calculating mip for scan ', num2str(nS)]);

    for nC=1:numColor
        imVar.color =colorList{nC};
        imVar.zNum = '';%Won't need this for mip
        imVar.scanNum = nS;

        recalcProj = false;
        mip{nC} = selectProjection(param, 'mip',0, imVar.scanNum, imVar.color, imVar.zNum, recalcProj);

        fprintf(2, '\n');
    end
    
    switch saveType
        case 'mat'
        %Save the projection as a .mat file
        saveName = [param.dataSaveDirectory, filesep, 'FluoroScan_', num2str(nS),'.mat'];
        save(saveName, 'mip');
        
        case 'tiff'
          for nC=1:numColor
              color =colorList{nC};
              saveName = [param.dataSaveDirectory, filesep,...
                  'FluoroScan_', num2str(nS),'_', color, '.tiff'];
              imwrite(uint16(mip{nC}), saveName);
          end
          
    end

end


end