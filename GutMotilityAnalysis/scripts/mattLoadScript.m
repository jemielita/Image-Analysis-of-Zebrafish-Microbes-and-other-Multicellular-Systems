% Script to pull Matt's data into a format we can use

aGDName = rdir('*.mat');
N=size(aGDName,1);
fps=5;
freqMean=0.035;
gutFFTData=zeros(N,6);

for i=1:N
    
    inputVar = load(aGDName(i).name);
    fishNameN=aGDName(i).name;
    fishNameN(end-14:end)=[];
    fishNameN(1:4)=[];
    curFishNum=str2double(fishNameN);
%     gutMesh=inputVar.piv.gutMesh;
%     gutMeshVels=inputVar.piv.gutMeshVels;
    gutMeshVelsPCoords=inputVar.piv.gutMeshVelsPCoords;
    [fPeak, fSTD, fMin, fMax, fFreq] = gutFFTPeakFinder( gutMeshVelsPCoords, fps, freqMean );
    gutFFTData(curFishNum,:)=[fPeak, fSTD, fMin, fMax, fFreq, freqMean];
    
end

gFBool=[0,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0];
vibBool=[0,0,0,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,0,1,1];
aeroBool=[0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,1,1,1,1,0,0];
fishPosInTime=1:length(gFBool);

FFTData_2_4_15_Matt=[gutFFTData,gFBool',vibBool',aeroBool'];

t=1:31;
gfb=logical(FFTData_2_4_15_Matt(:,7));
vb=logical(FFTData_2_4_15_Matt(:,8));
ab=logical(FFTData_2_4_15_Matt(:,9));
plot(t(gfb),FFTData_2_4_15_Matt(gfb,1),'k.', 'markersize', 20);hold on;
plot(t(vb),FFTData_2_4_15_Matt(vb,1),'g.', 'markersize', 20);
plot(t(ab),FFTData_2_4_15_Matt(ab,1),'r.', 'markersize', 20);hold off;