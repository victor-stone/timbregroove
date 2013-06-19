//
//  Instrument.h
//  TimbreGroove
//
//  Created by victor on 2/28/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SoundSource.h"

@class ConfigInstrument;

@interface Sampler : NSObject <SoundSource>

+(id)samplerWithAUGraph:(AUGraph)graph;

-(void)loadSound:(ConfigInstrument *)config midi:(Midi *)midi;

-(void)instantiateAU;

@property (nonatomic,readonly) int lowestPlayable;
@property (nonatomic,readonly) int highestPlayable;
@property (nonatomic,readonly) AudioUnit sampler;
@property (nonatomic,readonly) AUNode    graphNode;
@property (nonatomic) bool configured;
@property (nonatomic) MIDIPortRef     outPort;
@property (nonatomic) MIDIEndpointRef endPoint;
@property (nonatomic) int channel;
@end

