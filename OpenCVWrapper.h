//
//  OpenCVWrapper.h
//  VisionDetection
//
//  Created by zhuziyang on 2024/10/21.
//  Copyright © 2024 Willjay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Vision/Vision.h>
#import <opencv2/opencv.hpp>


NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (NSString *)getOpenCVVersion;
+ (UIImage *)grayscaleImg:(UIImage *)image;
+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation;

@end

@interface ImageProcessor : NSObject

+ (NSDictionary *)preprocess:(UIImage *)image
             withFaceObservation:(VNFaceObservation *)faceObservation
                       withSize:(CGSize)newSize
                   interpolation:(int)interpolation;

@end

cv::Mat hwc_to_chw(cv::Mat img);

NS_ASSUME_NONNULL_END