/*
 * Copyright 2011-2012 StackThread Software Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "STHorizontalPicker.h"
#import "STHorizontalPickerScaleDecimal.h"

const int DISTANCE_BETWEEN_ITEMS = 40;
const int TEXT_LAYER_WIDTH = 40;
const int NUMBER_OF_ITEMS = 15;
const float FONT_SIZE = 16.0f;
const float POINTER_WIDTH = 10.0f;
const float POINTER_HEIGHT = 12.0f;

//================================
// UIColor category
//================================
@implementation UIColor (STColorComponents)

- (CGColorSpaceModel)colorSpaceModel {
	return CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
}

- (CGFloat)red {
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	return c[0];
}

- (CGFloat)green {
	const CGFloat *c = CGColorGetComponents(self.CGColor);
    if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[1];
}

- (CGFloat)blue {
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[2];
}

- (CGFloat)alpha {
    return CGColorGetAlpha(self.CGColor);
}

@end





//================================
// STHorizontalPicker
//================================

@interface STHorizontalPicker ()

// Private properties

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollViewMarkerContainerView;
@property (nonatomic, strong) NSMutableArray *scrollViewMarkerLayerArray;
@property (nonatomic, strong) CAShapeLayer *pointerLayer;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CAGradientLayer *dropshadowLayer;
@property (nonatomic, strong) STPointerLayerDelegate *pointerLayerDelegate;

@end;
    
@implementation STHorizontalPicker

@synthesize scrollView, scrollViewMarkerContainerView, scrollViewMarkerLayerArray, name, pointerLayer, dropShadowColor, gradientColor, backColor, textColor, pointerFillColor, pointerStrokeColor, font, showScale;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        steps = 15;
        
        float leftPadding = self.frame.size.width/2;
        float rightPadding = leftPadding;
        float contentWidth = leftPadding + (steps * DISTANCE_BETWEEN_ITEMS) + rightPadding + TEXT_LAYER_WIDTH / 2;
    
        scale = [[UIScreen mainScreen] scale];
        font = [UIFont fontWithName:@"Arial-BoldMT" size:12.0f];
        
        if ([self respondsToSelector:@selector(setContentScaleFactor:)]) {
            self.contentScaleFactor = scale;
        }
        
        // Ensures that the corners are transparent
        self.backgroundColor = [UIColor clearColor];
        
        borderColor = [UIColor blackColor];
        backColor = [UIColor whiteColor];
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
        self.scrollView.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
        self.scrollView.layer.cornerRadius = 8.0f;
        self.scrollView.layer.borderWidth = 2.0f;
        self.scrollView.layer.borderColor = borderColor.CGColor ? borderColor.CGColor : [UIColor grayColor].CGColor;
        self.scrollView.backgroundColor = backColor;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;        
        self.scrollView.pagingEnabled = NO;
        self.scrollView.delegate = self;
        
        self.scrollViewMarkerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentWidth, self.frame.size.height)];
        
        [self setupMarkers];

        [self.scrollView addSubview:self.scrollViewMarkerContainerView];        
        [self addSubview:self.scrollView];
        [self snapToMarkerAnimated:NO];

        self.dropshadowLayer = [CAGradientLayer layer];
        self.dropshadowLayer.contentsScale = scale;
        self.dropshadowLayer.cornerRadius = 8.0f;
        self.dropshadowLayer.startPoint = CGPointMake(0.0f, 0.0f);
        self.dropshadowLayer.endPoint = CGPointMake(0.0f, 1.0f);
        self.dropshadowLayer.opacity = 1.0;
        self.dropshadowLayer.frame = CGRectMake(1.0f, 1.0f, self.frame.size.width - 2.0, self.frame.size.height - 2.0);
        self.dropshadowLayer.locations = [NSArray arrayWithObjects:
                                   [NSNumber numberWithFloat:0.0f],
                                   [NSNumber numberWithFloat:0.05f],
                                   [NSNumber numberWithFloat:0.2f],
                                   [NSNumber numberWithFloat:0.8f],
                                   [NSNumber numberWithFloat:0.95f],                                   
                                   [NSNumber numberWithFloat:1.0f], nil];
        self.dropshadowLayer.colors = [self dropShadowColorArray];
        
        [self.layer insertSublayer:self.dropshadowLayer above:self.scrollView.layer];
        
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.contentsScale = scale;
        self.gradientLayer.cornerRadius = 8.0f;
        self.gradientLayer.startPoint = CGPointMake(0.0f, 0.0f);
        self.gradientLayer.endPoint = CGPointMake(1.0f, 0.0f);
        self.gradientLayer.opacity = 1.0;
        self.gradientLayer.frame = CGRectMake(1.0f, 1.0f, self.frame.size.width - 2.0, self.frame.size.height - 2.0);
        self.gradientLayer.locations = [NSArray arrayWithObjects:
                                   [NSNumber numberWithFloat:0.0f],
                                   [NSNumber numberWithFloat:0.05f],
                                   [NSNumber numberWithFloat:0.3f],
                                   [NSNumber numberWithFloat:0.7f],
                                   [NSNumber numberWithFloat:0.95f],                                   
                                   [NSNumber numberWithFloat:1.0f], nil];
        self.gradientLayer.colors = [self gradientColorArray];
        [self.layer insertSublayer:self.gradientLayer above:self.dropshadowLayer];

        pointerStrokeColor = [UIColor blackColor];
        pointerFillColor = [UIColor yellowColor];
        self.pointerLayer = [CALayer layer];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerFillColor red]] forKey:@"pointerFillColorRed"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerFillColor green]] forKey:@"pointerFillColorGreen"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerFillColor blue]] forKey:@"pointerFillColorBlue"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerFillColor alpha]] forKey:@"pointerFillColorAlpha"];        
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerStrokeColor red]] forKey:@"pointerStrokeColorRed"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerStrokeColor green]] forKey:@"pointerStrokeColorGreen"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerStrokeColor blue]] forKey:@"pointerStrokeColorBlue"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerStrokeColor alpha]] forKey:@"pointerStrokeColorAlpha"];
        self.pointerLayer.opacity = 0.8f;
        self.pointerLayer.contentsScale = scale;
        self.pointerLayer.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
        self.pointerLayerDelegate = [[STPointerLayerDelegate alloc] init];
        self.pointerLayer.delegate = self.pointerLayerDelegate;

        [self.layer insertSublayer:self.pointerLayer above:self.gradientLayer];
        [self.pointerLayer setNeedsDisplay];
        
    }
    return self;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self snapToMarkerAnimated:YES];
    if (delegate && [delegate respondsToSelector:@selector(pickerView:didSelectValue:)]) {
        [self callDelegateWithNewValueFromOffset:[self.scrollView contentOffset].x];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self snapToMarkerAnimated:YES];
    if (delegate && [delegate respondsToSelector:@selector(pickerView:didSelectValue:)]) {
        [self callDelegateWithNewValueFromOffset:[self.scrollView contentOffset].x];
    }    
}

- (void)callDelegateWithNewValueFromOffset:(CGFloat)offset {

    CGFloat itemWidth = (float) DISTANCE_BETWEEN_ITEMS;
    
    CGFloat offSet = offset / itemWidth;
    NSUInteger target = (NSUInteger)(offSet + 0.35f);
    target = target > steps ? steps - 1 : target;
    CGFloat newValue = target * (maximumValue - minimumValue) / steps + minimumValue;
    
    [delegate pickerView:self didSelectValue:newValue];
    
}

- (void)snapToMarkerAnimated:(BOOL)animated {
    CGFloat itemWidth = (float)DISTANCE_BETWEEN_ITEMS;
    CGFloat position = [self.scrollView contentOffset].x;

    if (position < self.scrollViewMarkerContainerView.frame.size.width - self.frame.size.width / 2) {
        CGFloat newPosition = 0.0f;
        CGFloat offSet = position / itemWidth;
        NSUInteger target = (NSUInteger)(offSet + 0.35f);
        target = target > steps ? steps - 1 : target;
        newPosition = target * itemWidth + TEXT_LAYER_WIDTH / 2;
        [self.scrollView setContentOffset:CGPointMake(newPosition, 0.0f) animated:animated];
    }
}

- (void)removeAllMarkers {
    for (id marker in self.scrollViewMarkerLayerArray) {
        [(CATextLayer *)marker removeFromSuperlayer];
    }
    [self.scrollViewMarkerLayerArray removeAllObjects];
}

- (void)setupMarkers {
    [self removeAllMarkers];
    
    // Calculate the new size of the content
    float leftPadding = self.frame.size.width / 2;
    float rightPadding = leftPadding;
    float contentWidth = leftPadding + (steps * DISTANCE_BETWEEN_ITEMS) + rightPadding + TEXT_LAYER_WIDTH / 2;
    self.scrollView.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
    
    // Set the size of the marker container view
    [self.scrollViewMarkerContainerView setFrame:CGRectMake(0.0f, 0.0f, contentWidth, self.frame.size.height)];
    
    // Configure the new markers
    self.scrollViewMarkerLayerArray = [NSMutableArray arrayWithCapacity:steps];
    BOOL useDelegate = NO;
    if (nil != delegate && [(id)delegate respondsToSelector:@selector(displayStringForPickerView:atStep:withValue:)]) {
        useDelegate = YES;
    }
    for (int i = 0; i <= steps; i++) {
        
        float currentValue = (float) minimumValue + i * (maximumValue - minimumValue) / steps;
        CGRect layerFrame = CGRectIntegral(CGRectMake(leftPadding + i*DISTANCE_BETWEEN_ITEMS, self.frame.size.height / 2 - fontSize / 2 + 0, TEXT_LAYER_WIDTH, 40));
        
        CATextLayer *textLayer;
        
        if (nil != delegate && [delegate respondsToSelector:@selector(caTextLayerForPickerView:atStep:withValue:frame:)]) {
            textLayer = [self.delegate caTextLayerForPickerView:self atStep:i withValue:currentValue frame:layerFrame];
        } else {
            /*
            textLayer = [CATextLayer layer];
            textLayer.contentsScale = scale;
            textLayer.frame = layerFrame;
            textLayer.foregroundColor = self.textColor.CGColor;
            textLayer.alignmentMode = kCAAlignmentCenter;
            textLayer.fontSize = fontSize;
            textLayer.font = CGFontCreateWithFontName((__bridge CFStringRef)font.fontName);;
            
            if (useDelegate) {
                textLayer.string = [self.delegate displayStringForPickerView:self atStep:i withValue:currentValue];
            } else {
                textLayer.string = [NSString stringWithFormat:@"%.0f", currentValue];
            }
             */
            
            CGRect layerFrame = CGRectIntegral(CGRectMake(leftPadding + i*DISTANCE_BETWEEN_ITEMS, 0, TEXT_LAYER_WIDTH, 35));
            STHorizontalPickerScaleDecimal *scaleLayer = [[STHorizontalPickerScaleDecimal alloc] init];
            scaleLayer.frame = layerFrame;
            scaleLayer.contentsScale = scale;
            scaleLayer.labelColor = [UIColor cptPrimaryColor].CGColor;
            scaleLayer.scaleColor = [UIColor blackColor].CGColor;
            scaleLayer.primaryLabel = (__bridge CFStringRef)[NSString stringWithFormat:@"%.0f", currentValue];
            
            [self.scrollViewMarkerLayerArray addObject:scaleLayer];
            [self.scrollViewMarkerContainerView.layer addSublayer:scaleLayer];

        }

