//
//  Field.h
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/01.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "util.h"

static const int MAX_SHOT = 2;
static const float BUBBLE_VELOCITY = 24;
static const float BUBBLE_X = WIDTH / 2;
static const float BUBBLE_Y = H * (FIELDH - 1) + R - 2 * H;

typedef struct {
  bool active;
  float x, y;    // Position.
  int c;          // Type.
  float vx, vy;  // Velocity.
} Bubble;

@interface Field : NSObject {
  int _field[FIELDW * FIELDH];
  NSMutableArray* _effects;
  
  //SystemSoundID _shootSoundId;
  //SystemSoundID _disappearSoundId;

  int _state;    // State.
  int _scrolly;  // Scroll position, 1024 = 1 dot.
  int _scrollSpeed;
  int _score;    // Score.
  int _time;     // Time.

  Bubble _bubbles[MAX_SHOT];
  int _nextc[2];      // Next bubble type.
}

- (void)initialize;
- (void)onTick;
- (void)render:(CGContextRef) context rect:(CGRect)rect;

- (void)touchesEnded:(CGPoint)pos;

- (int)getScore;
- (int)getTime;
- (bool)isGameOver;

// For test.
- (void)setField:(const int*)field;
- (bool)shotBubble:(Bubble*)bubble pos:(CGPoint)pos x:(float)x y:(float)y c:(int)c;
- (bool)moveBubble: (Bubble*) bubble;

@end
