//
//  ViewController.h
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "GameViewController.h"

@interface ViewController : UIViewController<GameResultDelegate> {
  int _highScore;
}

@property (weak, nonatomic) IBOutlet UILabel *highScoreLabel;

@end
