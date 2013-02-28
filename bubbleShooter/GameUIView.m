//
//  GameUIView.m
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import "GameUIView.h"
#import "Effect.h"
#import "util.h"

@implementation GameUIView

// Player state.
enum {
  kIdleState = 0,
  kShootState = 1,
};

const float BUBBLE_VELOCITY = 8;

// Initialize.
- (id)initWithCoder:(NSCoder*)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
    _context = NULL;

    [self initialize];
  }
  return self;
}

// Finalize.
- (void)dealloc {
  [self setContext:NULL];
  //[super dealloc];
}

// Initialize.
- (void)initialize {
  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f
                                            target:self
                                          selector:@selector(onTick:)
                                          userInfo:nil
                                           repeats:YES];  // No need to retain.

  // Initializes field.
  for (int i = 0; i < FIELDW * FIELDH; _field[i++] = 0);
  for (int i = 0; i < FIELDH / 2; ++i) {
    for (int j = 0; j < FIELDW; ++j) {
      _field[fieldIndex(j, i)] = randi(1, kColorBubbles + 1);
    }
  }

  // Initializes bubble.
  _nextc = [self chooseNextBubble];
  [self initializeBubble];
  
  _effects = [[NSMutableArray alloc] init];
}

- (int)chooseNextBubble {
  return randi(1, kColorBubbles + 1);
}

- (void)initializeBubble {
  _state = kIdleState;
  _x = WIDTH / 2;
  _y = H * (FIELDH - 1) + W / 2;
  _c = _nextc;
  _vx = _vy = 0;
  _nextc = [self chooseNextBubble];
}

// Sets context.
- (void)setContext:(CGContextRef)context {
  if (_context != NULL) {
    CGContextRelease(_context);
  }
  _context = context;
  CGContextRetain(_context);
}

// On touch end.
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  CGPoint pos = [[[touches allObjects] objectAtIndex:0] locationInView:self];
  switch (_state) {
    default:
      break;
    case kIdleState:
    {
      float dx = pos.x - _x;
      float dy = pos.y - _y;
      if (dx != 0 || dy < 0) {
        float l = sqrt(dx * dx + dy * dy);
        _vx = dx * BUBBLE_VELOCITY / l;
        _vy = dy * BUBBLE_VELOCITY / l;
        _state = kShootState;
      }
    } break;
  }
}

// On tick event.
- (void)onTick:(NSTimer*)timer {
  switch (_state) {
    default:
      break;
    case kIdleState:
      break;
    case kShootState:
      _x += _vx;
      _y += _vy;
      if (_x < W / 2 || _x > WIDTH - W / 2)
        _vx = -_vx;
      if (_y < W / 2)
        _vy = -_vy;
      if (_y > HEIGHT + W / 2) {
        [self initializeBubble];
        break;
      }
      
      [self hitCheck];
      break;
  }

  [self updateEffects];

  // Requests redraw.
  [self setNeedsDisplay];
}

// Check bubble hits other bubble.
- (bool)hitCheck {
  int tx, ty;
  for (int by = ((int)_y - R - 2 * R) / H; by <= ((int)_y + R - 2 * R) / H; ++by) {
    for (int bx = ((int)_x - R - (by & 1) * R) / W; bx <= ((int)_x + R - (by & 1) * R) / W; ++bx) {
      if (hitFieldBubble(_field, bx, by, _x, _y, R, &tx, &ty))
        goto find;
    }
  }
  return false;
  
find:
  if (!validPosition(tx, ty) || _field[fieldIndex(tx, ty)] != 0) {
    NSLog(@"Invalid hit position: (%d,%d)", tx, ty);
    [self initializeBubble];
    return true;
  }

  _field[fieldIndex(tx, ty)] = _c;
  NSMutableArray* bubbles = countBubbles(_field, tx, ty, _c);
  if ([bubbles count] >= 3) {
    [self eraseBubbles:bubbles];
    [self fallCheck:bubbles];
  }
  [self initializeBubble];
  return true;
}

