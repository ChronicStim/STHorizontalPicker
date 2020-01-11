//
//  STHorizontalPickerScale.m
//  PainTracker
//
//  Created by Bob Kutschke on 1/9/20.
//  Copyright © 2020 Chronic Stimulation, LLC. All rights reserved.
//

#import "STHorizontalPickerScale.h"
#include <CoreText/CoreText.h>

const CGFloat kSTHorizontalPickerScaleWidth = 40.0f;
const CGFloat kSTHorizontalPickerScaleHeight = 40.0f;

@implementation STHorizontalPickerScale

@dynamic scaleColor;
@dynamic primaryLabel;
@dynamic labelColor;
@dynamic labelSizePerStep;
@dynamic spacerSizePerStep;
@synthesize fontSize = _fontSize;

- (id)init
{
    self = [super init];
    if (self) {
        self.needsDisplayOnBoundsChange = YES;
    }
    return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"scaleColor"] ||
        [key isEqualToString:@"primaryLabel"] ||
        [key isEqualToString:@"labelColor"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

+ (id)defaultValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"scaleColor"]) {
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGFloat components[4];
        components[0] = 0.0f;
        components[1] = 0.0f;
        components[2] = 0.0f;
        components[3] = 1.0f;
        CGColorRef color = CGColorCreate(space, components);
        CGColorSpaceRelease(space);
        return (__bridge_transfer id)color;
    }
    if ([key isEqualToString:@"primaryLabel"]) {
        return (id)CFSTR("200");
    }
    if ([key isEqualToString:@"labelColor"]) {
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGFloat components[4];
        components[0] = 0.086f;
        components[1] = 0.157f;
        components[2] = 0.333f;
        components[3] = 1.0f;
        CGColorRef color = CGColorCreate(space, components);
        CGColorSpaceRelease(space);
        return (__bridge_transfer id)color;
    }
    return [super defaultValueForKey:key];
}

-(CGSize)defaultLabelSizeForScale;
{
    CGSize defaultLabelSize = CGSizeMake(kSTHorizontalPickerScaleWidth, kSTHorizontalPickerScaleHeight);
    if (!CGSizeEqualToSize(self.labelSizePerStep, CGSizeZero)) {
        defaultLabelSize = self.labelSizePerStep;
    }
    return defaultLabelSize;
}

-(CGPoint)pointInBoundedRectWithSize:(CGSize)rectSize normalizedPoint:(CGPoint)normalizedPoint;
{
    CGPoint newPoint = CGPointZero;
    if (!CGSizeEqualToSize(CGSizeZero, rectSize)) {
        
        CGFloat normX = PIN(0.0f, 1.0f, normalizedPoint.x);
        CGFloat normY = PIN(0.0f, 1.0f, normalizedPoint.y);
        
        newPoint = CGPointMake(normX * rectSize.width-1, normY * rectSize.height);
    }
    
    return newPoint;
}

