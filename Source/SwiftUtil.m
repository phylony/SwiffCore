/*
    SwiftUtil.m
    Copyright (c) 2011, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "SwiftUtil.h"
#import <asl.h>


BOOL _SwiftShouldLog = NO;

void SwiftEnableLogging()
{
    _SwiftShouldLog = YES;
}


void _SwiftLog(NSInteger level, NSString *format, ...)
{
    if (!format) return;

    va_list  v;
    va_start(v, format);

#if TARGET_IPHONE_SIMULATOR
    NSLogv(format, v);
#else
    CFStringRef message = CFStringCreateWithFormatAndArguments(NULL, NULL, (CFStringRef)format, v);
    
    if (message) {
        UniChar *characters = (UniChar *)CFStringGetCharactersPtr((CFStringRef)message);
        CFIndex  length     = CFStringGetLength(message);
        BOOL     needsFree  = NO;

        if (!characters) {
            characters = malloc(sizeof(UniChar) * length);
            
            if (characters) {
                CFStringGetCharacters(message, CFRangeMake(0, length), characters);
                needsFree = YES;
            }
        }

        // Always log to ASL

        asl_log(NULL, NULL, level, "%ls\n", (wchar_t *)characters);

        if (needsFree) {
            free(characters);
        }

        CFRelease(message);
    }
#endif

    va_end(v);
}

static void sSwiftColorApplyColorTransformPointer(SwiftColor *color, SwiftColorTransform *transform)
{
    color->red = (color->red * transform->redMultiply) + transform->redAdd;
    if      (color->red < 0.0) color->red = 0.0;
    else if (color->red > 1.0) color->red = 1.0;
    
    color->green = (color->green * transform->greenMultiply) + transform->greenAdd;
    if      (color->green < 0.0) color->green = 0.0;
    else if (color->green > 1.0) color->green = 1.0;

    color->blue  = (color->blue * transform->blueMultiply)  + transform->blueAdd;
    if      (color->blue < 0.0) color->blue = 0.0;
    else if (color->blue > 1.0) color->blue = 1.0;
    
    color->alpha = (color->alpha * transform->alphaMultiply) + transform->alphaAdd;
    if      (color->alpha < 0.0) color->alpha = 0.0;
    else if (color->alpha > 1.0) color->alpha = 1.0;
}


SwiftColor SwiftColorApplyColorTransform(SwiftColor color, SwiftColorTransform transform)
{
    sSwiftColorApplyColorTransformPointer(&color, &transform);
    return color;
}


SwiftColor SwiftColorApplyColorTransformStack(SwiftColor color, CFArrayRef stack)
{
    if (!stack) return color;
    for (CFIndex i = 0, count = CFArrayGetCount(stack); i < count; i++) {
        SwiftColorTransform *transformPtr = (SwiftColorTransform *)CFArrayGetValueAtIndex(stack, i);
        sSwiftColorApplyColorTransformPointer(&color, transformPtr);
    }
    
    return color;
}

