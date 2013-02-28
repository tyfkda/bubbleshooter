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
static const int W = 32;
static const int H = W * 1.7320508 / 2;
static const int R = 16;

static const int FIELDW = 10;
static const int FIELDH = 15 + 3;
static const int FIELDX = 0;
static const int FIELDY = 14;

// Number of bubble colors.
static const int kColorBubbles = 6;

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

////////////////////////////////////////////////////////////////////
// Application specific utility functions

// Returns field index.
int fieldIndex(int x, int y);

// Whether the position is valid.
bool validPosition(int x, int y);

// Check bubble hits to field bubble.
bool hitFieldBubble(int* field, int bx, int by, int x, int y, int radius, int* px, int* py);

// Counts same color bubbles.
NSMutableArray* countBubbles(int* field, int x, int y, int c);

// Adds 6 adjacent positions to the array.
void addAdjacentPositions(NSMutableArray* seeds, int x, int y);

// Draws bubble with center position and type.
void drawBubble(CGContextRef context, float x, float y, int type);
