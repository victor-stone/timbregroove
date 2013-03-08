//
//  Audio.m
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Audio.h"
#import "SoundSystem.h"
#import "Midi.h"
#import "SoundSystemParameters.h"
#import "Config.h"
#import "Scene.h"
#import "Names.h"
#import "Instrument.h"

@interface Audio () {
@protected
    SoundSystem *           _soundSystem;
    SoundSystemParameters * _parameters;
    
    NSString * _eqName;
    
    Midi *     _midi;
    MidiFile * _midiSequence;
    NSString * _midiFileName;
}

@end
@implementation Audio

+(id)audioFromConfig:(ConfigAudioProfile *)config withScene:(Scene *)scene
{
    Class klass = NSClassFromString(config.instanceClass);
    Audio * audio = [klass new];
    [audio loadAudioFromConfig:config];
    return audio;
}

- (id)init
{
    self = [super init];
    if (self) {
        _soundSystem = [SoundSystem sharedInstance];
        _parameters = [[SoundSystemParameters alloc] initWithSoundSystem:_soundSystem];
        _midi = [[Midi alloc] init];
    }
    return self;
}

-(void)dealloc
{
    [_instruments each:^(id name, id instrument) {
        [_soundSystem decomissionInstrument:instrument];
    }];
    
    NSLog(@"Audio object gone");
}

-(void)loadAudioFromConfig:(ConfigAudioProfile *)config
{
    _instruments = [NSMutableDictionary new];
    [config.instruments each:^(id name, id configInstrument) {
        _instruments[name] = [_soundSystem loadInstrumentFromConfig:configInstrument];
    }];
    _midiFileName = config.midiFile;
    _eqName = config.EQ;
}

-(void)start
{
    if( _midiSequence )
    {
        [_midiSequence start];
    }
    else
    {
        Instrument * instrument = [_instruments allValues][0];
        [_midi setupMidiFreeRange:instrument];
    }

    if( _eqName )
        _parameters.selectedEQBandName = _eqName;
}

-(void)play
{
    [_instruments each:^(id name, id instrument) {
        [_soundSystem plugInstrumentIntoBus:instrument];
    }];

    if( _midiSequence )
        [_midiSequence resume];
}

-(void)pause
{
    if( _midiSequence )
        [_midiSequence pause];
    
    [_instruments each:^(id name, id instrument) {
        [_soundSystem unplugInstrumentFromBus:instrument];
    }];
}

-(void)update:(NSTimeInterval)dt
{
    [_soundSystem update:dt];
    [_parameters update:dt];
    [_midi update:dt];
}

-(void)triggersChanged:(Scene *)scene
{
    [_parameters triggersChanged:scene];
    [_soundSystem triggersChanged:scene];
    [_midi triggersChanged:scene];
}

-(void)getParameters:(NSMutableDictionary *)putHere;
{
    // get parameters will configure the
    // defaults
    [_parameters getParameters:putHere];
    [_midi getParameters:putHere];
}

- (void)getSettings:(NSMutableArray *)putHere
{
    
}

@end

@interface AutoPlayMidiFile : Audio
@end
@implementation AutoPlayMidiFile

-(void)start
{
    if( _midiFileName && !_midiSequence )
    {
        Instrument * instrument = [_instruments allValues][0];
        _midiSequence = [_midi setupMidiFile:_midiFileName withInstrument:instrument];
    }
    [super start];
    
}


@end