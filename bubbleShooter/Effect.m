//
//  Effect.m
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import "Effect.h"
#import "util.h"

@implementation Effect

-(void) initialize:(int)x y:(int)y c:(int)c {
  _x = x;
  _y = y;
  _c = c;
  _vx = randf(-4, 4);
  _vy = randf(-4, 0);
}

-(bool) update {
  _vy += 0.25;
  _x += _vx;
  _y += _vy;
  if (_y >= HEIGHT + R)
    return false;
  return true;
}

-(void) render: (CGContextRef)context {
  drawBubble(context, _x, _y, _c);
}

@end


