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
-(bool) update {
  return false;
}

-(void) render: (CGContextRef)context {
}
@end

@implementation DisappearEffect
-(void) initialize:(int)x y:(int)y c:(int)c r:(int)r {
  _x = x;
  _y = y;
  _c = c;
  _r = r;
}

-(bool) update {
  _r -= 2;
  if (_r <= 0)
    return false;
  return true;
}

-(void) render: (CGContextRef)context {
  int r = kBubbleColors[_c][0];
  int g = kBubbleColors[_c][1];
  int b = kBubbleColors[_c][2];
  setColor(context, r, g, b);
  fillCircle(context, _x, _y, _r);
}
@end

@implementation FallEffect
-(void) initialize: (int)x y:(int)y c:(int)c vx:(float)vx vy:(float)vy {
  _x = x;
  _y = y;
  _c = c;
  _vx = vx;
  _vy = vy;
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
