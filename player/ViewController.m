//
//  ViewController.m
//  Player
//
//  Created by Dasha on 4/21/17.
//  Copyright © 2017 Basquare. All rights reserved.
//

#import "ViewController.h"
#import "Player.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *loopSwitch;

@property (strong, nonatomic) Player *player;
@property (nonatomic) BOOL isPlaying;

@property (weak, nonatomic) IBOutlet UILabel *startFromLabel;
@property (weak, nonatomic) IBOutlet UISlider *startFromSlider;
@property (weak, nonatomic) IBOutlet UILabel *finishAtlLabel;
@property (weak, nonatomic) IBOutlet UISlider *finishAtSlider;
@property (weak, nonatomic) IBOutlet UILabel *delayLabel;
@property (weak, nonatomic) IBOutlet UISlider *delaySlider;
@property (weak, nonatomic) IBOutlet UISlider *pitchSlider;
@property (weak, nonatomic) IBOutlet UILabel *pitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempoLebel;
@property (weak, nonatomic) IBOutlet UISlider *tempoSlider;
@property (weak, nonatomic) IBOutlet UISwitch *loopSwitch;

@end

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DemoSong" ofType:@"m4a"];
    self.player = [[Player alloc] init];
    self.player.path = [NSURL fileURLWithPath:path];
    //player details
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"DemoSong" ofType:@"m4a"];
    self.isPlaying = false;
    
    //setupGestures
}


#pragma mark - IBActions
- (IBAction)onStartFromSlider:(UISlider *)sender {
    self.startFromLabel.text = [NSString stringWithFormat:@"%f", sender.value];
}

- (IBAction)onFinishAtSlider:(UISlider *)sender {
    self.finishAtlLabel.text = [NSString stringWithFormat:@"%f", sender.value];
}

- (IBAction)onDelaySlider:(UISlider *)sender {
    self.delayLabel.text = [NSString stringWithFormat:@"%f", sender.value];
}

- (IBAction)onPitchSlider:(UISlider *)sender {
     self.pitchLabel.text = [NSString stringWithFormat:@"%f", sender.value];
}

- (IBAction)onTempoSlider:(UISlider *)sender {
     self.tempoLebel.text = [NSString stringWithFormat:@"%f", sender.value];
}


- (IBAction)onPlay:(id)sender {

    if (!self.isPlaying) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"DemoSong" ofType:@"m4a"];
        self.player = [[Player alloc] init];
        self.player.path = [NSURL fileURLWithPath:path];
        
        self.player.tempo = self.tempoSlider.value / 100.0;
        self.player.startFromTime = self.tempoSlider.value;
        self.player.delayTime = self.delaySlider.value;
        self.player.pitch = self.pitchSlider.value;
        self.player.finishAtTime = self.finishAtSlider.value;
        self.player.isLoop = self.loopSwitch.on;
        
        
        [self.player prepareInputFile];
        [self.player play];
    }
    else {
        [self.player stop];
    }
    _isPlaying = !_isPlaying;
}


@end
