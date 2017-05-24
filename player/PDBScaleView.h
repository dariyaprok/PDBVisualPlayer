//
//  BAScaleView.h
//  Bar'n and Hooksz
//
//  Created by Dasha on 12/2/16.
//  Copyright © 2016 34in. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDBScaleView : UIImageView

- (void)reloadDataForWidth:(CGFloat)width andSecondsInterval:(NSInteger) secondsInterval;
- (void)reloadData;

@end
