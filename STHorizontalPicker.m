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
#import "STHorizontalPickerScale.h"
#import "STHorizontalPickerScaleDecimal.h"
#import "STHorizontalPickerScaleSimple.h"

const int DISTANCE_BETWEEN_ITEMS = 40;
const int TEXT_LAYER_WIDTH = 40;
const int NUMBER_OF_ITEMS = 15;
const float FONT_SIZE = 16.0f;
const float POINTER_WIDTH = 16.0f;
const float POINTER_HEIGHT = 18.0f;

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
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        [self loadAllViewComponents];
    }
    return self;
}

- (void)loadAllViewComponents;
{
    steps = 15;
    
    float leftPadding = self.frame.size.width/2;
    float distanceBetweenItems = [self spacerSizePerStep].width;
    float labelItemWidth = [self labelSizePerStep].width;
    float rightPadding = leftPadding;
    float contentWidth = leftPadding + (steps * distanceBetweenItems) + rightPadding + labelItemWidth / 2;
    
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
    self.pointerLayer = [CAShapeLayer layer];
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

-(void)layoutSubviews;
{
    float leftPadding = self.frame.size.width/2;
    float distanceBetweenItems = [self spacerSizePerStep].width;
    float labelItemWidth = [self labelSizePerStep].width;
    float rightPadding = leftPadding;
    float contentWidth = leftPadding + (steps * distanceBetweenItems) + rightPadding + labelItemWidth / 2;

    self.scrollView.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
    self.scrollView.contentSize = CGSizeMake(contentWidth, self.frame.size.height);

    self.scrollViewMarkerContainerView.frame = CGRectMake(0.0f, 0.0f, contentWidth, self.frame.size.height);
    
    [self setupMarkers];
    
    [self snapToMarkerAnimated:NO];

    self.dropshadowLayer.frame = CGRectMake(1.0f, 1.0f, self.frame.size.width - 2.0, self.frame.size.height - 2.0);

    self.gradientLayer.frame = CGRectMake(1.0f, 1.0f, self.frame.size.width - 2.0, self.frame.size.height - 2.0);

    self.pointerLayer.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self snapToMarkerAnimated:YES];
        if (self.delegate && [self.delegate respondsToSelector:@selector(pickerView:didSelectValue:)]) {
            [self callDelegateWithNewValueFromOffset:[self.scrollView contentOffset].x];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self snapToMarkerAnimated:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerView:didSelectValue:)]) {
        [self callDelegateWithNewValueFromOffset:[self.scrollView contentOffset].x];
    }    
}

- (void)callDelegateWithNewValueFromOffset:(CGFloat)offset {

    float distanceBetweenItems = [self spacerSizePerStep].width;
    
    CGFloat offSet = ((offset - (distanceBetweenItems/2.0f)) / distanceBetweenItems);
    if (0.0f > offSet) {
        offSet = 0.0f;
    }
//    NSUInteger target = (NSUInteger)(offSet + 0.35f);
    NSUInteger target = (NSUInteger)roundf(offSet);
    target = target > steps ? steps - 1 : target;
    CGFloat newValue = target * [self sizeOfEachStep] + minimumValue;
    value = newValue;
    
    [self.delegate pickerView:self didSelectValue:newValue];
    
}

