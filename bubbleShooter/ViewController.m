//
//  ViewController.m
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  _highScore = 0;
  [self renderHighScore];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)returnToTitleGameOver:(UIStoryboardSegue *)segue
{
}

- (void)renderHighScore {
  _highScoreLabel.text = [NSString stringWithFormat : @"%d", _highScore];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"play"]) {
    GameViewController* gvc = segue.destinationViewController;
    gvc.delegate = self;
  }
}

- (void)notifyScore:(int)score {
  if (score > _highScore) {
    _highScore = score;
    [self renderHighScore];
  }
}
@end
