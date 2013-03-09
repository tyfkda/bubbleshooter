//
//  FieldTest.m
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/07.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import "FieldTest.h"

@implementation FieldTest

- (void)setUp
{
  [super setUp];
  
  _field = [[Field alloc] init];
  [_field initialize];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testPositionCheck
{
  const int O = 1;
  const int _ = 0;
  const int pattern[FIELDW * FIELDH] = {
    O,O,O,O,O,O,O,O,O,O,
     O,O,O,O,O,O,O,O,O,  _,
    O,O,O,O,O,O,O,O,O,O,
     O,O,O,O,O,O,O,O,O,  _,
    O,O,O,O,O,O,O,O,O,O,
     O,O,O,O,O,O,O,O,O,  _,
    O,O,O,O,O,O,O,O,O,O,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
  };

  for (int ix = -2 * R; ix <= W * FIELDW + 2 * R; ++ix) {
    [_field setField:pattern];
    Bubble bubble;
  
    CGPoint pos;
    pos.x = (float)ix;
    pos.y = H * 7 + R;
    STAssertTrue([_field shotBubble:&bubble pos:pos x:BUBBLE_X y:BUBBLE_Y c:O], nil);
    // Confirm that moving bubble does not rise exception.
    while ([_field moveBubble: &bubble]) {
      // loop.
    }
  }
}

@end
