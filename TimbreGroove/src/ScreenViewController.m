//
//  TGUIViewController.m
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Global.h"
#import "Config.h"
#import "Scene.h"
#import "Names.h"

#import "TGTypes.h"
#import "Graph.h"
#import "GraphView.h"
#import "GraphView+Touches.h"
#import "Audio.h"

#import "NewScenePicker.h"
#import "SettingsVC.h"
#import "PauseViewController.h"
#import "NewSceneViewController.h"

#import "SoundSystem+Diag.h"

@interface ScreenViewController : UIViewController < NewSceneDelegate,
                                                        SettingVCDelegate,
                                                        PauseViewDelegate>
{
    NSMutableArray * _scenes;
    
    int _postDeleteSceneIndex;
    
    GLKViewController * _graphVC;
    Global * _global;

    Scene * _eqScene;
    int _lastEQBand;
    
    FloatParamBlock _mainSliderTrigger;
    
    NSString * _recordObserver;
    
}

@property (nonatomic,strong) Scene * currentScene;

@property (weak, nonatomic) IBOutlet UIView *graphContainer;
@property (weak, nonatomic) IBOutlet UIView *audioToolbar;
@property (weak, nonatomic) IBOutlet UIToolbar *utilityToolBar;
@property (weak, nonatomic) IBOutlet UIPageControl *pager;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashCan;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *recordButton;
@property (weak, nonatomic) IBOutlet UIView *menuAreaView;
- (IBAction)closeAudioMenu:(UIBarButtonItem *)sender;
- (IBAction)changePage:(id)sender;
- (IBAction)toolbarSlider:(UISlider *)sender;
- (IBAction)audioPanel:(UIButton *)sender;
- (IBAction)trash:(UIBarButtonItem *)sender;
- (IBAction)record:(UIBarButtonItem *)sender;
- (IBAction)showMenu:(UITapGestureRecognizer *)sender;
@end

@implementation ScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _postDeleteSceneIndex = -1;
    // force some global instializations
    [Config sharedInstance];
    
    _global = [Global sharedInstance];

    _scenes = [NSMutableArray new];
    
    BKSenderBlock recordChanger = ^(id sender) {
        if( _global.recording )
        {
            _recordButton.tintColor = [UIColor redColor];
        }
        else
        {
            _recordButton.tintColor = [UIColor purpleColor];
        }
    };
    
    _recordObserver = [_global addObserverForKeyPath:(NSString *)kGlobalRecording
                                                task:recordChanger];
    
}

-(void)setCurrentScene:(Scene *)currentScene
{
    if( _currentScene )
        [_currentScene pause];
    
    _currentScene = currentScene;
    
    if( currentScene )
       [currentScene activate];
    
    [self performSelector:@selector(performTransition:)
               withObject:currentScene
               afterDelay:0.12];
    
    _mainSliderTrigger = [currentScene.triggers getFloatTrigger:kTriggerMainSlider];
}

-(void)viewDidLayoutSubviews
{
    if( !_currentScene )
    {
        for( UIViewController * vc in self.childViewControllers )
        {
            if( [vc.title isEqualToString:@"graphVC"] )
            {
                _graphVC = (GLKViewController*)vc;
                _graphVC.view.frame = _graphContainer.bounds;
                _global.graphViewSize = _graphVC.view.frame.size;
                [self createAScene:[Config defaultScene]];
                break;
            }
        }
    }
}

- (void)createAScene:(ConfigScene *)config
{
    Scene * scene = [Scene sceneWithConfig:config];
    [_scenes addObject:scene];
    self.currentScene = scene;
    _pager.numberOfPages = [_scenes count];
}

- (void)deleteScene
{
    Scene * scene = _scenes[_postDeleteSceneIndex];
    [_scenes removeObject:scene];
    [scene decomission];
    scene = nil;
    
    _pager.numberOfPages = [_scenes count];
    _pager.currentPage = 0;
    _postDeleteSceneIndex = -1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)toggleMenus
{
    CGRect bottomRC = _utilityToolBar.frame;
    CGRect topRC    = _audioToolbar.frame;
    
    bool menusShowing = topRC.origin.y == 0;

    float speed = 0.75;
    
    if( menusShowing )
    {
        bottomRC.origin.y = self.view.frame.size.height;
        topRC.origin.y = -topRC.size.height;
        speed = 0.5;
    }
    else
    {
        _trashCan.enabled = _scenes.count > 1;
        bottomRC.origin.y -= bottomRC.size.height;
        topRC.origin.y = 0;
    }
    [UIView animateWithDuration:speed
                     animations:^{
                         _utilityToolBar.frame = bottomRC;
                         _audioToolbar.frame = topRC;
                     }
                     completion:^(BOOL finished){
                     }];
}


