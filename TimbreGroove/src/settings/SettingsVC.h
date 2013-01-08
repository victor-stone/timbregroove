//
//  SettingsVC.h
//  TimbreGroove
//
//  Created by victor on 1/2/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+TGViewExtensions.h"

@class Sound;
@class TrackView;

// for SettingsDescriptor.priority
#define SHADER_SETTINGS    0
#define TEXTURE_SETTINGS 100
#define MESH_SETTINGS    150
#define AUDIO_SETTINGS   200
#define GLOBAL_SETTINGS  500

typedef enum SettingControl
{
    SC_Slider,
    SC_Switch,
    SC_Text,
    SC_Picture,
    SC_Picker
} SettingControl;


@interface SettingsDescriptor : NSObject

-(id)initWithControlType:(SettingControl)cType
              memberName:(NSString *)memberName
               labelText:(NSString *)text
                  options:(NSDictionary *)values
                selected:(id)selected
                delegate:(id)delegate
                priority:(int)priority;

@property (nonatomic) SettingControl controlType;
@property (nonatomic,strong) NSString * memberName; // used for obj-c member name, layoutID, etc.
@property (nonatomic,strong) NSString * labelText;
@property (nonatomic,strong) NSDictionary * options;
@property (nonatomic,strong) id initialValue; // aka selected
@property (nonatomic,strong) id delegate; // used for pickViewDelegates, on clicks, valueChanged, etc.
@property (nonatomic,strong) id result;
@property (nonatomic) int priority;

@end

@interface SettingsVC : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>


@property (nonatomic,strong) NSArray * settings;

-(IBAction)backToHome:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *componentTitleLabel;

@end
