//
//  Player.m
//  Player
//
//  Created by Dasha on 4/21/17.
//  Copyright © 2017 Basquare. All rights reserved.
//

#import "Player.h"
#import "PitchHelper.h"

#define AUDIO_CHECK(value, op) success = (success && !CheckError (value, op));

bool CheckError(OSStatus error, const char *operation) {
    if (error != noErr)
    {
        char errorString[20] = {'\\'};
        
        *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
        if (isprint(errorString[1]) &&
            isprint(errorString[2]) &&
            isprint(errorString[3]) &&
            isprint(errorString[4]))
        {
            errorString[0] = errorString[5] = '\''; errorString[6] = '\0';
            
        } else {
            sprintf(errorString, "%d", (int)error);
        }
        NSLog(@"Error: %s (%s)\n", operation, errorString);
    }
    return error != noErr;
}

typedef struct {
    AudioUnit fileUnit;
    soundTouch_type soundTouch;
    float outputData[21474836];
    float *outputPointer;
    float *inputPointer;
    float inputData[21474836];
    int inputPosition;
    int lastInputedBuffer;
    int fillBufferPosition;
    int bufferPosition;
    int leftBuffers;
    float tempo;
} CallbackInfo;

static OSStatus InputModalityRenderCallBack (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    CallbackInfo *info = (CallbackInfo *)inRefCon;
    CheckError(AudioUnitRender(info->fileUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData), "Couldn't render");
    
    //read samples
    int bufferLength = ioData->mNumberBuffers *  inNumberFrames;
    //    float inputPointer[bufferLength];
    
    int bufferPosition = 0;
    for (int frame = 0; frame < inNumberFrames; ++ frame) {
        for (int bufferCount = 0; bufferCount < ioData->mNumberBuffers; ++ bufferCount) {
            float *data = (float*)ioData->mBuffers[bufferCount].mData;
            float sample = data[frame];
            info->inputPointer[info->inputPosition + bufferPosition++] = sample;
            //ioData->mBuffers[bufferCount].mData = nil;
        }
    }
    
    info->inputPosition += bufferPosition;
    putSamples(info->soundTouch, info->inputPointer + info->lastInputedBuffer, bufferLength/*(float)(bufferLength * info->tempo)*/);
    info->lastInputedBuffer += bufferLength;
    int numberOfSamples = 0;
    
    do {
        numberOfSamples = recieveSamples(info->soundTouch, (info->outputPointer + info->bufferPosition), bufferLength);
        info->bufferPosition += numberOfSamples;
        //        printf("%d number of recieving \n", numberOfSamples);
    }
    while (numberOfSamples > 0);
    if (info->bufferPosition - info->fillBufferPosition > 0) {
        for (int frame = 0; frame < inNumberFrames; ++ frame) {
            for (int bufferCount = 0; bufferCount<ioData->mNumberBuffers; ++ bufferCount) {
                float newData = info->outputPointer[info->fillBufferPosition];
                float *data = (float*)ioData->mBuffers[bufferCount].mData;
                (data)[frame] = newData;
                info->fillBufferPosition++;
            }
        }
    }
    
    return noErr;
}


@interface Player () <AVAudioPlayerDelegate>
{
    AUGraph graph;
    AUNode outputNode;
    AUNode fileNode;
    AudioUnit outputUnit;
    //AudioUnit fileUnit;
    AudioFileID inputFileID;
    AudioStreamBasicDescription inputFormat;
    CallbackInfo info;
}

@end

@implementation Player

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
        self.startFromTime = 0;
        self.delayTime = 0;
        self.pitch = 0;
        self.tempo = 1.0;
        self.finishAtTime = 0;
        self.isLoop = false;
        [self setupGraph];
    }
    return self;
}

#pragma mark - public
- (void)stop {
    CheckError(AUGraphStop(graph), "Can't stop graph");
}

- (void)play {
    Boolean isUpdated;
    CheckError(AUGraphUpdate(graph, &isUpdated), "Can't update");
    CheckError(AUGraphStart(graph), "Can't start graph");
}


