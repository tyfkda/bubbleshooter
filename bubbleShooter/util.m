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

////////////////////////////////////////////////////////////////////
// Application specific utility functions

int fieldIndex(int x, int y) {
  return y * FIELDW + x;
}

bool validPosition(int x, int y) {
  return 0 <= y && y < FIELDH && 0 <= x && x < FIELDW - (y & 1);
}

bool hitFieldBubble(const int* field, int bx, int by, int x, int y, int radius, int* px, int* py) {
  if (!validPosition(bx, by) ||
      field[fieldIndex(bx, by)] == 0)
    return false;
  
  int target_x = bx * W + (by & 1) * W / 2 + W / 2;
  int target_y = by * H + W / 2;
  int dx = x - target_x;
  int dy = y - target_y;
  if (dx * dx + dy * dy > radius * radius)
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
  *px = tx;
  *py = ty;
  return true;
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
