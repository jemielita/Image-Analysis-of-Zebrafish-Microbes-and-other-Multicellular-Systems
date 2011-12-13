%Analyze the distribution down the length of the gut for a time series.

function intenL = timeIntensityCurve(dirName)

%Get the total number of analyzed scans in this directory
scanNum = dir(dirName);
scanNum = [scanNum.name];
scanNum = regexp(scanNum, 'FluoroScan_\d');
scanNum = length(scanNum);

totNumScan = scanNum;

mess = strcat('Analyzing intensity for scans in ',dirName);
disp(mess);

for scanNum =1:totNumScan

    mess = ['Scan...', num2str(scanNum)];
    disp(mess);
    %Load in this projection
    fileName = [dirName, filesep, 'FluoroScan_', num2str(scanNum), '.mat'];
    im = load(fileName);
    im = im.dataOut;
    
    %Load in the region mask
    filename = [dirName, filesep, 'regMask.mat'];
    regMask = load(filename);
    regMask = regMask.regMask;
    
    %Analyze each color separately 
    totNumColor = size(im,2);
    
    disp('Analyzing color... ');
    for numColor =1:totNumColor
        disp(strcat(num2str(numColor), '...'));

        intenL(scanNum, numColor,:) = intensityCurve(regMask, im(numColor).totalInten);
    
    end
    
    
end


end
