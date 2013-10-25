%Analysis Template
%Sample analysis code.

%Analysis pipeline

%Also need the param file

%1. Calculate a histogram of pixel values near background
analysisType(1).name = 'backgroundHistogram';
analysisType(1).return = true;
analysisType(1).binSize = 1:2:2000; 


%Calculate the linear intensity down the length of the gut after
%subtracting the background intensity at those regions
analysisType(2).name = 'linearIntensityBkgSub';
analysisType(2).return = true;
analysisType(2).bkgList = 1:25:2000; %Need to get a sense of what size 

analysisType(3).name = 'spotDetection';
analysisType(3).return = true;

%2. Calculate linear intensity down length of gut
analysisType(1).name = 'linearIntensity';
analysisType(1).return = true;
analysisType(1).binSize = 1:2:2000;

%3. Calculate radial projection at all points along the gut
analysisType(3).name = 'radialProjection';
analysisType(3).return = true;

%4. Calculate radial distribution 
analysisType(4).name = 'radialDistribution';
analysisType(4).return = true;
analysisType(4).param.father = 2;
analysisType(4).param.binSize = 2;

%Scan parameters

%Location of the code we're using to analyze the gut-to create a paper
%trail of what the state of the code was when we did the analysis
scanParam.codeDir = 'C:\code\trunk';
%Colors to analyze
scanParam.color = {'568nm'};
scanParam.dataSaveDirectory =  'F:\Aeromonas_May23_take2\fish6\gutOutline';
%List of scans to analyze
scanParam.scanList = 1:44;

scanParam.stepSize = 5;
scanParam.regOverlap = 10;
