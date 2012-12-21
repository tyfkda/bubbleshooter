//
//  GameUIView.m
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import "GameUIView.h"


static const int WIDTH = 320;
static const int HEIGHT = 460;

static const int W = 32;
static const int H = W * 1.7320508 / 2;
static const int R = 16;

const int kColorBubbles = 6;


// Bubble color table.
static const int kBubbleColors[][3] = {
  { 0, 0, 0 },    // 0: Empty
  { 255, 0, 0 },  // 1: Red
  { 0, 255, 0 },  // 2: Green
  { 0, 0, 255 },  // 3: Blue
  { 255, 0, 255 },  // 4: Purple
  { 0, 255, 255 },  // 5: Cyan
  { 255, 255, 0 },  // 6: Yellow
};

// Set color.
void setColor(CGContextRef context, int r, int g, int b) {
  CGContextSetRGBFillColor(context, r/255.0f, g/255.0f, b/255.0f, 1.0f);
  CGContextSetRGBStrokeColor(context, r/255.0f, g/255.0f, b/255.0f, 1.0f);
}

// Fills circle with center position and radius.
void fillCircle(CGContextRef context, float x, float y, float r) {
  CGContextFillEllipseInRect(context, CGRectMake(x - r, y - r, r * 2, r * 2));
}

// Draws bubble with center position and type.
void drawBubble(CGContextRef context, float x, float y, int type) {
  int r = kBubbleColors[type][0];
  int g = kBubbleColors[type][1];
  int b = kBubbleColors[type][2];
  setColor(context, r, g, b);
  fillCircle(context, x, y, R);
}

int randi(int min, int max) {
  return arc4random_uniform(max - min) + min;
}

float randf(float min, float max) {
  return (((float)arc4random() / 0x100000000) * (max - min)) + min;
}



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





// Returns field index.
int fieldIndex(int x, int y) {
  return y * FIELDW + x;
}

// Adds 6 adjacent positions to the array.
bool validPosition(int x, int y) {
  return 0 <= y && y < FIELDH && 0 <= x && x < FIELDW - (y & 1);
}

// Adds 6 adjacent positions to the array.
void addAdjacentPositions(NSMutableArray* seeds, int x, int y) {
  int ox = x - 1 + (y & 1);
  int table[][2] = {
    { ox + 0, y - 1 },
    { ox + 1, y - 1 },
    { x - 1, y },
    { x + 1, y },
    { ox + 0, y + 1 },
    { ox + 1, y + 1 },
  };
  for (int i = 0; i < 6; ++i) {
    int xx = table[i][0];
    int yy = table[i][1];
    if (validPosition(xx, yy)) {
      [seeds addObject:[NSNumber numberWithInt:fieldIndex(xx, yy)]];
    }
  }
}

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

//ライン幅の指定
- (void)setLineWidth:(float)width {
  CGContextSetLineWidth(_context, width);
}

//ラインの描画
- (void)drawLine_x0:(float)x0 y0:(float)y0 x1:(float)x1 y1:(float)y1 {
  CGContextSetLineCap(_context, kCGLineCapRound);
  CGContextMoveToPoint(_context, x0, y0);
  CGContextAddLineToPoint(_context, x1, y1);
  CGContextStrokePath(_context);
}

//ポリラインの描画
- (void)drawPolyline_x:(float[])x y:(float[])y length:(int)length {
  CGContextSetLineCap(_context, kCGLineCapRound);
  CGContextSetLineJoin(_context, kCGLineJoinRound);
  CGContextMoveToPoint(_context, x[0], y[0]);
  for (int i=1; i<length; ++i) {
    CGContextAddLineToPoint(_context, x[i], y[i]);
  }
  CGContextStrokePath(_context);
}

//四角形の描画
- (void)drawRect_x:(float)x y:(float)y w:(float)w h:(float)h {
  CGContextMoveToPoint(_context, x, y);
  CGContextAddLineToPoint(_context, x+w, y);
  CGContextAddLineToPoint(_context, x+w, y+h);
  CGContextAddLineToPoint(_context, x, y+h);
  CGContextAddLineToPoint(_context, x, y);
  CGContextAddLineToPoint(_context, x+w, y);
  CGContextStrokePath(_context);
}

