//
//  Senerity.m
//  TimbreGroove
//
//  Created by victor on 2/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Scene.h"
#import "Names.h"
#import "Audio.h"
#import "Sampler.h"
#import "TriggerMap.h"
#import "NSString+Tweening.h"
#import "NoteGenerator.h"

#define AMBIENCE_VIRTUAL_CHANNEL 1
#define CONGAS_VIRTUAL_CHANNEL   0

@interface Serenity : Audio

@end

@interface Serenity() {
    NoteGenerator * _congasScale;
    NoteGenerator * _ambientScale;
    FloatParamBlock _channelVolume;
    FloatParamBlock _channelVolumeDecay;
    IntParamBlock   _selectChannel;
    PointerParamBlock _midiNote;
    UInt32 _ambienceChannel;
    UInt32 _congasChannel;
}

@end
@implementation Serenity

-(void)start
{
    [super start];
    
    _ambienceChannel = [self realChannelFromVirtual:AMBIENCE_VIRTUAL_CHANNEL];
    
    Sampler * congas = _instruments[CONGAS_VIRTUAL_CHANNEL];
    _congasChannel = congas.channel;
    NoteRange congasRange = (NoteRange){ congas.lowestPlayable, congas.highestPlayable };
    _congasScale = [[NoteGenerator alloc] initWithScale:kScaleSemitones isRandom:false andRange:congasRange];
    
    _ambientScale = [[NoteGenerator alloc] initWithScale:kScaleMinor isRandom:true];
    _ambientScale.range = (NoteRange){ 45, 80 };
}

-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    static NSString const * kChannelVolumeDecay = nil;
    
    if( !kChannelVolumeDecay )
        kChannelVolumeDecay = [kParamChannelVolume stringByAppendingTween:kTweenEaseInSine len:0.5];

    if( scene )
    {
        TriggerMap * tm = scene.triggers;
        _channelVolume      = [tm getFloatTrigger: kParamChannelVolume];
        _channelVolumeDecay = [tm getFloatTrigger  :kChannelVolumeDecay];
        _selectChannel      = [tm getIntTrigger    :kParamChannel];
        _midiNote           = [tm getPointerTrigger:kParamMIDINote];
    }
    else
    {
        _channelVolume = nil;
        _channelVolumeDecay = nil;
        _selectChannel = nil;
        _midiNote = nil;
    }
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"SwellSound"] = [Parameter withBlock:
                              ^(CGPoint pt)
                              {
                                  MIDINoteMessage mnm;
                                  _selectChannel(_ambienceChannel);
                                  _channelVolume(1);
                                  mnm.note = [_ambientScale next];
                                  mnm.duration = 1.1;
                                  mnm.velocity = 127;
                                  mnm.channel = _ambienceChannel;
                                  _midiNote(&mnm);
                                  mnm.note = [_ambientScale next];
                                  _midiNote(&mnm);
                                  _channelVolumeDecay(0.2);
                              }];
}
@end