// Erase bubbles.
- (void)eraseBubbles:(NSMutableArray*)bubbles {
  for (int i = 0; i < [bubbles count]; ++i) {
    int position = [[bubbles objectAtIndex:i] intValue];
    _field[position] = 0;
  }
}

// Checks bubbles fall.
- (void)fallCheck:(NSMutableArray*)erasedBubbles {
  int cutoff_count = 0;
  for (int i = 0; i < [erasedBubbles count]; ++i) {
    int position = [[erasedBubbles objectAtIndex:i] intValue];
    int x = position % FIELDW;
    int y = position / FIELDW;
    NSMutableArray* seeds = [[NSMutableArray alloc] initWithCapacity:6];
    addAdjacentPositions(seeds, x, y);
    for (int j = 0; j < [seeds count]; ++j) {
      cutoff_count += [self fallCheckSub:[[seeds objectAtIndex:j] intValue]];
    }
  }
  if (cutoff_count > 0) {
    NSLog(@"Cutoff! %d", cutoff_count);
  }
}

// Checks bubbles fall.
- (int)fallCheckSub:(int)seed {
  bool checked[FIELDW * FIELDH];
  for (int i = 0; i < FIELDW * FIELDH; checked[i++] = false);
  
  NSMutableArray* seeds = [[NSMutableArray alloc] initWithCapacity:1];
  [seeds addObject:[NSNumber numberWithInt:seed]];
 
  for (int i = 0; i < [seeds count]; ++i) {
    int position = [[seeds objectAtIndex:i] intValue];
    int x = position % FIELDW;
    int y = position / FIELDW;
    if (!validPosition(x, y) || _field[position] == 0 || checked[position]) {
      continue;
    }
    checked[position] = true;
    if (y == 0) {
      // Not fall these bubbles because sticked with ceil.
      return 0;
    }
    addAdjacentPositions(seeds, x, y);
  }

  // Not sticked with ceil. Fall all bubbles.
  int cutoff_count = 0;
  for (int i = 0; i < [seeds count]; ++i) {
    int position = [[seeds objectAtIndex:i] intValue];
    int x = position % FIELDW;
    int y = position / FIELDW;
    if (!validPosition(x, y) || _field[position] == 0)
      continue;

    int xx = x * W + (y & 1) * W / 2 + W / 2;
    int yy = y * H + W / 2;
    Effect* effect = [[Effect alloc] init];
    [effect initialize: xx y:yy c:_field[position]];
    [_effects addObject:effect];
    
    checked[position] = false;
    _field[position] = 0;
    ++cutoff_count;
  }
  return cutoff_count;
}

// Draw.
- (void)drawRect:(CGRect)rect {
  // Get graphics context.
  [self setContext:UIGraphicsGetCurrentContext()];
  
  // Clears background.
  setColor(_context, 0, 0, 64);
  fillRect(_context, 0, 0, self.frame.size.width, self.frame.size.height);

  [self renderField];
  [self renderPlayer];
  [self renderEffects];
}

// Renders field.
- (void)renderField {
  for (int i = 0; i < FIELDH; ++i) {
    int y = i * H + R;
    for (int j = 0; j < FIELDW - (i & 1); ++j) {
      int x = j * W + (i & 1) * R + R;
      int type = _field[fieldIndex(j, i)];
      if (type > 0) {
        drawBubble(_context, x, y, type);
      }
    }
  }
}

// Renders player.
- (void)renderPlayer {
  switch (_state) {
    default:
      break;
    case kIdleState:
    case kShootState:
      drawBubble(_context, _x, _y, _c);
      break;
  }
  drawBubble(_context, self.frame.size.width / 2 - R * 2, self.frame.size.height - R, _nextc);
}

// Renders effects.
- (void)renderEffects {
  for (int i = 0; i < [_effects count]; ++i) {
    Effect* effect = [_effects objectAtIndex:i];
    [effect render: _context];
  }
}

// Updates effects.
- (void)updateEffects {
  for (int i = 0; i < [_effects count]; ++i) {
    Effect* effect = [_effects objectAtIndex:i];
    if (![effect update]) {
      [_effects removeObject:effect];
      --i;
    }
  }
}

@end
