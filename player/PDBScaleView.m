//
//  BAScaleView.m
//  Bar'n and Hooksz
//
//  Created by Dasha on 12/2/16.
//  Copyright © 2016 34in. All rights reserved.
//

#define defaultSecondsInterval 5
#define defaultSecondsTextWidth self.frame.size.height/2
#define pixelsScale 20

#import "PDBScaleView.h"
//#import "Constants.h"

@interface PDBScaleView ()

@property (nonatomic) float scaleImageWidth;
@property (nonatomic) NSInteger secondsInterval;
@property (nonatomic) NSInteger textSize;
@property (nonatomic) float scaleFactor;

@end

@implementation PDBScaleView

- (void)awakeFromNib {
    self.backgroundColor = [UIColor yellowColor];
}

- (void)reloadDataForWidth:(CGFloat)width andSecondsInterval:(NSInteger) secondsInterval{
    self.scaleImageWidth = width;
    self.secondsInterval = secondsInterval;
    self.scaleFactor = width>self.frame.size.width ? width/self.frame.size.width : 1;
    self.textSize = 8.0 * self.scaleFactor;
    [self implementScaleImage];
}

- (void)reloadData {
    self.scaleImageWidth = self.frame.size.width;
    self.secondsInterval = defaultSecondsInterval;
    self.scaleFactor = 1;
    self.textSize = 8.0;
    [self implementScaleImage];
}


- (void)implementScaleImage {
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentCenter;
    NSDictionary *attr = @{
                           NSParagraphStyleAttributeName:style,
                           NSFontAttributeName : [UIFont systemFontOfSize:self.textSize]
                           };
    CGRect rect = CGRectMake(0, 0, self.scaleImageWidth, self.frame.size.height * _scaleFactor);
    //CGSize size = CGSizeMake(self.scaleImageWidth, self.frame.size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetAlpha(context, 1.0);
    
    CGColorRef lineColor = [[UIColor redColor] CGColor];
    
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0 * _scaleFactor);
    //float scaleFactor = self.scaleImageWidth>self.frame.size.width ? self.scaleImageWidth/self.frame.size.width : 1;
    float defaultSecondsWidth = (self.secondsInterval *pixelsScale /** scaleFactor*/)/[[UIScreen mainScreen] scale] ;
    int fiveSecondsCount = self.scaleImageWidth / defaultSecondsWidth;
    for (int i=0; i<= fiveSecondsCount; ++i) {
        CGContextMoveToPoint(context, i* defaultSecondsWidth + 1, 0);
        CGContextAddLineToPoint(context, i * defaultSecondsWidth + 1,_scaleFactor * self.frame.size.height/3);
        CGContextSetStrokeColorWithColor(context, lineColor);
        CGContextStrokePath(context);
        [[NSString stringWithFormat:@"%i", i * self.secondsInterval] drawInRect:CGRectMake((i*defaultSecondsWidth - _scaleFactor*defaultSecondsWidth/2),  self.frame.size.height/4, defaultSecondsWidth * _scaleFactor, _scaleFactor * self.frame.size.height * 3/4) withAttributes:attr];
    }
    UIImage *scaleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self setImage:scaleImage];

}
@end
