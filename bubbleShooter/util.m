//
//  util.m
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import "util.h"

// Bubble color table.
const int kBubbleColors[][3] = {
  { 0, 0, 0 },    // 0: Empty
  { 255, 0, 0 },  // 1: Red
  { 0, 255, 0 },  // 2: Green
  { 0, 0, 255 },  // 3: Blue
  { 255, 0, 255 },  // 4: Purple
  { 0, 255, 255 },  // 5: Cyan
  { 255, 255, 0 },  // 6: Yellow
  { 128, 128, 128 },  // 7: Gray
};

int randi(int min, int max) {
  return arc4random_uniform(max - min) + min;
}

float randf(float min, float max) {
  return (((float)arc4random() / 0x100000000) * (max - min)) + min;
}

void setColor(CGContextRef context, int r, int g, int b) {
  CGContextSetRGBFillColor(context, r/255.0f, g/255.0f, b/255.0f, 1.0f);
  CGContextSetRGBStrokeColor(context, r/255.0f, g/255.0f, b/255.0f, 1.0f);
}

void fillRect(CGContextRef context, float x, float y, float w, float h) {
  CGContextFillRect(context, CGRectMake(x, y, w, h));
}

void fillCircle(CGContextRef context, float x, float y, float r) {
  CGContextFillEllipseInRect(context, CGRectMake(x - r, y - r, r * 2, r * 2));
}

void drawCircle(CGContextRef context, float x, float y, float r) {
  CGContextStrokeEllipseInRect(context, CGRectMake(x - r, y - r, r * 2, r * 2));
}

void drawLine(CGContextRef context, float x0, float y0, float x1, float y1) {
  //CGContextSetLineCap(context, kCGLineCapRound);
  CGContextMoveToPoint(context, x0, y0);
  CGContextAddLineToPoint(context, x1, y1);
  CGContextStrokePath(context);
}

static float intersectRayCircle(float ox, float oy, float dx, float dy, float cx, float cy, float radius) {
  float vx = ox - cx, vy = oy - cy;
  float a = dx * dx + dy * dy;
  float b = dx * vx + dy * vy;
  float c = vx * vx + vy * vy - radius * radius;
  float d = b * b - a * c;
  if (d >= 0) {
    float s = sqrt(d);
    float t = (-b - s) / a;
    if (t <= 0)  t = (-b + s) / a;
    return t;
  }
  return -1;
}

////////////////////////////////////////////////////////////////////
// Application specific utility functions

int fieldIndex(int x, int y) {
  return y * FIELDW + x;
}

bool validPosition(int x, int y) {
  return 0 <= y && y < FIELDH && 0 <= x && x < FIELDW - (y & 1);
}

typedef struct {
  float t;
  int bx, by;
} HitInfo;

static bool hitFieldBubble(const int* field, int bx, int by, float x, float y, int radius, float vx, float vy, HitInfo* hitinfo) {
  if (!validPosition(bx, by) ||
      field[fieldIndex(bx, by)] == 0)
    return false;

  int target_x = bx * W + (by & 1) * R + R;
  int target_y = by * H + R;
  float t = intersectRayCircle(x, y, vx, vy, target_x, target_y, radius);
  if (t < 0)
    return false;
  if (t >= hitinfo->t)
    return false;
  
  hitinfo->t = t;
  hitinfo->bx = bx;
  hitinfo->by = by;
  return true;
}

static void calcHitPos(const int* field, float x, float y, float vx, float vy, const HitInfo* hitinfo, int* px, int* py) {
  const float t = hitinfo->t;
  const int bx = hitinfo->bx, by = hitinfo->by;
  const int target_x = bx * W + (by & 1) * R + R;
  const int target_y = by * H + R;

  float hx = x + vx * t;
  float hy = y + vy * t;
  float dx = hx - target_x;
  float dy = hy - target_y;
  
  // Hit a bubble.
  int tx = bx, ty = by;
  if (abs(dy) * sqrt(3) < abs(dx)) {
    tx += (dx >= 0) ? +1 : -1;
  } else {
    ty += (dy >= 0) ? +1 : -1;
    tx += (dx >= 0) ? 0 : -1;
    if (by & 1)
      ++tx;
    if (tx < 0)
      ++tx;
    if (tx >= FIELDW - (ty & 1))
      --tx;
  }
  *px = tx;
  *py = ty;
}

