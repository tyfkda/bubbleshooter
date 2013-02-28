//
//  Effect.h
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Effect : NSObject
-(bool) update;
-(void) render: (CGContextRef)context;
@end

@interface DisappearEffect : Effect {
  float _x, _y;
  int _c;
  int _r;
}
-(void) initialize: (int)x y:(int)y c:(int)c r:(int)r;
-(bool) update;
-(void) render: (CGContextRef)context;
@end

@interface FallEffect : Effect {
  float _x, _y;
  float _vx, _vy;
  int _c;
}
-(void) initialize: (int)x y:(int)y c:(int)c;
-(bool) update;
-(void) render: (CGContextRef)context;
@end