//        if (self.showScale) {
//            CGRect scaleFrame = CGRectIntegral(CGRectMake(leftPadding + i*DISTANCE_BETWEEN_ITEMS, 0, TEXT_LAYER_WIDTH, 18));
//            CALayer *scaleLayer = [[STHorizontalPickerScaleDecimal alloc] init];
//            scaleLayer.frame = scaleFrame;
//            [self.scrollViewMarkerContainerView.layer addSublayer:scaleLayer];
//        }

//        [self.scrollViewMarkerLayerArray addObject:textLayer];
//        [self.scrollViewMarkerContainerView.layer addSublayer:textLayer];
    }
}

- (NSArray *)dropShadowColorArray;
{
    UIColor *mainColor;
    if (nil != self.dropShadowColor) {
        mainColor = self.dropShadowColor;
    } else {
        mainColor = [UIColor blackColor];
    }
    CGFloat hue, saturation, brightness, alpha;
    if (![mainColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        NSLog(@"Unable to convert color to HSB model");
        return [NSArray arrayWithObjects:
                (id)[[UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:0.75] CGColor],
                (id)[[UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:0.55] CGColor],
                (id)[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.05] CGColor],
                (id)[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.05] CGColor],
                (id)[[UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:0.55] CGColor],
                (id)[[UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:0.75] CGColor], nil];
    }
    
    return [NSArray arrayWithObjects:
     (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.05f alpha:alpha*0.75f] CGColor],
     (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.25f alpha:alpha*0.55f] CGColor],
     (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*1.0f alpha:alpha*0.05f] CGColor],
     (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*1.0f alpha:alpha*0.05f] CGColor],
     (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.25f alpha:alpha*0.55f] CGColor],
     (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.05f alpha:alpha*0.75f] CGColor], nil];
}

