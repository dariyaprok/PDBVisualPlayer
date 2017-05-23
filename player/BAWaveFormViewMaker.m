//
//  BAWaveFormViewMaker.m
//  Bar'n and Hooksz
//
//  Created by Dasha on 9/28/16.
//  Copyright © 2016 34in. All rights reserved.
//

#import "BAWaveFormViewMaker.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PitchHelper.h"

#define absX(x) (x<0?0-x:x)
#define minMaxX(x,mn,mx) (x<=mn?mn:(x>=mx?mx:x))
#define noiseFloor (-50.0)
#define decibel(amplitude) (20.0 * log10(absX(amplitude)/32767.0))
#define imgExt @"png"
#define imageToData(x) UIImagePNGRepresentation(x)

#define pixelsScale 20

@interface BAWaveFormViewMaker ()

@property (strong, nonatomic) NSMutableArray *pathsQueue;

@end



@implementation BAWaveFormViewMaker

#pragma mark - public
- (void)makeWaveformImageForPath:(NSString *)path pitch:(float)pitch tempo:(float)tempo {
    NSDictionary *dataDictionary = @{@"path": path,
                                     @"pitch": @(pitch),
                                     @"tempo": @(tempo)};
    [self.pathsQueue addObject:dataDictionary];
    if (self.pathsQueue.count == 1) {
        [self startImplementWaveformImage];
    }
}


- (void) startImplementWaveformImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *dataDictionary = [self.pathsQueue firstObject];
        NSString *path = dataDictionary[@"path"];
        NSURL * fileURL;
        if (![path containsString:@"//"]) {
            fileURL = [NSURL fileURLWithPath:path];
        }
        else {
            fileURL = [NSURL URLWithString:path];
        }
        AVURLAsset * urlA = [AVURLAsset URLAssetWithURL:fileURL options:nil];
        UIImage *waveformImage = [UIImage imageWithData:[self renderPNGAudioPictogramLogForAssett:urlA options:dataDictionary]];
        CGSize newsize = CGSizeMake([self widthForPath:path], 50.0);
        UIGraphicsBeginImageContext(newsize);
        [waveformImage drawInRect:CGRectMake(0, 0, newsize.width, newsize.height)];
        UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BAWaveFormImageNotification" object:self userInfo:@{@"waveFormImage" : finalImage, @"path" : path}];
        [self.pathsQueue removeObject:dataDictionary];
        if (self.pathsQueue.count) {
            [self startImplementWaveformImage];
        }
    });
}

+ (instancetype) sharedWaveFormMaker {
    static BAWaveFormViewMaker *waveFormMaker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        waveFormMaker = [BAWaveFormViewMaker new];
    });
    return waveFormMaker;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        _pathsQueue = [NSMutableArray new];
    }
    return self;
}

- (float)widthForPath:(NSString *)path {
    NSURL * fileURL;
    if (![path containsString:@"//"]) {
        fileURL = [NSURL fileURLWithPath:path];
    }
    else {
        fileURL = [NSURL URLWithString:path];
    }
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    CGFloat seconds = CMTimeGetSeconds(songAsset.duration);
    CGFloat pixelsForLength = seconds * pixelsScale;
    return pixelsForLength/[[UIScreen mainScreen] scale];
}

#pragma mark - private
-(UIImage *) audioImageLogGraph:(Float32 *) samples
                   normalizeMax:(Float32) normalizeMax
                    sampleCount:(NSInteger) sampleCount
                     imageWidth:(float) imageWidth
                    imageHeight:(float) imageHeight {
    
    CGSize imageSize = CGSizeMake(sampleCount, imageHeight);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextSetAlpha(context, 1.0);
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    CGColorRef leftcolor = [[UIColor colorWithRed:122.0f/255.0f green:109.0f/255.0f blue:55.0f/255.0f alpha:1.0f] CGColor];
    
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0);
    
    float halfGraphHeight = (imageHeight / 2);
    float centerLeft = halfGraphHeight;
    float sampleAdjustmentFactor = imageHeight / (normalizeMax - noiseFloor)/2;
    
    for (NSInteger intSample = 0 ; intSample < sampleCount ; intSample ++ ) {
        Float32 left = *samples++;
        float pixels = (left - noiseFloor) * sampleAdjustmentFactor;
        CGContextMoveToPoint(context, intSample, centerLeft-pixels);
        CGContextAddLineToPoint(context, intSample, centerLeft+pixels);
        CGContextSetStrokeColorWithColor(context, leftcolor);
        CGContextStrokePath(context);
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}



