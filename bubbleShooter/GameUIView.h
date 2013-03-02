//
//  GameUIView.h
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import "Field.h"
#import "util.h"

@interface GameUIView : UIView {
  CGContextRef _context;
  NSTimer* _timer;

  SystemSoundID _shootSoundId;
  SystemSoundID _disappearSoundId;

  Field* _field;
  UIImage* _bg;

  /*
  int _field[FIELDW * FIELDH];
  NSMutableArray* _effects;
  
  int _state;    // Bubble state.
  int _scrolly;  // Scroll position, 1024 = 1 dot.
  int _scrollSpeed;
  float _x, _y;  // Bubble position.
  int _c;        // Bubble type.
  float _vx, _vy;  // Bubble velocity.
  int _nextc;      // Next bubble type.
  int _score;    // Score.
  int _time;     // Time.
   */
}

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

- (void)pauseGame;
- (void)resumeGame;
- (int)getScore;

@end
