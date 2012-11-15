%bacteriaIntensity: calculates the total intensity from a number of
%bacteria in an image
%
%USAGE: bacInten = bacteriaIntensity(im, numBacteria, meanBkg, stdBkg,
%cutoffBkg);
%
%INPUT im: 3D image containing only bacteria that are easily
%distinguishable
%      numBacteria: number of bacteria in the image
%      meanBkg: mean intensity of background noise
%      stdBkg: standard deviation of the background noise
%      cutoffBkg: threshold of number of standard deviations above
%      background to cutoff pixel intensities.
%
%OUTPUT: bacInten: total intensity due to a single bacteria
%
%AUTHOR: Matthew Jemielita, Nov 2, 2012

function bacInten = bacteriaIntensity(im, numBacteria, meanBkg, stdBkg, cutoffBkg)

totalInten = sum(im(im>meanBkg+(cutoffBkg*stdBkg)),3);

bacInten = totalInten/numBacteria;

b= 0
end