- (void)drawInContext:(CGContextRef)context
{
    CGSize defaultLabelSize = [self defaultLabelSizeForScale];
    CGRect imageBounds = CGRectMake(0.0f, 0.0f, defaultLabelSize.width, defaultLabelSize.height);
    CGRect bounds = [self bounds];
    CGFloat alignStroke;
    CGFloat resolution;
    CGFloat stroke;
    CGMutablePathRef path;
    CGPoint point;
    CGColorRef color;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGRect drawRect;
    CFMutableDictionaryRef attributes;
    CFAttributedStringRef attributedString;
    CTParagraphStyleRef paragraphStyle;
    CTTextAlignment alignment;
    CTLineBreakMode lineBreakMode;
    CTFontRef font;
    CTFramesetterRef framesetter;
    CTFrameRef frame;
    CGAffineTransform transform;
    CTParagraphStyleSetting paragraphSettings[2];
    
    transform = CGContextGetUserSpaceToDeviceSpaceTransform(context);
    resolution = sqrtf(fabs(transform.a * transform.d - transform.b * transform.c)) * 0.5f * (bounds.size.width / imageBounds.size.width + bounds.size.height / imageBounds.size.height);
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, bounds.origin.x, bounds.origin.y);
    CGContextScaleCTM(context, (bounds.size.width / imageBounds.size.width), (bounds.size.height / imageBounds.size.height));
    
    // Layer 1
    
    // Large hash at 0.5
    stroke = 2.0f;
    stroke *= resolution;
    if (stroke < 1.0f) {
        stroke = ceilf(stroke);
    } else {
        stroke = roundf(stroke);
    }
    stroke /= resolution;
    alignStroke = fmodf(0.5f * stroke * resolution, 1.0f);
    path = CGPathCreateMutable();
    point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake(0.5, 0.6)];
    point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
    point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
    CGPathMoveToPoint(path, NULL, point.x, point.y);
    point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake(0.5, 1.0)];
    point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
    point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    color = [self scaleColor];
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetLineWidth(context, stroke);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGPathRelease(path);
    
    // Small hash marks from 0.6 to 0.9
    for (int i = 6; i < 10 ; i++) {
        stroke = 2.0f;
        stroke *= resolution;
        if (stroke < 1.0f) {
            stroke = ceilf(stroke);
        } else {
            stroke = roundf(stroke);
        }
        stroke /= resolution;
        alignStroke = fmodf(0.5f * stroke * resolution, 1.0f);
        path = CGPathCreateMutable();
        point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake((float)i/10.0f , 0.9)];
        point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
        point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
        CGPathMoveToPoint(path, NULL, point.x, point.y);
        point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake((float)i/10.0f , 1.0)];
        point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
        point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
        CGPathAddLineToPoint(path, NULL, point.x, point.y);
        color = [self scaleColor];
        CGContextSetStrokeColorWithColor(context, color);
        CGContextAddPath(context, path);
        CGContextStrokePath(context);
        CGPathRelease(path);
    }
    
    // End mark at 1.0
    stroke = 2.0f;
    stroke *= resolution;
    if (stroke < 1.0f) {
        stroke = ceilf(stroke);
    } else {
        stroke = roundf(stroke);
    }
    stroke /= resolution;
    alignStroke = fmodf(0.5f * stroke * resolution, 1.0f);
    path = CGPathCreateMutable();
    point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake(1.0 , 0.8)];
    point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
    point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
    CGPathMoveToPoint(path, NULL, point.x, point.y);
    point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake(1.0 , 1.0)];
    point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
    point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    color = [self scaleColor];
    CGContextSetStrokeColorWithColor(context, color);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGPathRelease(path);
    
    // Lower Horizontal Axis
    stroke = 2.0f;
    stroke *= resolution;
    if (stroke < 1.0f) {
        stroke = ceilf(stroke);
    } else {
        stroke = roundf(stroke);
    }
    stroke /= resolution;
    alignStroke = fmodf(0.5f * stroke * resolution, 1.0f);
    path = CGPathCreateMutable();
    point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake(0.0 , 1.0)];
    point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
    point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
    CGPathMoveToPoint(path, NULL, point.x, point.y);
    point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake(1.0 , 1.0)];
    point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
    point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    color = [self scaleColor];
    CGContextSetStrokeColorWithColor(context, color);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGPathRelease(path);
    
    // Small hashes from 0.1 to 0.4
    for (int i = 1; i < 5 ; i++) {
        stroke = 2.0f;
        stroke *= resolution;
        if (stroke < 1.0f) {
            stroke = ceilf(stroke);
        } else {
            stroke = roundf(stroke);
        }
        stroke /= resolution;
        alignStroke = fmodf(0.5f * stroke * resolution, 1.0f);
        path = CGPathCreateMutable();
        point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake((float)i/10.0f , 0.9)];
        point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
        point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
        CGPathMoveToPoint(path, NULL, point.x, point.y);
        point = [self pointInBoundedRectWithSize:defaultLabelSize normalizedPoint:CGPointMake((float)i/10.0f , 1.0)];
        point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
        point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
        CGPathAddLineToPoint(path, NULL, point.x, point.y);
        color = [self scaleColor];
        CGContextSetStrokeColorWithColor(context, color);
        CGContextAddPath(context, path);
        CGContextStrokePath(context);
        CGPathRelease(path);
    }

    // Draw Text Label
    drawRect = CGRectMake(0, 0, defaultLabelSize.width, 0.8*defaultLabelSize.height);
    drawRect.origin.x = roundf(resolution * drawRect.origin.x) / resolution;
    drawRect.origin.y = roundf(resolution * drawRect.origin.y) / resolution;
    drawRect.size.width = roundf(resolution * drawRect.size.width) / resolution;
    drawRect.size.height = roundf(resolution * drawRect.size.height) / resolution;
    attributes = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    alignment = kCTTextAlignmentCenter;
    paragraphSettings[0].spec = kCTParagraphStyleSpecifierAlignment;
    paragraphSettings[0].valueSize = sizeof(alignment);
    paragraphSettings[0].value = &alignment;
    lineBreakMode = kCTLineBreakByClipping;
    paragraphSettings[1].spec = kCTParagraphStyleSpecifierLineBreakMode;
    paragraphSettings[1].valueSize = sizeof(lineBreakMode);
    paragraphSettings[1].value = &lineBreakMode;
    paragraphStyle = CTParagraphStyleCreate(paragraphSettings, 2);
    CFDictionarySetValue(attributes, kCTParagraphStyleAttributeName, paragraphStyle);
    CFRelease(paragraphStyle);
    font = CTFontCreateWithName(CFSTR("Arial-BoldMT"), self.fontSize, NULL);
    CFDictionarySetValue(attributes, kCTFontAttributeName, font);
    CFRelease(font);
    CFDictionarySetValue(attributes, kCTForegroundColorAttributeName, [self labelColor]);
    attributedString = CFAttributedStringCreate(NULL, [self primaryLabel], attributes);
    CFRelease(attributes);
    path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawRect);
    CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0f, -1.0f));
    framesetter = CTFramesetterCreateWithAttributedString(attributedString);
    frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(frame, context);
    CFRelease(framesetter);
    CFRelease(frame);
    CGPathRelease(path);
    CFRelease(attributedString);
    
    CGContextRestoreGState(context);
    CGColorSpaceRelease(space);
}

-(CGFloat)fontSize;
{
    if (0.0f == _fontSize) {
        _fontSize = 14.0f;
    }
    return _fontSize;
}

-(void)setFontSize:(CGFloat)fontSize;
{
    if (fontSize != _fontSize) {
        _fontSize = fontSize;
    }
    [self setNeedsDisplay];
}

-(CGFloat)fontSizeForPrimaryLabelString:(NSString *)labelString;
{
    CGFloat fontForMaxChar = 7.0f; // @ 8 char
    CGFloat fontForMinChar = 14.0f; // @ 3 char
    
    CGFloat minCharCount = 3;
    CGFloat maxCharCount = 8;
    CGFloat labelCharCount = (CGFloat)[labelString length];
    CGFloat normCharCount = (labelCharCount - minCharCount)/(maxCharCount - minCharCount);
    
    CGFloat fontSize = lerpf(fontForMinChar, fontForMaxChar, normCharCount);
    
    return fontSize;
}

@end