- (NSArray *)gradientColorArray;
{
    UIColor *mainColor;
    if (nil != self.gradientColor) {
        mainColor = self.gradientColor;
    } else {
        mainColor = [UIColor blackColor];
    }
    CGFloat hue, saturation, brightness, alpha;
    if (![mainColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        NSLog(@"Unable to convert color to HSB model");
        return [NSArray arrayWithObjects:
                (id)[[UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:0.95] CGColor],
                (id)[[UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:0.8] CGColor],
                (id)[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.1] CGColor],
                (id)[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.1] CGColor],
                (id)[[UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:0.8] CGColor],
                (id)[[UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:0.95] CGColor], nil];
    }
    
    return [NSArray arrayWithObjects:
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.05f alpha:alpha*0.95f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.25f alpha:alpha*0.8f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*1.0f alpha:alpha*0.1f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*1.0f alpha:alpha*0.1f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.25f alpha:alpha*0.8f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.05f alpha:alpha*0.95f] CGColor], nil];
}

- (CGFloat)scale;
{
    return [[UIScreen mainScreen] scale];
}

- (CGFloat)minimumValue {
    return minimumValue;
}

- (void)setMinimumValue:(CGFloat)newMin {
    minimumValue = newMin;
    [self setupMarkers];
}

- (CGFloat)maximumValue {
    return maximumValue;
}

