//
//  GameViewController.m
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/01.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import "GameViewController.h"
#import "GameUIView.h"

@interface GameViewController ()

@end

@implementation GameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onMenuButtonPushed:(id)sender {
  GameUIView* view = (GameUIView*)self.view;
  [view pauseGame];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Menu"
                                                  message:nil
                                                 delegate:self
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"Back to title", @"Resume", nil];
  [alert show];
}

- (void)exitGame {
  GameUIView* view = (GameUIView*)self.view;
  if ([_delegate respondsToSelector:@selector(notifyScore:)]){
    [_delegate notifyScore:[view getScore]];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onGameOverButtonPushed:(id)sender {
  [self exitGame];
}

// Called when alert dialog button is pushed.
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      [self exitGame];
      break;
    case 1:
    {
      GameUIView* view = (GameUIView*)self.view;
      [view resumeGame];
    } break;
  }
}
@end
