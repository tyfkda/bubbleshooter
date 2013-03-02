//
//  GameSettings.h
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/02.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameSettings : NSObject {
@private
  int _highScore;
}

+(GameSettings*) sharedSettings;

@property (nonatomic) int highScore;

-(void) save;
-(void) load;

@end