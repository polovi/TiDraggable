/**
 * An enhanced fork of the original TiDraggable module by Pedro Enrique,
 * allows for simple creation of "draggable" views.
 *
 * Copyright (C) 2013 Seth Benjamin
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * -- Original License --
 *
 * Copyright 2012 Pedro Enrique
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "TiDraggableView.h"
#import "TiDraggableViewProxy.h"
#import "TiUtils.h"
#import "TiRect.h"
#import "TiPoint.h"

@implementation TiDraggableView

#pragma mark Cleanup

- (void)dealloc
{
	[super dealloc];
}

#pragma mark Initialization

- (id)init
{
    self = [super init];

    if (self) {
        isDraggable = YES;
        ensureRight = YES;
        ensureBottom = YES;

        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];

        [self addGestureRecognizer:panRecognizer];
        [panRecognizer release];
    }

    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark View

- (TiPoint *)getViewCenter
{
    return [[[TiPoint alloc] initWithPoint:self.center] autorelease];
}

#pragma mark Touch Events

- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer
{
    if (isDraggable)
    {
        CGPoint translation = [panRecognizer translationInView:self.superview];
        CGPoint imageViewPosition = self.center;

        if([axis isEqualToString:@"x"])
        {
            imageViewPosition.x += translation.x;
            imageViewPosition.y = imageViewPosition.y;
        }
        else if([axis isEqualToString:@"y"])
        {
            imageViewPosition.x = imageViewPosition.x;
            imageViewPosition.y += translation.y;
        }
        else
        {
            imageViewPosition.x += translation.x;
            imageViewPosition.y += translation.y;
        }

        if(hasMaxLeft || hasMaxTop || hasMinLeft || hasMinTop)
        {
            CGSize size = self.frame.size;

            if(hasMaxLeft && imageViewPosition.x - size.width / 2 > maxLeft)
            {
                imageViewPosition.x = maxLeft + size.width / 2;
            }
            else if(hasMinLeft && imageViewPosition.x - size.width / 2 < minLeft)
            {
                imageViewPosition.x = minLeft + size.width / 2;
            }

            if(hasMaxTop && imageViewPosition.y - size.height / 2 > maxTop)
            {
                imageViewPosition.y = maxTop + size.height / 2;
            }
            else if(hasMinTop && imageViewPosition.y - size.height / 2 < minTop)
            {
                imageViewPosition.y = minTop + size.height / 2;
            }
        }

        self.center = imageViewPosition;

        [panRecognizer setTranslation:CGPointZero inView:self.superview];

        left = self.frame.origin.x;
        top = self.frame.origin.y;

        NSDictionary *tiProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithFloat:left], @"left",
                                 [NSNumber numberWithFloat:top], @"top",
                                 [self getViewCenter], @"center",
                                 nil];

        [(TiDraggableViewProxy*)[self proxy] setTop:[NSNumber numberWithFloat:top]];
        [(TiDraggableViewProxy*)[self proxy] setLeft:[NSNumber numberWithFloat:left]];

        if (ensureRight)
        {
            [(TiDraggableViewProxy*)[self proxy] setRight:[NSNumber numberWithFloat:-left]];
        }

        if (ensureBottom)
        {
            [(TiDraggableViewProxy*)[self proxy] setBottom:[NSNumber numberWithFloat:-top]];
        }

        if([self.proxy _hasListeners:@"start"] && [panRecognizer state] == UIGestureRecognizerStateBegan)
        {
            [self.proxy fireEvent:@"start" withObject:tiProps];
        }
        else if([self.proxy _hasListeners:@"move"] && [panRecognizer state] == UIGestureRecognizerStateChanged)
        {
            [self.proxy fireEvent:@"move" withObject:tiProps];
        }
        else if([self.proxy _hasListeners:@"end"] && [panRecognizer state] == UIGestureRecognizerStateEnded)
        {
            [self.proxy fireEvent:@"end" withObject:tiProps];
        }
        else if([self.proxy _hasListeners:@"cancel"] && [panRecognizer state] == UIGestureRecognizerStateCancelled)
        {
            [self.proxy fireEvent:@"cancel" withObject:tiProps];
        }
    }
}

- (void)pinchDetected:(UIPinchGestureRecognizer *)pinchRecognizer
{
    if (isDraggable) {
        CGFloat scale = pinchRecognizer.scale;
        self.transform = CGAffineTransformScale(self.transform, scale, scale);
        pinchRecognizer.scale = 1.0;
    }
}

- (void)rotationDetected:(UIRotationGestureRecognizer *)rotationRecognizer
{
    if (isDraggable) {
        CGFloat angle = rotationRecognizer.rotation;
        self.transform = CGAffineTransformRotate(self.transform, angle);
        rotationRecognizer.rotation = 0.0;
    }
}

#pragma mark Public API

- (void)setAxis_:(id)args
{
	ENSURE_SINGLE_ARG(args, NSString);

	axis = args;
}

- (void)setMaxTop_:(id)args
{
	ENSURE_SINGLE_ARG_OR_NIL(args, NSNumber);

    hasMaxTop = args != nil;
	maxTop = hasMaxTop ? [TiUtils floatValue:args] : 0;
}

- (void)setMaxLeft_:(id)args
{
	ENSURE_SINGLE_ARG_OR_NIL(args, NSNumber);

    hasMaxLeft = args != nil;
	maxLeft = hasMaxLeft ? [TiUtils floatValue:args] : 0;
}

- (void)setMinTop_:(id)args
{
	ENSURE_SINGLE_ARG_OR_NIL(args, NSNumber);

    hasMinTop = args != nil;
	minTop = hasMinTop ? [TiUtils floatValue:args] : 0;
}

- (void)setMinLeft_:(id)args
{
	ENSURE_SINGLE_ARG_OR_NIL(args, NSNumber);

    hasMinLeft = args != nil;
	minLeft = hasMinLeft ? [TiUtils floatValue:args] : 0;
}

- (void)setCanResize_:(id)args
{
    if([TiUtils boolValue:args] == YES)
    {
        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
        [pinchRecognizer setDelegate:self];
        [self addGestureRecognizer:pinchRecognizer];
        [pinchRecognizer release];
    }
}

- (void)setDraggable_:(id)args
{
    isDraggable = [TiUtils boolValue:args];
}

- (void)setEnsureRight_:(id)args
{
    ensureRight = [TiUtils boolValue:args];
}

- (void)setEnsureBottom_:(id)args
{
    ensureBottom = [TiUtils boolValue:args];
}

- (void)setCanRotate_:(id)args
{
    if([TiUtils boolValue:args] == YES)
    {
        UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationDetected:)];
        [rotationRecognizer setDelegate:self];
        [self addGestureRecognizer:rotationRecognizer];
        [rotationRecognizer release];
    }
}

@end