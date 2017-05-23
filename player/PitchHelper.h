//
//  PitchHelper.h
//  BAMixerPlayer
//
//  Created by Dasha on 10/28/16.
//  Copyright © 2016 TarasSheremet. All rights reserved.
//

#ifndef PitchHelper_h
#define PitchHelper_h

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

typedef void* soundTouch_type;
//struct SoundTouchStruct;


EXTERNC void changePitch (float *inputSamples, float *outputSamples, int numberOfSamples, float pitchLevel);
EXTERNC void putSamples (soundTouch_type st, float *samples, int numberOfSamples);
EXTERNC int recieveSamples (soundTouch_type st, float *samples, int numberOfSamples);
EXTERNC void flush (soundTouch_type st);
EXTERNC void setPitch (soundTouch_type st, float pitchLevel);
EXTERNC void setTempo (soundTouch_type st, float tempoLevel);
EXTERNC void setChannelCount (soundTouch_type st, int channelCount);
EXTERNC void setSampleRate (soundTouch_type st, long sampleRate);
EXTERNC void* initSoundTouch();
EXTERNC void clearSoundTouch(soundTouch_type st);
EXTERNC void destroy(soundTouch_type st);

#endif /* PitchHelper_h */