- (void)performTransition:(Scene *)scene
{
    CGRect org = _graphContainer.frame;
    CGRect offscreen = org;
    offscreen.origin.x = org.size.width;
    
    float speed = 0.4;
    
    [UIView animateWithDuration:speed
                     animations:^{
                         _graphContainer.frame = offscreen;
                     }
                     completion:^(BOOL finished){
                         _graphVC.paused = YES;
                         GraphView * gview = (GraphView *)_graphVC.view;
                         gview.scene = scene;
                         _graphVC.paused = NO;
                         _pager.currentPage = [_scenes indexOfObject:_currentScene];
                         
                         [UIView animateWithDuration:speed
                                          animations:^{
                                              _graphContainer.frame = org;
                                          }
                                          completion:^(BOOL finished){
                                              if( _postDeleteSceneIndex != -1 )
                                              {
                                                  [self deleteScene];
                                                  [self performSelector:@selector(toggleMenus)
                                                             withObject:nil
                                                             afterDelay:0.1];
                                              }
                                          }];
                     }];
}

- (void)performUtilityTransitionWithScene:(Scene *)scene
{
    CGRect org = _graphContainer.frame;
    CGRect offscreen = org;
    offscreen.origin.y = org.size.height;
    
    float speed = 0.4;
    
    [UIView animateWithDuration:speed
                     animations:^{
                         _graphContainer.frame = offscreen;
                     }
                     completion:^(BOOL finished){
                         GraphView * gview = (GraphView *)_graphVC.view;
                         gview.scene = scene;
                         [UIView animateWithDuration:speed
                                          animations:^{
                                              _graphContainer.frame = org;
                                          }
                                          completion:^(BOOL finished){
                                          }];
                         
                     }];
    
}

- (IBAction)closeAudioMenu:(UIBarButtonItem *)sender {
    [self toggleMenus];
}

- (IBAction)changePage:(id)sender
{
    self.currentScene = _scenes[_pager.currentPage];
}

- (IBAction)toolbarSlider:(UISlider *)sender
{
    if( _mainSliderTrigger )
        _mainSliderTrigger(sender.value);
}

- (IBAction)audioPanel:(UIButton *)sender
{
    if( _eqScene )
    {
        [self performUtilityTransitionWithScene:_currentScene];
        [_eqScene decomission];
        [_currentScene.audio triggersChanged:_currentScene];
        _eqScene = nil;
    }
    else
    {
        _eqScene = [[Scene alloc] initWithConfig:[Config systemScene:kConfigEQPanelScene]
                                   andProxyAudio:nil]; // _currentScene.audio];
        [_eqScene activate];
        [self performUtilityTransitionWithScene:_eqScene];
    }
}

- (IBAction)trash:(UIBarButtonItem *)sender
{
    _postDeleteSceneIndex = _pager.currentPage;
    int i = _postDeleteSceneIndex ? 0 : 1;
    self.currentScene = _scenes[i];
}

- (IBAction)record:(UIBarButtonItem *)sender {
    Global * g = _global;
    g.recording = !g.recording;
}

- (IBAction)showMenu:(UITapGestureRecognizer *)sender
{
    [self toggleMenus];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [segue.identifier isEqualToString:@"newTrack"] )
    {
        ((NewSceneViewController *)segue.destinationViewController).delegate = self;
    }
    else if( [segue.identifier isEqualToString:@"settings"] )
    {
        ((SettingsVC *)segue.destinationViewController).delegate = self;
    }
    else if( [segue.identifier isEqualToString:@"pause"] )
    {
        [_currentScene pause];
        _graphVC.paused = YES;
        ((PauseViewController *)segue.destinationViewController).delegate = self;
    }
    else
    {
        NSLog(@"Doing seque called; %@", segue.identifier);
    }
}

-(void)SettingsVC:(SettingsVC *)vc getSettings:(NSMutableArray *)array
{
    [_currentScene getSettings:array];
}

-(void)SettingsVC:(SettingsVC *)vc commitChanges:(NSDictionary *)settings
{
    [((GraphView *)_graphVC.view) performSelector:@selector(commitSettings)
                                       withObject:nil
                                       afterDelay:0.3];
}

-(void)NewScene:(NewSceneViewController *)vc selection:(ConfigScene *)sceneConfig
{
    [vc.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self performSelector:@selector(createAScene:) withObject:sceneConfig afterDelay:0.25];
    }];
    
}

-(void)PauseViewController:(PauseViewController *)pvc resume:(BOOL)ok
{
    [_currentScene activate];
    _graphVC.paused = NO;
}
@end