- (void)snapToMarkerAnimated:(BOOL)animated {

    float distanceBetweenItems = [self spacerSizePerStep].width;
    
    CGFloat position = [self.scrollView contentOffset].x;

//    NSLog(@"HorizPicker itemWidth: %.f position: %.f",itemWidth,position);
    
    if (position < self.scrollViewMarkerContainerView.frame.size.width - self.frame.size.width / 2) {
        CGFloat newPosition = 0.0f;
        CGFloat offSet = ((position - (distanceBetweenItems/2.0f)) / distanceBetweenItems);
        if (0.0f > offSet) {
            offSet = 0.0f;
        }
//        NSUInteger target = (NSUInteger)(offSet + 0.35f);
         NSUInteger target = (NSUInteger)roundf(offSet);
        target = target > steps ? steps - 1 : target;
        float labelWidth = [self labelSizePerStep].width;
        newPosition = roundf(target * distanceBetweenItems + (labelWidth / 2.0f));
        [self.scrollView setContentOffset:CGPointMake(newPosition, 0.0f) animated:animated];
        CGFloat newValue = target * [self sizeOfEachStep] + minimumValue;
        value = newValue;
        
//        NSLog(@"HorizPicker snap: offset:%.f target:%i newPosition: %.f newValue:%.f",offSet,target,newPosition,newValue);
        
        [self.delegate pickerView:self didSnapToValue:newValue];
    }
}

- (void)removeAllMarkers {
    for (id marker in self.scrollViewMarkerLayerArray) {
        [(CATextLayer *)marker removeFromSuperlayer];
    }
    [self.scrollViewMarkerLayerArray removeAllObjects];
}

- (void)setupMarkers;
{
    [self removeAllMarkers];
    
    // Calculate the new size of the content
    float leftPadding = self.frame.size.width / 2;
    float distanceBetweenItems = [self spacerSizePerStep].width;
    float labelItemWidth = [self labelSizePerStep].width;
    float rightPadding = leftPadding;
    float contentWidth = leftPadding + (steps * distanceBetweenItems) + rightPadding + labelItemWidth / 2;

    self.scrollView.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
    
    // Set the size of the marker container view
    [self.scrollViewMarkerContainerView setFrame:CGRectMake(0.0f, 0.0f, contentWidth, self.frame.size.height)];
    
    // Configure the new markers
    self.scrollViewMarkerLayerArray = [NSMutableArray arrayWithCapacity:steps];
    for (int i = 0; i <= steps; i++) {
        
        float currentValue = (float) minimumValue + i * (maximumValue - minimumValue) / steps;
        
        if (nil != self.delegate && [self.delegate respondsToSelector:@selector(scaleTypeForPickerView:)]) {
            
            STHorizontalPickerScaleType scaleType = [self.delegate scaleTypeForPickerView:self];
            
            STHorizontalPickerScale *scaleLayer = nil;
            CGRect layerFrame = CGRectIntegral(CGRectMake(leftPadding + i*distanceBetweenItems, 0, labelItemWidth, (self.frame.size.height-5.0f)));

            switch (scaleType) {
                case STHorizontalPickerScaleType_None:  {
                    
                    scaleLayer = (STHorizontalPickerScaleDecimal *)[[STHorizontalPickerScaleDecimal alloc] init];
                    scaleLayer.frame = layerFrame;
                    scaleLayer.contentsScale = scale;
                    scaleLayer.labelColor = [UIColor cptPrimaryColor].CGColor;
                    scaleLayer.scaleColor = [UIColor clearColor].CGColor;

                }   break;
                case STHorizontalPickerScaleType_Simple:  {
                    
                    scaleLayer = (STHorizontalPickerScaleSimple *)[[STHorizontalPickerScaleSimple alloc] init];
                    scaleLayer.frame = layerFrame;
                    scaleLayer.contentsScale = scale;
                    scaleLayer.labelColor = [UIColor cptPrimaryColor].CGColor;
                    scaleLayer.scaleColor = [UIColor cptPrimaryColor].CGColor;

                }   break;
                case STHorizontalPickerScaleType_Decimal:  {
                    
                    scaleLayer = (STHorizontalPickerScaleDecimal *)[[STHorizontalPickerScaleDecimal alloc] init];
                    scaleLayer.frame = layerFrame;
                    scaleLayer.contentsScale = scale;
                    scaleLayer.labelColor = [UIColor cptPrimaryColor].CGColor;
                    scaleLayer.scaleColor = [UIColor cptPrimaryColor].CGColor;

                }   break;

                default:
                    break;
            }
            
            scaleLayer.labelSizePerStep = self.labelSizePerStep;
            scaleLayer.spacerSizePerStep = self.spacerSizePerStep;
            scaleLayer.fontSize = self.fontSize;
            
            if (nil != self.delegate && [self.delegate respondsToSelector:@selector(displayStringForPickerView:atStep:withValue:)]) {
                scaleLayer.primaryLabel = (__bridge CFStringRef)[self.delegate displayStringForPickerView:self atStep:i withValue:currentValue];
            } else {
                scaleLayer.primaryLabel = (__bridge CFStringRef)[NSString stringWithFormat:@"%.0f", currentValue];
            }
            
            [self.scrollViewMarkerLayerArray addObject:scaleLayer];
            [self.scrollViewMarkerContainerView.layer addSublayer:scaleLayer];

        } else {
            CGRect layerFrame = CGRectIntegral(CGRectMake(leftPadding + i*distanceBetweenItems, 0, labelItemWidth, (self.frame.size.height-5.0f)));
            STHorizontalPickerScaleDecimal *scaleLayer = [[STHorizontalPickerScaleDecimal alloc] init];
            scaleLayer.frame = layerFrame;
            scaleLayer.contentsScale = scale;
            scaleLayer.labelColor = [UIColor cptPrimaryColor].CGColor;
            scaleLayer.scaleColor = [UIColor cptPrimaryColor].CGColor;
            scaleLayer.primaryLabel = (__bridge CFStringRef)[NSString stringWithFormat:@"%.0f", currentValue];
            
            [self.scrollViewMarkerLayerArray addObject:scaleLayer];
            [self.scrollViewMarkerContainerView.layer addSublayer:scaleLayer];

        }
    }
}