- (void)setMaximumValue:(CGFloat)newMax {
    maximumValue = newMax;
    [self setupMarkers];
}

- (NSUInteger)steps {
    return steps;
}

- (void)setSteps:(NSUInteger)newSteps {
    steps = newSteps;
    [self setupMarkers];
}

- (CGFloat)value {
    return value;
}

- (UIColor *)borderColor {
    return borderColor;
}

- (void)setBorderColor:(UIColor *)newColor {
    if (newColor != borderColor)
    {
        borderColor = newColor;

        self.scrollView.layer.borderColor = borderColor.CGColor;
    }
}

- (UIColor *)dropShadowColor;
{
    return dropShadowColor;
}

- (void)setDropShadowColor:(UIColor *)newColor;
{
    if (newColor != dropShadowColor) {
        dropShadowColor = newColor;
        self.dropshadowLayer.colors = [self dropShadowColorArray];
        [self.dropshadowLayer setNeedsDisplay];
    }
}

- (UIColor *)gradientColor;
{
    return gradientColor;
}

- (void)setGradientColor:(UIColor *)newColor;
{
    if (newColor != gradientColor) {
        gradientColor = newColor;
        self.gradientLayer.colors = [self gradientColorArray];
        [self.gradientLayer setNeedsDisplay];
    }
}

- (UIColor *)backColor;
{
    return backColor;
}

- (void)setBackColor:(UIColor *)newColor;
{
    if (newColor != backColor) {
        backColor = newColor;
        self.scrollView.backgroundColor = backColor;
        [self.scrollView setNeedsDisplay];
    }
}

- (UIColor *)textColor;
{
    return textColor;
}

- (void)setTextColor:(UIColor *)newColor;
{
    if (newColor != textColor) {
        textColor = newColor;
        [self setupMarkers];
    }
}

- (UIColor *)pointerFillColor;
{
    return pointerFillColor;
}

- (void)setPointerFillColor:(UIColor *)newColor;
{
    if (newColor != pointerFillColor) {
        pointerFillColor = newColor;

        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerFillColor red]] forKey:@"pointerFillColorRed"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerFillColor green]] forKey:@"pointerFillColorGreen"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerFillColor blue]] forKey:@"pointerFillColorBlue"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerFillColor alpha]] forKey:@"pointerFillColorAlpha"];
        [self.pointerLayer setNeedsDisplay];
        
    }
}

- (UIColor *)pointerStrokeColor;
{
    return pointerStrokeColor;
}

- (void)setPointerStrokeColor:(UIColor *)newColor;
{
    if (newColor != pointerStrokeColor) {
        pointerStrokeColor = newColor;
        
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerStrokeColor red]] forKey:@"pointerStrokeColorRed"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerStrokeColor green]] forKey:@"pointerStrokeColorGreen"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerStrokeColor blue]] forKey:@"pointerStrokeColorBlue"];
        [self.pointerLayer setValue:[NSNumber numberWithFloat:[pointerStrokeColor alpha]] forKey:@"pointerStrokeColorAlpha"];
        [self.pointerLayer setNeedsDisplay];
        
    }
}

