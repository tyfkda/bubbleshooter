//
//  ViewController.m
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import "ViewController.h"
#import "GameSettings.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

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
  int highScore = [GameSettings sharedSettings].highScore;
  _highScoreLabel.text = [NSString stringWithFormat : @"%d", highScore];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"play"]) {
    GameViewController* gvc = segue.destinationViewController;
    gvc.delegate = self;
  }
}

- (void)notifyScore:(int)score {
  if (score > [GameSettings sharedSettings].highScore) {
    [GameSettings sharedSettings].highScore = score;
    [self renderHighScore];
  }
}
@end
