%Analysis Template
%Sample analysis code.

%Analysis pipeline

%Also need the param file

%1. Calculate linear intensity down length of gut
analysisType(1).name = 'linearIntensity';
analysisType(1).return = true;

%2. Calculate radial projection at all points along the gut
analysisType(2).name = 'radialProjection';
analysisType(2).return = true;

% %3. Calculate radial distribution 
analysisType(3).name = 'radialDistribution';
analysisType(3).return = true;
analysisType(3).param.father = 2;
analysisType(3).param.binSize = 2;


%Scan parameters

%Location of the code we're using to analyze the gut-to create a paper
%trail of what the state of the code was when we did the analysis
scanParam.codeDir = 'C:\code\trunk';
%Colors to analyze
scanParam.color = {'488nm', '568nm'};
scanParam.dataSaveDirectory =  'F:\Aeromonas_May23_take2\fish6\gutOutline';
%List of scans to analyze
scanParam.scanList = 1:24;

scanParam.stepSize = 5;
scanParam.regOverlap = 10;


%For linear intensity
scanParam.boxDim = 100:100:4000;
scanParam.