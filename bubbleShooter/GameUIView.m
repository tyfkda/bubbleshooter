//
//  GameUIView.m
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import "GameUIView.h"
#import "util.h"

@implementation GameUIView

// Initialize.
- (id)initWithCoder:(NSCoder*)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
    _context = NULL;

    [self loadSounds];
    _field = [[Field alloc] init];
    [_field initialize];
    
    [self resumeGame];
  }
  return self;
}

- (void)loadSounds {
  NSBundle *mainBundle = [NSBundle mainBundle];
  NSURL *shootWavURL = [NSURL fileURLWithPath:[mainBundle pathForResource:@"chime" ofType:@"mp3"] isDirectory:NO];
  AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain(shootWavURL), &_shootSoundId);
  NSURL *disappearWavURL = [NSURL fileURLWithPath:[mainBundle pathForResource:@"chime" ofType:@"mp3"] isDirectory:NO];
  AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain(disappearWavURL), &_disappearSoundId);
}

// Finalize.
- (void)dealloc {
  [self pauseGame];
  [self setContext:NULL];
  //[super dealloc];
}

// Sets context.
- (void)setContext:(CGContextRef)context {
  if (_context != NULL) {
    CGContextRelease(_context);
  }
  _context = context;
  CGContextRetain(_context);
}

// Starts timer.
- (void)resumeGame {
  if (_timer == nil) {
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f
                                              target:self
                                            selector:@selector(onTick:)
                                            userInfo:nil
                                             repeats:YES];  // No need to retain.
  }
}

- (void)pauseGame {
  if (_timer != nil) {
    [_timer invalidate];
    _timer = nil;
  }
}

- (void)onTick:(NSTimer*)timer {
  [_field onTick];
  if ([_field isGameOver]) {
    _backButton.hidden = NO;
    _menuButton.hidden = YES;
  }
  
  // Requests redraw.
  [self setNeedsDisplay];
}

// On touch end.
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  CGPoint pos = [[[touches allObjects] objectAtIndex:0] locationInView:self];
  [_field touchesEnded: pos];
}

// Draw.
- (void)drawRect:(CGRect)rect {
  // Get graphics context.
  [self setContext:UIGraphicsGetCurrentContext()];

  [_field render: _context rect:rect];
  [self renderScore];
  [self renderTime];
}

- (int)getScore {
  return [_field getScore];
}

// Renders score.
- (void)renderScore {
  int score = [self getScore];
  _scoreLabel.text = [NSString stringWithFormat : @"%d", score];
}

// Renders time.
- (void)renderTime {
  int time = [_field getTime];
  char c = time % 60 < 30 ? ':' : ' ';
  int sec = (time / 60) % 60;
  int min = time / 3600;
  _timeLabel.text = [NSString stringWithFormat : @"%2d%c%02d", min, c, sec];
}

@end
