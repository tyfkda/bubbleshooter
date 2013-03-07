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

- (void)testExample
{
  //STFail(@"Unit tests are not implemented yet in bubbleShooterTest");
}

@end
