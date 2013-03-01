//
//  Field.m
//  bubbleShooter
//
//  Created by Keita Obo on 13/03/01.
//  Copyright (c) 2013 Keita Obo. All rights reserved.
//

#import "Field.h"
#import "Effect.h"

// Player state.
enum {
  kIdleState,
  kShootState,
  kGameOver,
};

const float BUBBLE_VELOCITY = 12;

@implementation Field


- (int)getScore { return _score; }
- (int)getTime { return _time; }

// Initialize.
- (void)initialize {
  // Initializes field.
  for (int i = 0; i < FIELDW * FIELDH; _field[i++] = 0);
  for (int i = 0; i < FIELDH / 2; ++i) {
    [self setRandomLine: i];
  }
  
  // Initializes bubble.
  _nextc = [self chooseNextBubble];
  [self initializeBubble];
  
  _effects = [[NSMutableArray alloc] init];
  _score = 0;
  _time = 0;
  _scrolly = -3 * H * 1024;
  _scrollSpeed = 1024 / (2 * 60) * 4;
}

- (void)setRandomLine: (int)y {
  for (int x = 0; x < FIELDW - (y & 1); ++x) {
    int c;
    if (randi(0, 65536) < 65536 / 30) {
      c = 7;  // Gray
    } else {
      c = randi(1, kColorBubbles + 1);
    }
    _field[fieldIndex(x, y)] = c;
  }
}

- (int)chooseNextBubble {
  // Search field to list up enable bubble colors.
  bool enable[kColorBubbles];
  for (int i = 0; i < kColorBubbles; ++i)
    enable[i] = false;
  int n = 0;
  for (int i = 0; i < FIELDW * FIELDH; ++i) {
    if (_field[i] != 0) {
      int c = _field[i] - 1;
      if (c < kColorBubbles && !enable[c]) {
        enable[c] = true;
        ++n;
      }
    }
  }
  int r = randi(0, n);
  for (int i = 0; i < kColorBubbles; ++i) {
    if (enable[i])
      if (--r < 0)
        return i + 1;
  }
  
  NSLog(@"Must not come here.");
  return randi(1, kColorBubbles + 1);
}

- (void)initializeBubble {
  _state = kIdleState;
  _x = WIDTH / 2;
  _y = H * (FIELDH - 1) + R - 2 * H;
  _c = _nextc;
  _vx = _vy = 0;
  _nextc = [self chooseNextBubble];
}

// Scroll down.
- (bool)scrollDown {
  _scrolly += _scrollSpeed;
  if (_scrolly >= -1 * H * 1024) {
    _scrolly -= 2 * H * 1024;
    
    // Shift field.
    for (int i = FIELDW * FIELDH; --i >= FIELDW * 2; ) {
      _field[i] = _field[i - FIELDW * 2];
    }
    for (int y = 0; y < 2; ++y) {
      [self setRandomLine: y];
    }
    
    if ([self isGameOver])
      return false;
  }
  return true;
}

// On touch end.
- (void)touchesEnded:(CGPoint)pos {
  switch (_state) {
    default:
      break;
    case kIdleState:
    {
      float dx = (pos.x - FIELDX) - _x;
      float dy = (pos.y - FIELDY) - _y;
      const int tan5 = 87;
      if (dy < 0 && (dx == 0 || 1000 * abs(dy) / abs(dx) >= tan5)) {
        float l = sqrt(dx * dx + dy * dy);
        _vx = dx * BUBBLE_VELOCITY / l;
        _vy = dy * BUBBLE_VELOCITY / l;
        _state = kShootState;
        //AudioServicesPlaySystemSound(_shootSoundId);
      }
    } break;
  }
}

- (void)setGameOver {
  _state = kGameOver;
  //_backButton.hidden = NO;
}

// On tick event.
- (void)onTick {
  switch (_state) {
    default:
      break;
    case kIdleState:
      _time += 1;
      if (![self scrollDown]) {
        [self setGameOver];
      }
      break;
    case kShootState:
      _time += 1;
      if (![self scrollDown]) {
        [self setGameOver];
      }
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
      
      if ([self hitCheck]) {
        if ([self isGameOver]) {
          [self setGameOver];
        }
      }
      break;
    case kGameOver:
      break;
  }
  
  [self updateEffects];
}

