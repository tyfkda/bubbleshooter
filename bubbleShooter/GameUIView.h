//
//  GameUIView.h
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "util.h"

@interface GameUIView : UIView {
  CGContextRef _context;
  NSTimer* _timer;
  int _field[FIELDW * FIELDH];
  NSMutableArray* _effects;

  int _state;    // Bubble state.
  float _x, _y;  // Bubble position.
  int _c;        // Bubble type.
  float _vx, _vy;  // Bubble velocity.
}

@end
