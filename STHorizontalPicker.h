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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class STHorizontalPicker;

//================================
// Delegate protocol
//================================
@protocol STHorizontalPickerDelegate <NSObject>

@optional
- (CGFloat)minimumValueForPickerView:(STHorizontalPicker *)picker;
- (CGFloat)maximumValueForPickerView:(STHorizontalPicker *)picker;
- (NSUInteger)stepCountForPickerView:(STHorizontalPicker *)picker;
- (NSString *)displayStringForPickerView:(STHorizontalPicker *)picker atStep:(NSInteger)stepIndex withValue:(CGFloat)stepValue;
- (CATextLayer *)caTextLayerForPickerView:(STHorizontalPicker *)picker atStep:(NSInteger)stepIndex withValue:(CGFloat)stepValue frame:(CGRect)layerFrame;

@required
- (void)pickerView:(STHorizontalPicker *)picker didSelectValue:(CGFloat)value;
- (void)pickerView:(STHorizontalPicker *)picker didSnapToValue:(CGFloat)value;

@end

//================================
// UIColor category
//================================
@interface UIColor (STColorComponents)
- (CGFloat)red;
- (CGFloat)green;
- (CGFloat)blue;
- (CGFloat)alpha;
@end


//================================
// STHorizontalPicker interface
//================================
@interface STHorizontalPicker : UIView <UIScrollViewDelegate> {
    CGFloat value;
    
    NSUInteger steps;
    CGFloat minimumValue;
    CGFloat maximumValue;
    
    id delegate;
    
    UIColor *borderColor;
    UIColor *dropShadowColor;
    UIColor *gradientColor;
    UIColor *backColor;
    UIColor *textColor;
    UIColor *pointerFillColor;
    UIColor *pointerStrokeColor;
    
    UIFont *font;
    CGFloat fontSize;
    
    BOOL showScale;
    
    @private
    CGFloat scale; // Drawing scale    
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIColor *dropShadowColor;
@property (nonatomic, strong) UIColor *gradientColor;
@property (nonatomic, strong) UIColor *backColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *pointerFillColor;
@property (nonatomic, strong) UIColor *pointerStrokeColor;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) BOOL showScale;

- (void)loadAllViewComponents;
- (void)setupMarkers;

- (void)snapToMarkerAnimated:(BOOL)animated;

- (CGFloat)scale;

- (CGFloat)minimumValue;
- (void)setMinimumValue:(CGFloat)newMin;

- (CGFloat)maximumValue;
- (void)setMaximumValue:(CGFloat)newMax;

- (NSUInteger)steps;
- (void)setSteps:(NSUInteger)newSteps;

- (CGFloat)value;
- (void)setValue:(CGFloat)newValue;
- (void)moveToMidPointValue;

- (UIColor *)borderColor;
- (void)setBorderColor:(UIColor *)newColor;

- (UIColor *)dropShadowColor;
- (void)setDropShadowColor:(UIColor *)newColor;

- (UIColor *)gradientColor;
- (void)setGradientColor:(UIColor *)newColor;

- (UIColor *)backColor;
- (void)setBackColor:(UIColor *)newColor;

- (UIColor *)textColor;
- (void)setTextColor:(UIColor *)newColor;

- (UIColor *)pointerFillColor;
- (void)setPointerFillColor:(UIColor *)newColor;

- (UIColor *)pointerStrokeColor;
- (void)setPointerStrokeColor:(UIColor *)newColor;

- (CGFloat)fontSize;
- (void)setFontSize:(CGFloat)newFontSize;

- (id)delegate;
- (void)setDelegate:(id<STHorizontalPickerDelegate>)newDelegate;
- (void)callDelegateWithNewValueFromOffset:(CGFloat)offset;

- (BOOL)showScale;
- (void)setShowScale:(BOOL)newShowScale;

-(void)moveToValue:(CGFloat)newValue withSnap:(BOOL)snap updateDelegate:(BOOL)updateDelegate;
-(void)resetMinMaxAndMarkersForPickerView;

@end



//================================
// STPointerLayerDelegate interface
//================================
@interface STPointerLayerDelegate : NSObject <CALayerDelegate>
{}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context;

@end