//四角形の塗り潰し
- (void)fillRect_x:(float)x y:(float)y w:(float)w h:(float)h {
  CGContextFillRect(_context,CGRectMake(x, y, w, h));
}

// Draws circle with center position and radius.
- (void)drawCircle_x:(float)x y:(float)y r:(float)r {
  CGContextAddEllipseInRect(_context, CGRectMake(x - r, y - r, r * 2, r * 2));
  CGContextStrokePath(_context);
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
      
      [self hitCheck];
      
      if (_y > HEIGHT + W / 2) {
        [self initializeBubble];
      }
      break;
  }

  [self updateEffects];

  // Requests redraw.
  [self setNeedsDisplay];
}

// Check bubble hits other bubble.
- (void)hitCheck {
  int result[2];
  if ([self hit_x:_x y:_y ox:-R oy:-R result:result] ||
      [self hit_x:_x y:_y ox:+R oy:-R result:result] ||
      [self hit_x:_x y:_y ox:-R oy:+R result:result] ||
      [self hit_x:_x y:_y ox:+R oy:+R result:result]) {
    _state = kDisappearState;
    int tx = result[0], ty = result[1];
    if (validPosition(tx, ty)) {
      _field[fieldIndex(tx, ty)] = _c;
      NSMutableArray* bubbles = [self countBubbles_x:tx y:ty c:_c];
      if ([bubbles count] >= 3) {
        [self eraseBubbles:bubbles];
        [self fallCheck:bubbles];
      }
    }
    [self initializeBubble];
  }
}

// Check bubble hits other bubble.
- (bool)hit_x: (int)x y:(int)y ox:(int)ox oy:(int)oy result:(int*)result {
  if (x + ox < 0 || y + oy < 0)
    return false;
  int by = (y + oy - (W - H) / 2) / H;
  if (by >= FIELDH)
    return false;
  int bx = (x + oy - (by & 1) * W / 2) / W;
  if (bx >= FIELDW)
    return false;
  if (_field[fieldIndex(bx, by)] == 0)
    return false;

  int target_x = bx * W + (by & 1) * W / 2 + W / 2;
  int target_y = by * H + W / 2;
  int dx = x - target_x;
  int dy = y - target_y;
  if (dx * dx + dy * dy > 4 * R * R)
    return false;

  // Hit a bubble.
  int tx = bx, ty = by;
  if (abs(dy) * sqrt(3) < abs(dx)) {
    tx += (dx >= 0) ? +1 : -1;
  } else {
    ty += (dy >= 0) ? +1 : -1;
    tx += (dx >= 0) ? 0 : -1;
    if (by & 1)
      ++tx;
  }
  result[0] = tx;
  result[1] = ty;
  return true;
}

// Counts bubbles connected more than 2.
- (NSMutableArray*)countBubbles_x:(int)x y:(int)y c:(int)c {
  bool checked[FIELDW * FIELDH];
  for (int i = 0; i < FIELDW * FIELDH; checked[i++] = false);
  NSMutableArray* seeds = [[NSMutableArray alloc] initWithCapacity:1];
  [seeds addObject:[NSNumber numberWithInt:fieldIndex(x, y)]];

  NSMutableArray* erasedBubbles = [[NSMutableArray alloc] init];
  int n = 0;
  while ([seeds count] > 0) {
    int position = [[seeds objectAtIndex:[seeds count] - 1] intValue];
    [seeds removeLastObject];
    int x = position % FIELDW;
    int y = position / FIELDW;
    if (!validPosition(x, y) || _field[position] != c || checked[position])
      continue;

    [erasedBubbles addObject:[NSNumber numberWithInt:position]];
    checked[position] = true;
    ++n;
    addAdjacentPositions(seeds, x, y);
  }
  return erasedBubbles;
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
  [self fillRect_x:0
                 y:0
                 w:self.frame.size.width
                 h:self.frame.size.height];

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
