//
//  ViewController.m
//  Player
//
//  Created by Dasha on 4/21/17.
//  Copyright © 2017 Basquare. All rights reserved.
//

#import "ViewController.h"
#import "Player.h"
#import "BAWaveFormViewMaker.h"

@interface ViewController ()


@property (strong, nonatomic) Player *player;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic, strong) NSString *path;

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
@property (weak, nonatomic) IBOutlet UIImageView *waveFormImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waveFormImageWidthConstraint;

@end

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.path = [[NSBundle mainBundle] pathForResource:@"DemoSong" ofType:@"m4a"];
    self.player = [[Player alloc] init];
    self.player.path = [NSURL fileURLWithPath:_path];
    //player details
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"DemoSong" ofType:@"m4a"];
    self.isPlaying = false;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveWaveFormImage:) name:@"BAWaveFormImageNotification" object:nil];
    [self startImplementImag];
    
    //setupGestures
}


#pragma mark - IBActions
- (IBAction)onStartFromSlider:(UISlider *)sender {
    self.startFromLabel.text = [NSString stringWithFormat:@"%.01f", sender.value];
}

- (IBAction)onFinishAtSlider:(UISlider *)sender {
    self.finishAtlLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (IBAction)onDelaySlider:(UISlider *)sender {
    self.delayLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (IBAction)onPitchSlider:(UISlider *)sender {
     self.pitchLabel.text = [NSString stringWithFormat:@"%.0f", sender.value];
}

- (IBAction)onTempoSlider:(UISlider *)sender {
     self.tempoLebel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}


- (IBAction)onPlay:(id)sender {

    if (!self.isPlaying) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"DemoSong" ofType:@"m4a"];
        self.player = [[Player alloc] init];
        self.player.path = [NSURL fileURLWithPath:path];
        
        self.player.tempo = self.tempoSlider.value / 100.0;
        self.player.startFromTime = self.startFromSlider.value * 1000.0;
        self.player.delayTime = self.delaySlider.value * 1000.0;
        self.player.pitch = self.pitchSlider.value;
        self.player.finishAtTime = self.finishAtSlider.value * 1000.0;
        self.player.isLoop = self.loopSwitch.on;
        
        [self.player prepareInputFile];
        [self.player play];
    }
    else {
        [self.player stop];
    }
    _isPlaying = !_isPlaying;
}

- (void) startImplementImag {
    [[BAWaveFormViewMaker sharedWaveFormMaker] makeWaveformImageForPath:self.path];
}

- (void)recieveWaveFormImage:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *waveFormImage = (UIImage *)notification.userInfo[@"waveFormImage"];
        NSData *imageData = UIImagePNGRepresentation(waveFormImage);
        NSString *path = notification.userInfo[@"path"];
        [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:path];
        self.waveFormImageWidthConstraint.constant = waveFormImage.size.width;
        [self.view layoutSubviews];
        self.waveFormImageView.image = waveFormImage;
    });
}


@end
