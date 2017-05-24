//
//  PDBDetailsVC.m
//  Player
//
//  Created by админ on 5/25/17.
//  Copyright © 2017 Basquare. All rights reserved.
//

#import "PDBDetailsVC.h"
#import "PDBScaleView.h"

@interface PDBDetailsVC ()

@property (weak, nonatomic) IBOutlet PDBScaleView *waveScaleView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waveScaleViewWidth;
@property (weak, nonatomic) IBOutlet UIImageView *waveImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waveImageViewWidth;
@property (weak, nonatomic) IBOutlet PDBScaleView *oldWaveBigScaleView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oldScaleViewWidth;
@property (weak, nonatomic) IBOutlet UIImageView *oldIWaveImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oldWaveViewWidth;

@end

@implementation PDBDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    self.oldWaveViewWidth.constant = self.oldWaveImage.size.width;
    self.oldIWaveImageView.image = self.oldWaveImage;
    [self updateScaleView:self.oldWaveBigScaleView constraint:self.oldScaleViewWidth width:self.oldWaveImage.size.width];

    self.waveImageViewWidth.constant = self.waveImage.size.width;
    self.waveImageView.image = self.waveImage;
    [self updateScaleView:self.waveScaleView constraint:self.waveScaleViewWidth width:self.waveImage.size.width];
    [self.view layoutSubviews];
}

- (void)updateScaleView: (PDBScaleView *)scaleView constraint:(NSLayoutConstraint *)constraint width:(CGFloat)width {
    constraint.constant = width > [UIScreen mainScreen].bounds.size.width ? width : [UIScreen mainScreen].bounds.size.width;
    [self.view layoutIfNeeded];
    [scaleView reloadData];
};
@end
