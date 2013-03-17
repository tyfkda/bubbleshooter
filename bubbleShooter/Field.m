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
  kPlaying,
  kGameOver,
};

@implementation Field

- (int)getScore { return _score; }
- (int)getTime { return _time; }
- (bool)isGameOver { return _state == kGameOver; }

// Initialize.
- (void)initialize {
  // Initializes field.
  for (int i = 0; i < FIELDW * FIELDH; _field[i++] = 0);
  for (int i = 0; i < FIELDH / 2; ++i) {
    [self setRandomLine: i];
  }
  
  // Initializes bubble.
  _state = kPlaying;
  for (int i = 0; i < sizeof(_nextc) / sizeof(*_nextc); ++i)
    _nextc[i] = [self chooseNextBubble];
  for (int i = 0; i < MAX_SHOT; ++i)
    _bubbles[i].active = false;
  
  _effects = [[NSMutableArray alloc] init];
  _score = 0;
  _time = 0;
  _scrolly = -3 * H * 1024;
  _scrollSpeed = 1024 / (2 * 60) * 4;
}

- (void)setField:(const int*)field {
  memcpy(_field, field, sizeof(_field));
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

- (void)shiftNext {
  const int n = sizeof(_nextc) / sizeof(*_nextc);
  memmove(&_nextc[0], &_nextc[1], (n - 1) * sizeof(*_nextc));
  _nextc[n - 1] = [self chooseNextBubble];
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
    
    if ([self detectGameOver])
      return false;
  }
  return true;
}

// On touch end.
- (void)touchesEnded:(CGPoint)pos {
  switch (_state) {
    default:
      break;
    case kPlaying:
    {
      Bubble* bubble = NULL;
      for (int i = 0; i < MAX_SHOT; ++i) {
        if (!_bubbles[i].active) {
          bubble = &_bubbles[i];
          break;
        }
      }
      if (bubble != NULL) {
        if ([self shotBubble:bubble pos:pos x:BUBBLE_X y:BUBBLE_Y c:_nextc[0]]) {
          //AudioServicesPlaySystemSound(_shootSoundId);
          [self shiftNext];
        }
      }
    } break;
  }
}

- (bool)shotBubble:(Bubble*)bubble pos:(CGPoint)pos x:(float)x y:(float)y c:(int)c {
  float dx = (pos.x - FIELDX) - x;
  float dy = (pos.y - FIELDY) - y;
  const int tan5 = 87;
  if (dy >= 0 || (dx != 0 && 1000 * abs(dy) / abs(dx) < tan5))
    return false;

  float l = sqrt(dx * dx + dy * dy);
  bubble->active = true;
  bubble->x = x;
  bubble->y = y;
  bubble->c = c;
  bubble->vx = dx * BUBBLE_VELOCITY / l;
  bubble->vy = dy * BUBBLE_VELOCITY / l;
  return true;
}

- (void)setGameOver {
  _state = kGameOver;
}

// On tick event.
- (void)onTick {
  switch (_state) {
    default:
      break;
    case kPlaying:
      _time += 1;
      if (![self scrollDown]) {
        [self setGameOver];
      }
      
      bool hit = false;
      for (int i = 0; i < MAX_SHOT; ++i)
        hit |= [self moveBubble: &_bubbles[i]];
      if (hit) {
        if ([self detectGameOver]) {
          [self setGameOver];
        }
      }
      break;
    case kGameOver:
      break;
  }
  
  [self updateEffects];
}

- (bool)moveBubble: (Bubble*) bubble {
  if (!bubble->active)
    return true;

  int tx, ty;
  int y = bubble->y - _scrolly / 1024;
  if (hitFieldCheck(_field, bubble->x, y, R + R - 4, bubble->vx, bubble->vy, &tx, &ty)) {
    [self setBubble: bubble tx:tx ty:ty];
    bubble->active = false;
    return false;
  }

  bubble->x += bubble->vx;
  bubble->y += bubble->vy;
  if (bubble->x < R || bubble->x > FIELDW * W - R)
    bubble->vx = -bubble->vx;
  if (bubble->y < R)
    bubble->vy = -bubble->vy;
  if (bubble->y > HEIGHT + R) {
    bubble->active = false;
    return true;
  }

  return true;
}

