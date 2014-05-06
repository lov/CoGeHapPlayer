/*
 HapSupport.m
 Hap QuickTime Playback
 
 Copyright (c) 2012-2013, Tom Butterworth and Vidvox LLC. All rights reserved.
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of Hap nor the name of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "HapSupport.h"
#import <QuickTime/QuickTime.h>

/*
 These are the four-character-codes used to designate the three Hap codecs
 */
#define kHapCodecSubType 'Hap1'
#define kHapAlphaCodecSubType 'Hap5'
#define kHapYCoCgCodecSubType 'HapY'

/*
 Searches the list of installed codecs for a given codec
 */
static BOOL HapQTCodecIsAvailable(OSType codecType)
{
    CodecNameSpecListPtr list;
    
    OSStatus error = GetCodecNameList(&list, 0);
    if (error) return NO;
    
    for (short i = 0; i < list->count; i++ )
    {        
        if (list->list[i].cType == codecType) return YES;
    }
    
    return NO;
}

/*
 Much of QuickTime is deprecated in recent MacOS but no equivalent functionality exists in modern APIs,
 so we ignore these warnings.
 */
#pragma GCC push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
BOOL HapQTMovieHasHapTrackPlayable(QTMovie *movie)
{
    // Loop through every video track
    for (QTTrack *track in [movie tracksOfMediaType:QTMediaTypeVideo])
    {
        Media media = [[track media] quickTimeMedia];
        
        // Get the codec-type of this track
        ImageDescriptionHandle imageDescription = (ImageDescriptionHandle)NewHandle(0); // GetMediaSampleDescription will resize it
        GetMediaSampleDescription(media, 1, (SampleDescriptionHandle)imageDescription);
        OSType codecType = (*imageDescription)->cType;
        DisposeHandle((Handle)imageDescription);
        
        switch (codecType) {
            case kHapCodecSubType:
            case kHapAlphaCodecSubType:
            case kHapYCoCgCodecSubType:
                return HapQTCodecIsAvailable(codecType);
            default:
                break;
        }
    }
    return NO;
}
#pragma GCC pop

CFDictionaryRef HapQTCreateCVPixelBufferOptionsDictionary()
{
    // The pixel formats we want. These are registered by the Hap codec.
    SInt32 rgb_dxt1 = kHapPixelFormatTypeRGB_DXT1;
    SInt32 rgba_dxt5 = kHapPixelFormatTypeRGBA_DXT5;
    SInt32 ycocg_dxt5 = kHapPixelFormatTypeYCoCg_DXT5;
    
    const void *formatNumbers[3] = {
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &rgb_dxt1),
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &rgba_dxt5),
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &ycocg_dxt5)
    };
    
    CFArrayRef formats = CFArrayCreate(kCFAllocatorDefault, formatNumbers, 3, &kCFTypeArrayCallBacks);
    
    CFRelease(formatNumbers[0]);
    CFRelease(formatNumbers[1]);
    CFRelease(formatNumbers[2]);
    
    const void *keys[2] = { kCVPixelBufferPixelFormatTypeKey, kCVPixelBufferOpenGLCompatibilityKey };
    const void *values[2] = { formats, kCFBooleanTrue };
    
    CFDictionaryRef dictionary = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    CFRelease(formats);
    
    return dictionary;
}
