//
//  Mixer.h
//  TimbreGroove
//
//  Created by victor on 1/27/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMIDI/CoreMIDI.h>

void CheckError( OSStatus error, const char *operation);

@interface Sound : NSObject
-(OSStatus)playNote:(int)note forDuration:(NSTimeInterval)duration;
-(void)playMidiFile:(NSString *)filename;
-(void)addNoteCache:(int)note ts:(MIDITimeStamp)ts;
@property (nonatomic,readonly) int lowestPlayable;
@property (nonatomic,readonly) int highestPlayable;
@property (nonatomic,readonly) AudioUnit sampler;
@end

@interface Mixer : NSObject {
    // here for categories
    AUGraph          _processingGraph;
    AudioUnit *      _samplerUnits;
    AudioUnit        _ioUnit;
    AudioUnit        _mixerUnit;
    AUNode           _mixerNode;
    
    MIDIClientRef  _midiClient;
    MusicTimeStamp _playerTrackLength;
    MusicSequence  _currentSequence;
    MusicPlayer    _musicPlayer;
}

+(Mixer *)sharedInstance;

-(Sound *)getSound:(NSString *)name;
-(NSArray *)getAllSoundNames;

-(void *)fetchAudioFrame;

@property (nonatomic) AudioUnitParameterValue mixerOutputGain;
@end
