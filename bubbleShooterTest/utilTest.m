//
//  utilTest.m
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/07.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import "utilTest.h"
#import "util.h"

@implementation utilTest

static NSComparisonResult cmp(id obj1, id obj2, void* _) {
  NSNumber* num1 = obj1;
  NSNumber* num2 = obj2;
  return [num1 compare: num2];
}

- (void) checkIntMutableArray: array expected:(const int*)expected {
  [array sortUsingFunction: cmp context: nil];
  for (int i = 0; i < [array count]; ++i) {
    STAssertEquals(expected[i], [[array objectAtIndex: i] intValue], nil);
  }
}

- (void)testFieldIndex {
  STAssertEquals(0, fieldIndex(0, 0), nil);
  STAssertEquals(3 * FIELDW + 2, fieldIndex(2, 3), nil);
}

- (void)testValidPosition {
  STAssertTrue(validPosition(0, 0), nil);
  STAssertTrue(validPosition(FIELDW - 1, 0), nil);
  STAssertFalse(validPosition(-1, 0), nil);
  STAssertFalse(validPosition(FIELDW, 0), nil);

  STAssertTrue(validPosition(0, 1), nil);
  STAssertTrue(validPosition(FIELDW - 2, 1), nil);
  STAssertFalse(validPosition(-1, 1), nil);
  STAssertFalse(validPosition(FIELDW - 1, 1), nil);
  STAssertFalse(validPosition(FIELDW, 1), nil);

  STAssertFalse(validPosition(0, -1), nil);
  STAssertFalse(validPosition(0, FIELDH), nil);
  STAssertTrue(validPosition(0, FIELDH - 1), nil);
}

- (void)testHitFieldBubble {
  const int X = 7;
  const int O = 1;
  const int _ = 0;
  const int field[] = {
    X,X,X,X,X,X,X,X,X,X,
     X,X,X,X,X,X,X,X,X,  _,
    X,X,X,X,X,X,X,X,X,X,
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
  int px, py;
  int bubbleX = W * 5 + R + 1, bubbleY = H * 6 + 2 * R - 1;
  STAssertTrue(hitFieldBubble(field, 5, 6, bubbleX, bubbleY, R + R, &px, &py), nil);
  STAssertEquals(5, px, nil);
  STAssertEquals(7, py, nil);
  STAssertFalse(hitFieldBubble(field, 5, 0, bubbleX, bubbleY, R + R, &px, &py), nil);
}

- (void)testCountBubbles {
  const int X = 7;
  const int O = 1;
  const int B = 2;
  const int _ = 0;
  const int field[] = {
    X,X,X,X,X,X,X,X,X,X,
     X,X,X,X,X,X,X,X,X,  _,
    X,X,X,X,X,X,X,X,X,X,
     B,B,O,B,B,B,O,B,B,  _,
    B,B,B,O,O,B,O,B,B,B,
     O,B,O,B,B,B,B,B,B,  _,
    B,B,O,B,O,B,B,B,O,B,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
  };
  NSMutableArray* bubbles = countBubbles(field, 2, 6, O, 2);
  STAssertTrue(bubbles != nil, nil);
  STAssertEquals(5, (int)[bubbles count], nil);

  const int expected[] = {
    fieldIndex(2, 3),
    fieldIndex(3, 4),
    fieldIndex(4, 4),
    fieldIndex(2, 5),
    fieldIndex(2, 6),
  };
  [self checkIntMutableArray: bubbles expected:expected];
}

- (void)testAddAdjacentPositions {
  NSMutableArray* seeds = [[NSMutableArray alloc] init];
  addAdjacentPositions(seeds, 0, 1);
  STAssertTrue(seeds != nil, nil);
  STAssertEquals(5, (int)[seeds count], nil);
  
  const int expected[] = {
    fieldIndex(0, 0),
    fieldIndex(1, 0),
    fieldIndex(1, 1),
    fieldIndex(0, 2),
    fieldIndex(1, 2),
  };
  [self checkIntMutableArray: seeds expected:expected];
}

- (void)testFallCheck {
  const int O = 1;
  const int _ = 0;
  const int field[] = {
    O,O,O,O,O,O,O,O,O,O,
     O,O,O,O,O,O,O,O,O,  _,
    O,O,O,O,O,O,O,O,O,O,
     _,O,O,O,O,O,O,O,O,  _,
    O,_,O,O,O,O,O,O,O,O,
     O,_,O,O,O,O,O,O,O,  _,
    O,O,_,O,O,O,O,O,O,O,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
     _,_,_,_,_,_,_,_,_,  _,
    _,_,_,_,_,_,_,_,_,_,
  };
  NSMutableArray* erasedBubbles = [[NSMutableArray alloc] init];
  [erasedBubbles addObject:[NSNumber numberWithInt:fieldIndex(0, 3)]];
  [erasedBubbles addObject:[NSNumber numberWithInt:fieldIndex(1, 4)]];
  [erasedBubbles addObject:[NSNumber numberWithInt:fieldIndex(1, 5)]];
  [erasedBubbles addObject:[NSNumber numberWithInt:fieldIndex(2, 6)]];
  
  NSMutableArray* cutoffBubbles = [[NSMutableArray alloc] init];
  fallCheck(field, erasedBubbles, cutoffBubbles);
  STAssertEquals(4, (int)[cutoffBubbles count], nil);
  
  const int expected[] = {
    fieldIndex(0, 4),
    fieldIndex(0, 5),
    fieldIndex(0, 6),
    fieldIndex(1, 6),
  };
  [self checkIntMutableArray: cutoffBubbles expected:expected];
}

@end