- (CGFloat)fontSize {
    return fontSize;
}

- (void)setFontSize:(CGFloat)newFontSize {
    fontSize = newFontSize;
    [self setupMarkers];
}

- (void)setValue:(CGFloat)newValue {
    value = newValue > maximumValue ? maximumValue : newValue;
    value = newValue < minimumValue ? minimumValue : newValue;
    
    CGFloat itemWidth = (float) DISTANCE_BETWEEN_ITEMS;
    CGFloat xValue = (newValue - minimumValue) / ((maximumValue-minimumValue) / steps) * itemWidth + TEXT_LAYER_WIDTH / 2;
        
    [self.scrollView setContentOffset:CGPointMake(xValue, 0.0f) animated:NO];
}

- (void)moveToMidPointValue;
{
    CGFloat midPoint = ((maximumValue + minimumValue) / 2.0f);
    [self setValue:midPoint];
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id<STHorizontalPickerDelegate>)newDelegate {
    delegate = newDelegate;
    
    BOOL needsReset = FALSE;
    
    if ([delegate respondsToSelector:@selector(minimumValueForPickerView:)]) {
        minimumValue = [delegate minimumValueForPickerView:self];
        needsReset = TRUE;
    }
    if ([delegate respondsToSelector:@selector(maximumValueForPickerView:)]) {
        maximumValue = [delegate maximumValueForPickerView:self];
        needsReset = TRUE;
    }
    if ([delegate respondsToSelector:@selector(stepCountForPickerView:)]) {
        steps = [delegate stepCountForPickerView:self];
        needsReset = TRUE;
    }
    
    if (needsReset) {
        [self setupMarkers];
    }
}

- (BOOL)showScale;
{
    return showScale;
}

- (void)setShowScale:(BOOL)newShowScale;
{
    if (newShowScale != showScale) {
        showScale = newShowScale;
        [self setupMarkers];
    }
}

- (void)dealloc
{
    scrollView = nil;
    scrollViewMarkerContainerView = nil;
    scrollViewMarkerLayerArray = nil;
    pointerLayer = nil;

}

@end


//================================
// STPointerLayerDelegate
//================================

@implementation STPointerLayerDelegate

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    CGContextSaveGState(context);

    CGContextSetLineWidth(context, 1.0f);
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
	CGContextSetRGBStrokeColor(context, [[layer valueForKey:@"pointerStrokeColorRed"] floatValue], [[layer valueForKey:@"pointerStrokeColorGreen"] floatValue], [[layer valueForKey:@"pointerStrokeColorBlue"] floatValue], [[layer valueForKey:@"pointerStrokeColorAlpha"] floatValue]);
    CGContextSetRGBFillColor(context, [[layer valueForKey:@"pointerFillColorRed"] floatValue], [[layer valueForKey:@"pointerFillColorGreen"] floatValue], [[layer valueForKey:@"pointerFillColorBlue"] floatValue], [[layer valueForKey:@"pointerFillColorAlpha"] floatValue]);
    
    CGContextSetShadowWithColor(context, CGSizeMake(0, 2), 3.0, [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3].CGColor);
    
    CGMutablePathRef path;
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, layer.frame.size.width / 2 - POINTER_WIDTH / 2, 0);
    CGPathAddLineToPoint(path, NULL, layer.frame.size.width / 2, POINTER_HEIGHT);
    CGPathAddLineToPoint(path, NULL, layer.frame.size.width / 2 + POINTER_WIDTH / 2, 0);
    CGPathCloseSubpath(path);

    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    
    CGContextSetShadowWithColor(context, CGSizeMake(0, -2), 3.0, [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3].CGColor);

    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, layer.frame.size.width / 2 - POINTER_WIDTH / 2, layer.frame.size.height);
    CGPathAddLineToPoint(path, NULL, layer.frame.size.width / 2, layer.frame.size.height - POINTER_HEIGHT);
    CGPathAddLineToPoint(path, NULL, layer.frame.size.width / 2 + POINTER_WIDTH / 2, layer.frame.size.height);
    CGPathCloseSubpath(path);
    
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);

    CGContextRestoreGState(context);
}

@end