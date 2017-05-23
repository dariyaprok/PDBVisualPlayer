//
//  BAWaveFormViewMaker.h
//  Bar'n and Hooksz
//
//  Created by Dasha on 9/28/16.
//  Copyright © 2016 34in. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAWaveFormViewMaker : NSObject

+ (instancetype) sharedWaveFormMaker;
- (void) makeWaveformImageForPath: (NSString *)path pitch:(float)pitch tempo:(float)tempo;
- (float) widthForPath: (NSString *)path;

@end
