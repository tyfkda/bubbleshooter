//
//  GameUIView.m
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import "GameUIView.h"
#import "util.h"



@interface Effect : NSObject {
  float _x, _y;
  float _vx, _vy;
  int _c;
}
-(void) initialize: (int)x y:(int)y c:(int)c;
-(bool) update;
-(void) render: (CGContextRef)context;
@end


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



@implementation GameUIView

static const int kIdleState = 0;
static const int kShootState = 1;
static const int kDisappearState = 2;

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
  _timer=[NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f
                                          target:self
                                        selector:@selector(onTick:)
                                        userInfo:nil
                                         repeats:YES];//retain必要なし

  // Initializes field.
  for (int i = 0; i < FIELDW * FIELDH; ++i) {
    _field[i] = 0;
  }
  for (int i = 0; i < FIELDH / 2; ++i) {
    for (int j = 0; j < FIELDW; ++j) {
      _field[fieldIndex(j, i)] = randi(1, kColorBubbles + 1);
    }
  }

  // Initializes bubble.
  [self initializeBubble];
  
  _effects = [[NSMutableArray alloc] init];
}

- (void)initializeBubble {
  _state = kIdleState;
  _x = WIDTH / 2;
  _y = H * (FIELDH - 1) + W / 2;
  _c = randi(1, kColorBubbles + 1);
  _vx = _vy = 0;
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
        const float V = 5;
        float l = sqrt(dx * dx + dy * dy);
        _vx = dx * V / l;
        _vy = dy * V / l;
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
  if (hitBubble(_field, _x, _y, -R, -R, &tx, &ty) ||
      hitBubble(_field, _x, _y, +R, -R, &tx, &ty) ||
      hitBubble(_field, _x, _y, -R, +R, &tx, &ty) ||
      hitBubble(_field, _x, _y, +R, +R, &tx, &ty)) {
    if (validPosition(tx, ty)) {
      _field[fieldIndex(tx, ty)] = _c;
      NSMutableArray* bubbles = countBubbles(_field, tx, ty, _c);
      if ([bubbles count] >= 3) {
        [self eraseBubbles:bubbles];
        [self fallCheck:bubbles];
        _state = kDisappearState;
      } else {
        [self initializeBubble];
      }
    } else {
      [self initializeBubble];
    }
    return true;
  }
  return false;
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
  for (int i = 0; i < [erasedBubbles count]; ++i) {
    int position = [[erasedBubbles objectAtIndex:i] intValue];
    int x = position % FIELDW;
    int y = position / FIELDW;
    NSMutableArray* seeds = [[NSMutableArray alloc] initWithCapacity:6];
    addAdjacentPositions(seeds, x, y);
    for (int j = 0; j < [seeds count]; ++j) {
      [self fallCheckSub:[[seeds objectAtIndex:j] intValue]];
    }
  }
}

// Checks bubbles fall.
- (void)fallCheckSub:(int)seed {
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
      return;
    }
    addAdjacentPositions(seeds, x, y);
  }

  // Not sticked with ceil. Fall all bubbles.
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
  }
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
    int y = i * H + W / 2;
    for (int j = 0; j < FIELDW - (i & 1); ++j) {
      int x = j * W + (i & 1) * W / 2 + W / 2;
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