// Check bubble hits other bubble in the field.
bool hitFieldCheck(const int* field, float x, float y, int r, float vx, float vy, int* ptx, int* pty) {
  HitInfo hitinfo;
  hitinfo.t = 1;
  hitinfo.bx = hitinfo.by = -1;

  const float x0 = MIN(x, x + vx), y0 = MIN(y, y + vy);
  const float x1 = MAX(x, x + vx), y1 = MAX(y, y + vy);
  for (int by = (y0 - R - 2 * R) / H - 1; by <= (y1 + R - 2 * R) / H + 1; ++by) {
    for (int bx = (x0 - R - (by & 1) * R) / W; bx <= (x1 + R - (by & 1) * R) / W; ++bx) {
      hitFieldBubble(field, bx, by, x, y, r, vx, vy, &hitinfo);
    }
  }

  if (hitinfo.bx >= 0 && hitinfo.by >= 0) {
    int tx, ty;
    calcHitPos(field, x, y, vx, vy, &hitinfo, &tx, &ty);
    
    if (!validPosition(tx, ty) || field[fieldIndex(tx, ty)] != 0) {
      [NSException raise:@"Invalid hit position" format:@"pos(%d,%d), base(%d,%d), bubble(%.1f,%.1f), vel(%.1f,%.1f), t:%.4f", tx, ty, hitinfo.bx, hitinfo.by, x, y, vx, vy, hitinfo.t];
    } else {
      *ptx = tx;
      *pty = ty;
      return true;
    }
  }

  return false;
}

NSMutableArray* countBubbles(const int* field, int x, int y, int c, int miny) {
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
    if (y < miny || !validPosition(x, y) || field[position] != c || checked[position])
      continue;
    
    [erasedBubbles addObject:[NSNumber numberWithInt:position]];
    checked[position] = true;
    ++n;
    addAdjacentPositions(seeds, x, y);
  }
  return erasedBubbles;
}

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

// Checks bubbles fall.
NSMutableArray* fallCheck(const int* field) {
  NSMutableArray* cutoffBubbles = [[NSMutableArray alloc] init];
  NSMutableArray* seeds = [[NSMutableArray alloc] initWithCapacity:FIELDW];
  for (int x = 0; x < FIELDW; ++x) {
    [seeds addObject:[NSNumber numberWithInt:fieldIndex(x, 0)]];
  }

  bool checked[FIELDW * FIELDH];
  for (int i = 0; i < FIELDW * FIELDH; checked[i++] = false);

  for (int i = 0; i < [seeds count]; ++i) {
    int position = [[seeds objectAtIndex:i] intValue];
    if (field[position] == 0 || checked[position])
      continue;

    checked[position] = true;
    int x = position % FIELDW;
    int y = position / FIELDW;
    addAdjacentPositions(seeds, x, y);
  }

  for (int y = 0; y < FIELDH; ++y) {
    for (int x = 0; x < FIELDW - (y & 1); ++x) {
      int position = fieldIndex(x, y);
      if (field[position] == 0 || checked[position])
        continue;
      [cutoffBubbles addObject:[NSNumber numberWithInt:position]];
    }
  }
  return cutoffBubbles;
}

void drawBubble(CGContextRef context, float x, float y, int type) {
  if (type == 0)
    return;
  int r = kBubbleColors[type][0];
  int g = kBubbleColors[type][1];
  int b = kBubbleColors[type][2];
  setColor(context, r, g, b);
  fillCircle(context, x, y, R);
  setColor(context, r >> 1, g >> 1, b >> 1);
  drawCircle(context, x, y, R);
}
