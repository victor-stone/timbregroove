//
//  Audio.h
//  TimbreGroove
//
//  Created by victor on 2/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

@class ConfigAudioProfile;
@class Scene;
@class SoundSystem;
@class SoundSystemParameters;

@interface Audio : NSObject {
    @protected
    NSArray * _instruments;
}
+(id)audioFromConfig:(ConfigAudioProfile *)config withScene:(Scene *)scene;
-(void)loadAudioFromConfig:(ConfigAudioProfile *)config;
-(void)getParameters:(NSMutableDictionary *)putHere;
-(void)getSettings:(NSMutableArray *)putHere;
-(void)update:(NSTimeInterval)dt;
-(void)triggersChanged:(Scene *)scene;
-(void)getTriggerMap:(NSMutableArray *)putHere;

-(void)start;
-(void)activate;
-(void)pause;

-(void)startMidiFile;

@property (nonatomic,weak)  SoundSystem * soundSystem;
@property (nonatomic,strong) SoundSystemParameters * ssp;


@end
