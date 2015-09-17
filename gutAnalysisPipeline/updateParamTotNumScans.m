function param = updateParamTotNumScans(param,nsNew)

% Quick function to update relevant param fields when changing total number of
% scans, i.e. after drift.
%
% Brandon Schlomann
% September 2, 2015

param.expData.totalNumberScans = nsNew;

try
    
    param.scans(nsNew+1:end) = [];
catch
    disp(strcat('param.scans already has fewer than ',num2str(nsNew),' elements'))
end

try
    % better way to do this?
    for i=nsNew+1:numel(param.centerLineAll)
        param.centerLineAll{i} = [];
    end
    
    param.centerLineAll = param.centerLineAll(~cellfun(@isempty,param.centerLineAll));
catch
    disp(strcat('param.centerLine already has fewer than ',num2str(nsNew),' elements'))
end

try
    param.endGutPos(nsNew+1:end,:) = [];
catch
    disp(strcat('param.endGutPos already has fewer than ',num2str(nsNew),' elements'))
end

try
    param.autoFluorPos(nsNew+1:end,:) = [];
catch
    disp(strcat('param.autoFluorPos already has fewer than ',num2str(nsNew),' elements'))
end

try
    param.endBulbPos(nsNew+1:end,:) = [];
catch
    disp(strcat('param.endBulbPos already has fewer than ',num2str(nsNew),' elements'))
end

try
    param.autoFluorEndPos(nsNew+1:end,:) = [];
catch
    disp(strcat('param.autoFluorEndPos already has fewer than ',num2str(nsNew),' elements'))
end    

try
    param.beginGutPos(nsNew+1:end,:) = [];
catch
    disp(strcat('param.beginGutPos already has fewer than ',num2str(nsNew),' elements'))
end

try
    param.gutRegionsInd(nsNew+1:end,:) = [];
catch
    disp(strcat('param.gutRegionsInd already has fewer than ',num2str(nsNew),' elements'))
    
end


    
    
    


end