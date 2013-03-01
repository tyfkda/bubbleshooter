//
//  GameViewController.h
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/01.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GameResultDelegate<NSObject>
- (void)notifyScore:(int)score;
@end

@interface GameViewController : UIViewController

@property (nonatomic) id<GameResultDelegate> delegate;

- (IBAction)onMenuButtonPushed:(id)sender;
- (IBAction)onGameOverButtonPushed:(id)sender;

@end