- (CGSize)labelSizePerStep;
{
    if (CGSizeEqualToSize(CGSizeZero, _labelSizePerStep)) {
        // Force initialization of the size
        [self setLabelSizePerStep:_labelSizePerStep];
    }
    return _labelSizePerStep;
}

-(void)setLabelSizePerStep:(CGSize)newSize;
{
    if (CGSizeEqualToSize(CGSizeZero, newSize)) {
        if (nil != self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(labelSizePerStepForPickerView:)]) {
            // Get Size from delegate if available
            _labelSizePerStep = [self.delegate labelSizePerStepForPickerView:self];
        } else {
            // Get Size from defaults
            _labelSizePerStep = CGSizeMake(TEXT_LAYER_WIDTH, self.bounds.size.height);
        }
    } else {
        _labelSizePerStep = newSize;
    }
    [self setNeedsLayout];
}

- (CGSize)spacerSizePerStep;
{
    if (CGSizeEqualToSize(CGSizeZero, _spacerSizePerStep)) {
        // Force initialization of the size
        [self setSpacerSizePerStep:_spacerSizePerStep];
    }
    return _spacerSizePerStep;
}

-(void)setSpacerSizePerStep:(CGSize)newSize;
{
    if (CGSizeEqualToSize(CGSizeZero, newSize)) {
        if (nil != self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(spacerSizePerStepForPickerView:)]) {
            // Get Size from delegate if available
            _spacerSizePerStep = [self.delegate spacerSizePerStepForPickerView:self];
        } else {
            // Get Size from defaults
            _spacerSizePerStep = CGSizeMake(DISTANCE_BETWEEN_ITEMS, self.bounds.size.height);
        }
    } else {
        _spacerSizePerStep = newSize;
    }
    [self setNeedsLayout];
}

- (NSArray *)dropShadowColorArray;
{
    UIColor *mainColor;
    if (nil != self.dropShadowColor) {
        mainColor = self.dropShadowColor;
    } else {
        mainColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
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
        mainColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
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
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.5f alpha:alpha*0.95f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.75f alpha:alpha*0.8f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*1.0f alpha:alpha*0.1f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*1.0f alpha:alpha*0.1f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.75f alpha:alpha*0.8f] CGColor],
            (id)[[UIColor colorWithHue:hue saturation:saturation brightness:brightness*.5f alpha:alpha*0.95f] CGColor], nil];
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