- (NSData *) renderPNGAudioPictogramLogForAssett:(AVURLAsset *)songAsset options:(NSDictionary *)options {
    
    CGFloat seconds = CMTimeGetSeconds(songAsset.duration);
    CGFloat pixelsForLength = seconds * pixelsScale;
    CGFloat length = pixelsForLength/[[UIScreen mainScreen] scale];
    
    NSError * error = nil;
    
    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    
    AVAssetTrack * songTrack = [songAsset.tracks objectAtIndex:0];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        
                                        nil];
    
    
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    
    [reader addOutput:output];
    
    UInt32 sampleRate = 0;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(fmtDesc ) {
            
            sampleRate = fmtDesc->mSampleRate;
            
        }
    }
    
    UInt32 bytesPerSample = 2;
    Float32 normalizeMax = noiseFloor;
    NSLog(@"normalizeMax = %f",normalizeMax);
    NSMutableData * fullSongData = [[NSMutableData alloc] init];
    [reader startReading];
    
    UInt64 totalBytes = 0;
    
    Float64 totalLeft = 0;
    Float64 totalRight = 0;
    Float32 sampleTally = 0;
    
    //NSTimeInterval duration = (float)songAsset.duration.value/(float)songAsset.duration.timescale;
    NSInteger samplesPerPixel = sampleRate / 50;
    
    while (reader.status == AVAssetReaderStatusReading){
        
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            totalBytes += length;
            
            
            NSMutableData * data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            
            SInt16 * samples = (SInt16 *) data.mutableBytes;
            int sampleCount = (int)length / bytesPerSample;
            for (int i = 0; i < sampleCount ; i ++) {
                
                Float32 left = (Float32) *samples++;
                left = decibel(left);
                left = minMaxX(left,noiseFloor,0);
                
                totalLeft  += left;
                
                
                
                sampleTally++;
                
                if (sampleTally > samplesPerPixel) {
                    
                    left  = totalLeft / sampleTally;
                    if (left > normalizeMax) {
                        normalizeMax = left;
                    }
                    
                    [fullSongData appendBytes:&left length:sizeof(left)];
                    
                    
                    totalLeft   = 0;
                    totalRight  = 0;
                    sampleTally = 0;
                    
                }
            }
            
            
            CMSampleBufferInvalidate(sampleBufferRef);
            
            CFRelease(sampleBufferRef);
        }
    }
    
    NSData * finalData = nil;
    
    if (reader.status == AVAssetReaderStatusCompleted){
        
        NSLog(@"rendering output graphics using normalizeMax %f",normalizeMax);
        
        NSLog(@"lenfgth of vie = %f, length of pixels = %f", length, pixelsForLength);
        
        UIImage *test;
        if ([options[@"tempo"] floatValue] == 1.0 && [options[@"pitch"] floatValue] == 0) {
            test = [self audioImageLogGraph:(Float32 *) fullSongData.bytes
                               normalizeMax:normalizeMax
                                sampleCount:fullSongData.length / sizeof(Float32)
                                 imageWidth:length
                                imageHeight:50];
        }
        else {
            soundTouch_type soundTouch = initSoundTouch();
            setSampleRate(soundTouch, 44100);
            setChannelCount(soundTouch, 1);
            setTempo(soundTouch, [options[@"tempo"] floatValue]);
            setPitch(soundTouch, [options[@"pitch"] floatValue]);
            putSamples(soundTouch, (Float32 *)fullSongData.bytes, (int) fullSongData.length / sizeof(Float32));
            float data[fullSongData.length / sizeof(Float32)];
            float *pointer = data;
            int numberOfSamples = 0;
            
            do {
                numberOfSamples = recieveSamples(soundTouch, pointer, (int) fullSongData.length / sizeof(Float32));
            }
            while (numberOfSamples > 0);
            test = [self audioImageLogGraph:pointer
                               normalizeMax:normalizeMax
                                sampleCount:fullSongData.length / sizeof(Float32)
                                 imageWidth:length
                                imageHeight:50];
        }
        
        //free(pointer);
        finalData = imageToData(test);
        
    }
    
    return finalData;
}
@end
