//
//  STHorizontalPickerScale.h
//  PainTracker
//
//  Created by Bob Kutschke on 1/9/20.
//  Copyright © 2020 Chronic Stimulation, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat kSTHorizontalPickerScaleWidth;
extern const CGFloat kSTHorizontalPickerScaleHeight;

@interface STHorizontalPickerScale : CALayer

@property (nonatomic) CGColorRef scaleColor;
@property (nonatomic) CFStringRef primaryLabel;
@property (nonatomic) CGColorRef labelColor;
@property (nonatomic) CGSize labelSizePerStep;
@property (nonatomic) CGSize spacerSizePerStep;
@property (nonatomic) CGFloat fontSize;

-(CGFloat)fontSizeForPrimaryLabelString:(NSString *)labelString;
-(CGSize)defaultLabelSizeForScale;
-(CGPoint)pointInBoundedRectWithSize:(CGSize)rectSize normalizedPoint:(CGPoint)normalizedPoint;

@end

NS_ASSUME_NONNULL_END