-(CGFloat)sizeOfEachStep;
{
    if (0 == steps) {
        return 0.0f;
    }
    return (([self maximumValue] - [self minimumValue]) / (CGFloat)[self steps]);
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

    if (nil != self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(fontSizeForPrimaryLabelString:)]) {
        fontSize = [self.delegate fontSizeForLabelForPickerView:self];
    } else {
        fontSize = newFontSize;
    }

    [self setupMarkers];
}

- (void)setValue:(CGFloat)newValue {
    value = newValue > maximumValue ? maximumValue : newValue;
    value = newValue < minimumValue ? minimumValue : newValue;
    
    float distanceBetweenItems = [self spacerSizePerStep].width;
    float labelItemWidth = [self labelSizePerStep].width;
    
    CGFloat itemWidth = (float) distanceBetweenItems;
    CGFloat xValue;
    if (maximumValue == minimumValue || steps == 0) {
        xValue = 0.0f;
    } else {
        xValue = (newValue - minimumValue) / ((maximumValue-minimumValue) / steps) * itemWidth + labelItemWidth / 2;
    }
    
    [self.scrollView setContentOffset:CGPointMake(xValue, 0.0f) animated:NO];
}

- (void)moveToMidPointValue;
{
    CGFloat midPoint = ((maximumValue + minimumValue) / 2.0f);
    [self setValue:midPoint];
}

-(void)moveToValue:(CGFloat)newValue withSnap:(BOOL)snap updateDelegate:(BOOL)updateDelegate;
{
    [self setValue:newValue];
    if (snap) {
        [self snapToMarkerAnimated:NO];
    }
    if (updateDelegate && nil != self.delegate) {
        if ([self.delegate respondsToSelector:@selector(pickerView:didSelectValue:)]) {
            [self callDelegateWithNewValueFromOffset:[self.scrollView contentOffset].x];
        }
    }
}

- (id)delegate {
    return _delegate;
}

- (void)setDelegate:(id<STHorizontalPickerDelegate>)newDelegate {
    _delegate = newDelegate;
    
    [self resetMinMaxAndMarkersForPickerView];
}

-(void)resetMinMaxAndMarkersForPickerView;
{
    NSUInteger needsReset = 0;
    
    if ([self.delegate respondsToSelector:@selector(minimumValueForPickerView:)]) {
        CGFloat newMinValue = [self.delegate minimumValueForPickerView:self];
        if (newMinValue != minimumValue) {
            minimumValue = newMinValue;
            needsReset += 1;
        }
    }
    if ([self.delegate respondsToSelector:@selector(maximumValueForPickerView:)]) {
        CGFloat newMaxValue = [self.delegate maximumValueForPickerView:self];
        if (newMaxValue != maximumValue) {
            maximumValue = newMaxValue;
            needsReset += 1;
        }
    }
    if ([self.delegate respondsToSelector:@selector(stepCountForPickerView:)]) {
        CGFloat newStepsValue = [self.delegate stepCountForPickerView:self];
        if (newStepsValue != steps) {
            steps = newStepsValue;
            needsReset += 1;
        }
    }
    if ([self.delegate respondsToSelector:@selector(scaleTypeForPickerView:)]) {
        STHorizontalPickerScaleType scaleType = [self.delegate scaleTypeForPickerView:self];
        if (scaleType != STHorizontalPickerScaleType_None) {
            needsReset += 1;
        }
    }
    
    if (needsReset > 0) {
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

-(BOOL)isScrolling;
{
    return (scrollView.isDragging || scrollView.isDecelerating || scrollView.isTracking);
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
    CGPathRelease(path);
    
    CGContextRestoreGState(context);
}

@end
