//
//  GameSettings.m
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/02.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import "GameSettings.h"

#define USER_DEFAULTS_KEY_HIGH  @"High"

@implementation GameSettings

static GameSettings* g_gameSettings = nil;

@synthesize highScore = _highScore;

+(GameSettings*) sharedSettings
{
  if (!g_gameSettings) {
    g_gameSettings = [[GameSettings alloc] init];
  }
  return g_gameSettings;
}

-(void) load
{
  _highScore = [[NSUserDefaults standardUserDefaults]
                integerForKey:USER_DEFAULTS_KEY_HIGH];
}

-(void) save
{
  [[NSUserDefaults standardUserDefaults]
   setInteger:_highScore forKey:USER_DEFAULTS_KEY_HIGH];
}
@end
