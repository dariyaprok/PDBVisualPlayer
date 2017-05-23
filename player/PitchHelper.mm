//
//  PitchHelper.c
//  BAMixerPlayer
//
//  Created by Dasha on 10/28/16.
//  Copyright © 2016 TarasSheremet. All rights reserved.
//

#include "PitchHelper.h"
#include <MacTypes.h>
#import <SoundTouch.h>


//
EXTERNC void* initSoundTouch() {
    return new soundtouch:: SoundTouch();
}

EXTERNC void putSamples (soundTouch_type st, float *samples, int numberOfSamples) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    soundTouch->putSamples(samples, numberOfSamples);
}

EXTERNC int recieveSamples (soundTouch_type st, float *samples, int numberOfSamples) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    return soundTouch->receiveSamples(samples, numberOfSamples);
}

EXTERNC void setPitch (soundTouch_type st, float pitchLevel) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    soundTouch->setPitchSemiTones(pitchLevel);
    soundTouch->setSetting(SETTING_USE_QUICKSEEK, 1);
    //    soundTouch->setSetting(SETTING_USE_AA_FILTER, 1);
}

EXTERNC void setTempo (soundTouch_type st, float tempoLevel) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    soundTouch->setTempo(tempoLevel);
    soundTouch->setSetting(SETTING_USE_QUICKSEEK, 1);
}

EXTERNC void flush (soundTouch_type st) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    soundTouch->flush();
}

//EXTERNC void changePitch (float *inputSamples, float *outputSamples, int numberOfSamples, float pitchLevel) {
//    soundtouch::SoundTouch soundTouch = soundtouch::SoundTouch();
//    soundTouch.putSamples(inputSamples, numberOfSamples);
//    soundTouch.setPitch(pitchLevel);
//
//    soundTouch.receiveSamples(outputSamples, numberOfSamples);
//}

EXTERNC void setSampleRate (soundTouch_type st, long sampleRate) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    soundTouch->setSampleRate(sampleRate);
}

EXTERNC void setChannelCount (soundTouch_type st, int channelCount) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    soundTouch->setChannels(channelCount);
}

EXTERNC void destroy (soundTouch_type st) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    soundTouch->~SoundTouch();
}

EXTERNC void clearSoundTouch(soundTouch_type st) {
    soundtouch:: SoundTouch *soundTouch = static_cast<soundtouch::SoundTouch *>(st);
    soundTouch->clear();
}
