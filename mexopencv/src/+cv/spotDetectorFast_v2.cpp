/*
 @file awtC.cpp
 @brief mex interface performing an a trous wavelet transform on an image
 @author Kota Yamaguchi, Ryan Baker
 @date 2014
*/

/*
 *
 */

// Headers 

#include "mexopencv.hpp"
#include <math.h>       /* pow */
using namespace std;
using namespace cv;


// Global Constants

const int NBANDS = 8; // Assumes argument nbands will not be greater than 8


// Main function

void significantCoefficientDenoising (const Mat &img, Mat& result, Size s, int nBands)
{
    
    // Initialize variables
    int i;
    int ddepth = -1,k,num;
    int delta = 0;
    double powerExp = 2;
    int borderType = BORDER_REPLICATE;
    int threshType = THRESH_BINARY;
    double thresh, maxVal=1;
    Point anchor(-1,-1);
    Scalar mean, stddev;
    Mat kernel;
    
    
    Mat lastA = img.clone();
    Mat midA = img.clone();
    Mat newA = img.clone(); 
        
    Mat mask = Mat::zeros(s.height, s.width, CV_32F );
    Mat maskTemp = Mat::zeros(s.height, s.width, CV_32F );
    
   // Mat result =  Mat::zeros(s.height, s.width, CV_32F );
    Mat temp;
    
    // Apply filter 2D
    for(k=1;k<=nBands;k++)
    {
        // Reinitialize with zeros
        num=int(pow(powerExp,k+1)+1);
        kernel = Mat::zeros(num, 1, CV_64F );
        
        // Update Kernel
        kernel.at<double>(int(pow(powerExp,k))) = 0.375;
        kernel.at<double>(0) = 0.0625;
        kernel.at<double>(int(pow(powerExp,k+1))) = 0.0625;
        kernel.at<double>(int(pow(powerExp,k-1))) = 0.25;
        kernel.at<double>(int(pow(powerExp,k+1)-pow(powerExp,k-1))) = 0.25;
        
        // Filter the image
        filter2D(
                lastA,                    // src type
                midA,                     // dst type
                ddepth,                   // dst depth
                kernel.t(),                   // 2D kernel
                anchor,                   // anchor point, center if (-1,-1)
                delta,                    // bias added after filtering
                borderType                // border type
                );
        
        // Transpose, do other direction
        filter2D(
                midA,                    // src type
                newA,                    // dst type
                ddepth,                  // dst depth
                kernel,              // 2D kernel, transposed
                anchor,                  // anchor point, center if (-1,-1)
                delta,                   // bias added after filtering
                borderType               // border type
                );
        
        // Update lastA  
        midA=lastA-newA;
        midA.convertTo(temp,CV_32F);
        lastA = newA.clone();
        
        // Get the mask values
        meanStdDev(
                temp,
                mean,
                stddev
                );
        thresh=3*(double)stddev.val[0]; // Mean should be roughly around zero. You can choose to include if you'd like
        // Get the mask
        threshold(
                abs(temp),
                maskTemp,
                thresh,
                maxVal,
                threshType
                );
        mask=mask|maskTemp;
        result=result+temp.mul(mask);
    }

 
};

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    // Check the number of arguments
    if (nrhs!=2)
        mexErrMsgIdAndTxt("mexopencv:error","Wrong number of arguments");
    if (nlhs!=1)
        mexErrMsgIdAndTxt("mexopencv:error","Wrong number of output arguments");
    /* We only handle doubles */
    if (!mxIsDouble(prhs[0]))
        mexErrMsgTxt("Input image should be double.\n");
    
    // Convert inputs
    Mat imgInput = MxArray(prhs[0]).toMat(); // Thresholding only works with singles

    Mat img;
    
    imgInput.convertTo(img, CV_32F);
    int nBands = int(mxGetScalar(prhs[1])); 
    Size s = img.size();

    Mat result = Mat::zeros(s.height, s.width, CV_32F );
    Mat finalResult = Mat::zeros(s.height, s.width, CV_32F );
    Mat filtResult = Mat::zeros(s.height, s.width, CV_32F );
  //  int i = gpu::getCudaEnabledDeviceCount();

    Mat resDenoised = Mat::zeros(s.height, s.width, CV_32F );
    
    significantCoefficientDenoising (img, result,s, nBands);
   
    significantCoefficientDenoising (img-result, resDenoised,s, nBands);
    
    finalResult = result + resDenoised;
    
    
   // Applying a median filter to the image
    medianBlur(finalResult, filtResult, 5);
    
    plhs[0] = MxArray(finalResult);
    return;
}

