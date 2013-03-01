//
//  Field.h
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/01.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "util.h"

@interface Field : NSObject {
  int _field[FIELDW * FIELDH];
  NSMutableArray* _effects;
  
  //SystemSoundID _shootSoundId;
  //SystemSoundID _disappearSoundId;

  int _state;    // Bubble state.
  int _scrolly;  // Scroll position, 1024 = 1 dot.
  int _scrollSpeed;
  float _x, _y;  // Bubble position.
  int _c;        // Bubble type.
  float _vx, _vy;  // Bubble velocity.
  int _nextc;      // Next bubble type.
  int _score;    // Score.
  int _time;     // Time.
}

- (void)initialize;
- (void)onTick;
- (void)render:(CGContextRef) context rect:(CGRect)rect;

- (void)touchesEnded:(CGPoint)pos;

- (int)getScore;
- (int)getTime;

@end