- (void)prepareInputFile {
    
    //allow read file
    CheckError(AudioFileOpenURL(CFBridgingRetain(self.path), kAudioFileReadPermission, 0, &(inputFileID)), "Can't add read permission");
    
    //get input format
    UInt32 inputFormatSize = sizeof(inputFormat);
    CheckError(AudioFileGetProperty(inputFileID, kAudioFilePropertyDataFormat, &inputFormatSize, &inputFormat), "Can't get input format");
    
    //add callback
    [self setupCallback];
    
    CheckError(AudioUnitSetProperty(info.fileUnit, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &inputFileID, sizeof(inputFileID)), "Can't create input File");
    
    UInt64 nPackets = 0;
    UInt32 propSize = sizeof(nPackets);
    CheckError(AudioFileGetProperty(inputFileID, kAudioFilePropertyAudioDataPacketCount, &propSize, &nPackets), "Can't get pcket count");
    
    //tell the player AU to play the entire file
    ScheduledAudioFileRegion rgn;
    memset(&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = (float)_delayTime * inputFormat.mSampleRate / 1000.0;
    rgn.mCompletionProc = NULL;
    rgn.mCompletionProcUserData = NULL;
    rgn.mAudioFile = inputFileID;
    rgn.mLoopCount = (_isLoop || info.tempo != 1.0 )? -1 : 0;
    
    //start at functionality
    rgn.mStartFrame = (int)(((float)(self.startFromTime) * inputFormat.mSampleRate) / 1000.0);
    
    UInt32 framesToPlay;
    if (_finishAtTime == 0) {
        framesToPlay = (int)(float)((float)nPackets * ((float)inputFormat.mFramesPerPacket / info.tempo));
    }
    else {
        framesToPlay = (int)(((float)((_finishAtTime - _startFromTime) * inputFormat.mSampleRate)) / 1000.0);
    }
    _currentDuration = ((float)framesToPlay * 1000) / inputFormat.mSampleRate;
    rgn.mFramesToPlay = framesToPlay;
    
    //delay functionality
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = self.delayTime / 1000.0 * inputFormat.mSampleRate;
    
    CheckError(AudioUnitSetProperty(info.fileUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &rgn, sizeof(rgn)), "Can't set sheduled file region");
    
    // prime the file player AU with default values
    UInt32 defaultVal = 0;
    CheckError(AudioUnitSetProperty(info.fileUnit, kAudioUnitProperty_ScheduledFilePrime,
                                    kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal)),
               "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFilePrime] failed");
    
    
    //tell the player when to start play
    AudioTimeStamp startTime;
    memset(&startTime, 0, sizeof(startTime));
    startTime.mFlags = kAudioTimeStampSampleTimeValid;
    startTime.mSampleTime = -1;
    CheckError(AudioUnitSetProperty(info.fileUnit, kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)), "Audio unit set start time stamp");
    
}

#pragma mark - private
- (void)setupGraph {
    // create a new AUGraph
    CheckError(NewAUGraph(&(graph)), "Can't create new graph");
    
    //create output node
    AudioComponentDescription outputDescription;
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    CheckError(AUGraphAddNode(graph, &outputDescription, &outputNode), "Can't create output node");
    
    //crate file node
    AudioComponentDescription fileNodeDescription;
    fileNodeDescription.componentType = kAudioUnitType_Generator;
    fileNodeDescription.componentSubType = kAudioUnitSubType_AudioFilePlayer;
    fileNodeDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    CheckError(AUGraphAddNode(graph, &fileNodeDescription, &fileNode), "Can't create file node");
    
    //open graph
    CheckError(AUGraphOpen(graph), "Open graph failed");
    
    //create file unit
    CheckError(AUGraphNodeInfo(graph, fileNode, 0, &info.fileUnit), "Can't create file unit");
    
    //create output unit
    CheckError(AUGraphNodeInfo(graph, outputNode, 0, &outputUnit), "Can't create output unit");
    
    //connect output node to input file node
    CheckError(AUGraphConnectNodeInput(graph, fileNode, 0, outputNode, 0), "Can't connect output node");
    
    //initialixe graph
    CheckError(AUGraphInitialize(graph), "Can't initialize graph");
}

- (void)setupCallback {
    if (_pitch != 0 || _tempo != 1.0) {
        
        info.soundTouch = initSoundTouch();
        setSampleRate(info.soundTouch, inputFormat.mSampleRate);
        setChannelCount(info.soundTouch, 1);
        setTempo(info.soundTouch, _tempo);
        setPitch(info.soundTouch, _pitch);
        info.tempo = _tempo;
        
        UInt32 framesToPlay;
        if (_finishAtTime == 0) {
            framesToPlay = 360 * inputFormat.mSampleRate;
        }
        else {
            framesToPlay = (_finishAtTime - _startFromTime)/1000 * inputFormat.mSampleRate;
        }
        //float outputData[framesToPlay];
        //        info.outputPointer = outputData;
        info.bufferPosition = 0;
        info.fillBufferPosition = 0;
        info.inputPosition = 0;
        info.lastInputedBuffer = 0;
        info.outputPointer = info.outputData;
        info.inputPointer = info.inputData;
        
        AURenderCallbackStruct callBackStruct;
        callBackStruct.inputProc = InputModalityRenderCallBack;
        callBackStruct.inputProcRefCon = &info;
        
        
        CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0, &callBackStruct, sizeof(callBackStruct)), "Couldn't set renser's callback");
    }
    //    else {
    //        CheckError(AudioUnitSetProperty(nil, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0, &callBackStruct, sizeof(callBackStruct)), "Couldn't set renser's callback");
    //    }
}

- (void)dealloc
{
    if (info.soundTouch) {
        destroy(info.soundTouch);
    }
    if (inputFileID) {
        AudioFileClose(inputFileID);
    }
    CheckError(AUGraphUninitialize(graph), "Can't unitialize graph");
    CheckError(AUGraphClose(graph), "Can't clase graph");
}

@end