// Check bubble hits other bubble.
- (bool)hitCheck {
  int y = _y - _scrolly / 1024;
  int tx, ty;
  for (int by = ((int)y - R - 2 * R) / H; by <= ((int)y + R - 2 * R) / H; ++by) {
    for (int bx = ((int)_x - R - (by & 1) * R) / W; bx <= ((int)_x + R - (by & 1) * R) / W; ++bx) {
      if (hitFieldBubble(_field, bx, by, _x, y, R + R - 4, &tx, &ty))
        goto find;
    }
  }
  return false;
  
find:
  if (!validPosition(tx, ty) || _field[fieldIndex(tx, ty)] != 0) {
    NSLog(@"Invalid hit position: (%d,%d)", tx, ty);
    [self initializeBubble];
    return false;
  }
  
  _field[fieldIndex(tx, ty)] = _c;
  int miny = -_scrolly / (1024 * H);
  NSMutableArray* bubbles = countBubbles(_field, tx, ty, _c, miny);
  int connect_count = [bubbles count];
  if (connect_count >= 3) {
    [self eraseBubbles:bubbles];
    int cutoff_count = [self fallCheck:bubbles bubbleX:_x bubbleY:y];
    _score += connect_count * 10 + cutoff_count * 100;
    
    //AudioServicesPlaySystemSound(_disappearSoundId);
  }
  [self initializeBubble];
  return true;
}

// Whether game is over.
- (bool)isGameOver {
  int y = FIELDH - 1;
  for (int x = 0; x < FIELDW - (y & 1); ++x) {
    if (_field[y * FIELDW + x] != 0)
      return true;
  }
  return false;
}

// Erase bubbles.
- (void)eraseBubbles:(NSMutableArray*)bubbles {
  for (int i = 0; i < [bubbles count]; ++i) {
    int position = [[bubbles objectAtIndex:i] intValue];
    int c = _field[position];
    _field[position] = 0;
    
    int x = position % FIELDW, y = position / FIELDW;
    int xx = x * W + (y & 1) * R + R + FIELDX;
    int yy = y * H + R + _scrolly / 1024 + FIELDY;
    DisappearEffect* effect = [[DisappearEffect alloc] init];
    [effect initialize: xx y:yy c:c r:R];
    [_effects addObject:effect];
  }
}

// Checks bubbles fall.
- (int)fallCheck:(NSMutableArray*)erasedBubbles bubbleX:(int)bubbleX bubbleY:(int)bubbleY {
  int cutoff_count = 0;
  for (int i = 0; i < [erasedBubbles count]; ++i) {
    int position = [[erasedBubbles objectAtIndex:i] intValue];
    int x = position % FIELDW;
    int y = position / FIELDW;
    NSMutableArray* seeds = [[NSMutableArray alloc] initWithCapacity:6];
    addAdjacentPositions(seeds, x, y);
    for (int j = 0; j < [seeds count]; ++j) {
      cutoff_count += [self fallCheckSub:[[seeds objectAtIndex:j] intValue] bubbleX:bubbleX bubbleY:bubbleY];
    }
  }
  return cutoff_count;
}

// Checks bubbles fall.
- (int)fallCheckSub:(int)seed bubbleX:(int)bubbleX bubbleY:(int)bubbleY {
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
    float vx = (float)(xx - bubbleX) / 10;
    float vy = (float)(yy - bubbleY) / 10;
    FallEffect* effect = [[FallEffect alloc] init];
    [effect initialize: (xx + FIELDX) y:(yy + _scrolly / 1024 + FIELDY) c:_field[position] vx:vx vy:vy];
    [_effects addObject:effect];
    
    checked[position] = false;
    _field[position] = 0;
    ++cutoff_count;
  }
  return cutoff_count;
}

// Render.
- (void)render:(CGContextRef) context rect:(CGRect)rect {
  // Clears background.
  setColor(context, 0, 0, 64);
  fillRect(context, 0, 0, rect.size.width, rect.size.height);
  
  [self renderField: context beGray:(_state == kGameOver)];
  if (_state != kGameOver) {
    [self renderPlayer: context];
  }
  [self renderEffects: context];
  
  setColor(context, 0, 0, 64);
  fillRect(context, 0, 0, rect.size.width, FIELDY);
}

// Renders field.
- (void)renderField: (CGContextRef) context beGray:(bool)beGray {
  int basey = _scrolly / 1024 + FIELDY;
  for (int i = 0; i < FIELDH; ++i) {
    int y = i * H + R + basey;
    for (int j = 0; j < FIELDW - (i & 1); ++j) {
      int x = j * W + (i & 1) * R + R + FIELDX;
      int type = _field[fieldIndex(j, i)];
      if (type > 0) {
        if (beGray) {
          type = 7;
        }
        drawBubble(context, x, y, type);
      }
    }
  }
}

// Renders player.
- (void)renderPlayer: (CGContextRef) context {
  switch (_state) {
    default:
      break;
    case kIdleState:
    case kShootState:
      drawBubble(context, _x + FIELDX, _y + FIELDY, _c);
      break;
  }
  drawBubble(context, WIDTH / 2 - R * 2 + FIELDX, HEIGHT - R + FIELDY, _nextc);
}

// Renders effects.
- (void)renderEffects: (CGContextRef) context {
  for (int i = 0; i < [_effects count]; ++i) {
    Effect* effect = [_effects objectAtIndex:i];
    [effect render: context];
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
