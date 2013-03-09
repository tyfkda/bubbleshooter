//
//  util.h
//  bubbleShooter
//
//  Created by Keita Obo on 12/12/21.
//  Copyright (c) 2012 Keita Obo. All rights reserved.
//

#import <Foundation/Foundation.h>

// Main screen size.
static const int WIDTH = 320;
static const int HEIGHT = 460;

// Bubble and field size.
static const int W = 30;
static const int H = W * 1.7320508 / 2;
static const int R = 15;

static const int FIELDW = 10;
static const int FIELDH = 15 + 3;
static const int FIELDX = (WIDTH - W * FIELDW) / 2;
static const int FIELDY = 14;

// Number of bubble colors.
static const int kColorBubbles = 4;  //6;

// Returns random integer.
int randi(int min, int max);

// Returns random float.
float randf(float min, float max);

// Sets color.
void setColor(CGContextRef context, int r, int g, int b);

// Fills rectangle.
void fillRect(CGContextRef context, float x, float y, float w, float h);

// Fills circle with center position and radius.
void fillCircle(CGContextRef context, float x, float y, float r);

// Draws circle with center position and radius.
void drawCircle(CGContextRef context, float x, float y, float r);

void drawLine(CGContextRef context, float x0, float y0, float x1, float y1);

////////////////////////////////////////////////////////////////////
// Application specific utility functions

extern const int kBubbleColors[][3];

// Returns field index.
int fieldIndex(int x, int y);

// Whether the position is valid.
bool validPosition(int x, int y);

bool hitFieldCheck(const int* field, float x, float y, int r, int* ptx, int* pty);

// Counts same color bubbles.
NSMutableArray* countBubbles(const int* field, int x, int y, int c, int miny);

// Adds 6 adjacent positions to the array.
void addAdjacentPositions(NSMutableArray* seeds, int x, int y);

NSMutableArray* fallCheck(const int* field);

// Draws bubble with center position and type.
void drawBubble(CGContextRef context, float x, float y, int type);