- (void)setBubble: (Bubble*) bubble tx:(int)tx ty:(int)ty {
  _field[fieldIndex(tx, ty)] = bubble->c;
  int miny = -_scrolly / (1024 * H);
  NSMutableArray* bubbles = countBubbles(_field, tx, ty, bubble->c, miny);
  int connect_count = [bubbles count];
  if (connect_count >= 3) {
    [self eraseBubbles:bubbles];
    //int y = bubble->y - _scrolly / 1024;

    NSMutableArray* cutoffBubbles = fallCheck(_field);
    int cutoff_count = [cutoffBubbles count];
    if (cutoff_count > 0) {
      for (int i = 0; i < [cutoffBubbles count]; ++i) {
        int position = [[cutoffBubbles objectAtIndex:i] intValue];
        int x = position % FIELDW;
        int y = position / FIELDW;
        
        int xx = x * W + (y & 1) * R + R;
        int yy = y * H + R;
        float vx = (float)(xx - bubble->x) / 10;
        float vy = (float)(yy - bubble->y) / 10;
        FallEffect* effect = [[FallEffect alloc] init];
        [effect initialize: (xx + FIELDX) y:(yy + _scrolly / 1024 + FIELDY) c:_field[position] vx:vx vy:vy];
        [_effects addObject:effect];
        _field[position] = 0;
      }
    }

    _score += connect_count * 10 + cutoff_count * 100;

    //AudioServicesPlaySystemSound(_disappearSoundId);
  }
}

// Whether game is over.
- (bool)detectGameOver {
  int y = (-_scrolly / (H * 1024)) + FIELDH - 3 - 1;
  for (int x = 0; x < FIELDW - (y & 1); ++x) {
    if (_field[y * FIELDW + x] != 0)
      return true;
  }
  return false;
}

// Erase bubbles.
- (void)eraseBubbles:(NSMutableArray*)bubbles {
  const int offsetX = R + FIELDX;
  const int offsetY = R + _scrolly / 1024 + FIELDY;
  for (int i = 0; i < [bubbles count]; ++i) {
    int position = [[bubbles objectAtIndex:i] intValue];
    int c = _field[position];
    _field[position] = 0;
    
    int x = position % FIELDW, y = position / FIELDW;
    int xx = x * W + (y & 1) * R + offsetX;
    int yy = y * H + offsetY;
    DisappearEffect* effect = [[DisappearEffect alloc] init];
    [effect initialize: xx y:yy c:c r:R];
    [_effects addObject:effect];
  }
}

// Render.
- (void)render:(CGContextRef) context rect:(CGRect)rect {
  {  // Dead line.
    const int y = (FIELDH - 3 - 2) * H + R * 2 + FIELDY;
    setColor(context, 128, 128, 128);
    drawLine(context, FIELDX, y, WIDTH - FIELDX, y);
  }

  [self renderField: context beGray:(_state == kGameOver)];
  if (_state != kGameOver) {
    [self renderPlayer: context];
  }
  [self renderEffects: context];
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

  setColor(context, 128, 0, 0);
  fillRect(context, 0, FIELDY, FIELDX, HEIGHT - FIELDY);
  fillRect(context, WIDTH - FIELDX, FIELDY, FIELDX, HEIGHT - FIELDY);
}

// Renders player.
- (void)renderPlayer: (CGContextRef) context {
  drawBubble(context, BUBBLE_X + FIELDX, BUBBLE_Y + FIELDY, _nextc[0]);
  drawBubble(context, WIDTH / 2 - R * 2 + FIELDX, HEIGHT - R + FIELDY, _nextc[1]);

  for (int i = 0; i < MAX_SHOT; ++i)
    [self renderBubble: context bubble:&_bubbles[i]];
}

// Renders player.
- (void)renderBubble: (CGContextRef) context bubble:(Bubble*)bubble {
  if (!bubble->active)
    return;
  drawBubble(context, bubble->x + FIELDX, bubble->y + FIELDY, bubble->c);
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
