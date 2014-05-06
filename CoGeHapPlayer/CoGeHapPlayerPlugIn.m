//
//  CoGeHapPlayerPlugIn.h
//  CoGeHapPlayer
//
//  Created by Tamas Nagy on 10/12/13.
//  Copyright (c) 2013 Tamas Nagy. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "CoGeHapPlayerPlugIn.h"

#define	kQCPlugIn_Name				@"CoGeHapPlayer"
#define	kQCPlugIn_Description		@"A basic movie player plugin with support for GPU accelerated playback of Hap movie files"




@implementation CoGeHapPlayerPlugIn

/*
 Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
 @dynamic inputFoo, outputBar;
 */

@dynamic inputMoviePath, inputRate, inputVolume,  inputPlayhead, inputLoopMode;
@dynamic outputMovieFinished, outputImage, outputMovieTime;

@synthesize workingLoopMode;
@synthesize workingRate;
@synthesize workingVolume;
@synthesize movieChanged;
@synthesize movieOKToPlayBack;
@synthesize movieSize;
@synthesize isPlaybackHAPMovie;


+ (NSDictionary*) attributes
{
	/*
	 Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
	 */
	
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/*
	 Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
	 */
	
    if([key isEqualToString:@"inputMoviePath"])
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeString, QCPortAttributeTypeKey,
				@"Movie Location", QCPortAttributeNameKey,
				@"",  QCPortAttributeDefaultValueKey,
				
				nil];
    
	if([key isEqualToString:@"inputRate"])
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeNumber, QCPortAttributeTypeKey,
				@"Rate", QCPortAttributeNameKey,
				[NSNumber numberWithDouble:1], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithDouble:1], QCPortAttributeMaximumValueKey,
				
				nil];
    
	if([key isEqualToString:@"inputVolume"])
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeNumber, QCPortAttributeTypeKey,
				@"Volume", QCPortAttributeNameKey,
				[NSNumber numberWithDouble:1], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithDouble:1], QCPortAttributeMaximumValueKey,
				
				nil];

    if([key isEqualToString:@"inputPlayhead"])
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeNumber, QCPortAttributeTypeKey,
				@"Playhead", QCPortAttributeNameKey,
				[NSNumber numberWithDouble:0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithDouble:1], QCPortAttributeMaximumValueKey,
				
				nil];
    

    if([key isEqualToString:@"inputLoopMode"])
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeIndex, QCPortAttributeTypeKey,
				@"Loop Mode", QCPortAttributeNameKey,
                [NSArray arrayWithObjects:@"Loop", @"Mirrored Loop", @"No Loop",nil], QCPortAttributeMenuItemsKey,
				[NSNumber numberWithDouble:0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithDouble:2], QCPortAttributeMaximumValueKey,

				nil];

    if([key isEqualToString:@"output Image"])
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeImage, QCPortAttributeTypeKey,
				@"Output Image", QCPortAttributeNameKey,
				nil];

    if([key isEqualToString:@"outputMovieFinished"])
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeBoolean, QCPortAttributeTypeKey,
				@"Movie Finished", QCPortAttributeNameKey,
				[NSNumber numberWithDouble:0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithDouble:1], QCPortAttributeMaximumValueKey,
				nil];

    if([key isEqualToString:@"outputMovieTime"])
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeNumber, QCPortAttributeTypeKey,
				@"Movie Time", QCPortAttributeNameKey,
				[NSNumber numberWithDouble:0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithDouble:1], QCPortAttributeMaximumValueKey,
				
				nil];

	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/*
	 Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	 */
	
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	/*
	 Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	 */
	
	return kQCPlugInTimeModeIdle;
}

- (id) init
{
	if(self = [super init]) {
		/*
		 Allocate any permanent resource required by the plug-in.
		 */
        
	}
	
	return self;
}

- (void) finalize
{
	/*
	 Release any non garbage collected resources created in -init.
	 */
	
	[super finalize];
}

- (void) dealloc
{
	/*
	 Release any resources created in -init.
	 */
	
	[super dealloc];
}


@end

@implementation CoGeHapPlayerPlugIn (Execution)


- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	/*
	 Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	 Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	 */
	//	NSLog(@"startExecution");
    
    
    currentmovie = nil;
	
    
    if (_latestTextureFrame != NULL) {
        
        CVBufferRelease(_latestTextureFrame);
        
    }
    
    _latestTextureFrame = NULL;
    
    
    _context = CGLRetainContext([context CGLContextObj]);
    
    [self initVisualContexts];
    
    movieFinished = NO;
    
	return YES;
}

-(void)initVisualContexts {
    
    if (_visualContextHAP) {
        
        QTVisualContextRelease(_visualContextHAP);
        _visualContextHAP = NULL;
    }
    
    if (_visualContextTexture) {
        
        QTVisualContextRelease(_visualContextTexture);
        _visualContextTexture = NULL;
    }
    
    CFDictionaryRef pixelBufferOptions = HapQTCreateCVPixelBufferOptionsDictionary();
    
    // QT Visual Context attributes
    NSDictionary *visualContextOptions = [NSDictionary dictionaryWithObject:(NSDictionary *)pixelBufferOptions
                                                                     forKey:(NSString *)kQTVisualContextPixelBufferAttributesKey];
    
    CFRelease(pixelBufferOptions);
    
    OSStatus error = QTPixelBufferContextCreate(kCFAllocatorDefault, (CFDictionaryRef)visualContextOptions, &_visualContextHAP);
    
    if (error != noErr)
    {
        NSLog(@"err %ld, couldnt create  Hap visual context at %s", error, __func__);
    }
    
    NSMutableDictionary* pixelBufferDict = [NSMutableDictionary dictionary];
    [pixelBufferDict setValue:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferOpenGLCompatibilityKey];
    
    
    error = QTOpenGLTextureContextCreate(kCFAllocatorDefault,
                                         _context,
                                         CGLGetPixelFormat(_context),
                                         (CFDictionaryRef)pixelBufferDict,
                                         &_visualContextTexture);
    
    //
    // if this options are enabled we can get an error/warning logged on 10.9: CGCMSUtilsGetICCProfileDescription
    //
    //    QTVisualContextSetAttribute(_visualContextTexture,kQTVisualContextWorkingColorSpaceKey, CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB));
    //    QTVisualContextSetAttribute(_visualContextTexture,kQTVisualContextOutputColorSpaceKey, CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB));
    
    if (error != noErr)
    {
        NSLog(@"err %ld, couldnt create Texture visual context at %s", error, __func__);
    }
    
    
}


- (void) enableExecution:(id<QCPlugInContext>)context
{
	//	NSLog(@"enableExecution");
	/*
	 Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
	 */
	
	
}

-(BOOL)canHandleFileAtURL:(NSURL *)_url {
    
	NSString *fileuti = nil;
	[_url getResourceValue:&fileuti forKey:NSURLTypeIdentifierKey error:nil];
	
	if ([fileuti isEqualToString:@"com.apple.quartz-composer-composition"]) {
		
		return NO;
	}
    
    //  [fileuti release];
	
	return YES;
}



-(void)stopActualMovie {
    
    if (currentmovie) {
        
        
		[currentmovie stop];
        [currentmovie gotoBeginning];
        SetMovieVisualContext([currentmovie quickTimeMovie], NULL);
        //[currentmovie setVisualContext:NULL];
        
        //not sure about calling autorelease is safe here
        //but seems it not producing leaking memory
        //and its much faster calling autorelease here then release
        //which really speeds up triggering speed
		[currentmovie autorelease];
        currentmovie = nil;
        
        
	}
}

-(void)triggerNewFile:(NSString *)path {
    
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self stopActualMovie];
    
    [self setMovieChanged:YES];

    movieFinished = NO;

    NSURL *newurl = [NSURL fileURLWithPath:[path stringByStandardizingPath]];
    
     if (([QTMovie canInitWithFile:path]) && ([self canHandleFileAtURL:newurl])) {
        
        
        
        NSMutableDictionary* movieAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                newurl, QTMovieURLAttribute,
                                                [NSNumber numberWithBool:NO],QTMovieLoopsAttribute,
                                                [NSNumber numberWithBool:NO],QTMovieLoopsBackAndForthAttribute,
                                                [NSNumber numberWithBool:YES], QTMovieOpenAsyncOKAttribute,
                                                [NSNumber numberWithBool:NO], QTMovieOpenForPlaybackAttribute,
                                                [NSNumber numberWithBool:YES], QTMovieEditableAttribute,
                                                //[NSNumber numberWithBool:YES], QTMovieOpenAsyncRequiredAttribute,
                                                nil];
        
        
        currentmovie = [[QTMovie alloc] initWithAttributes:movieAttributes error:NULL];
        
        [self setVisualContextForCurrentMovie];
        [self setMovieLoopMode];
        
        [currentmovie gotoBeginning];
        
        [self setVolume];
        
        [self setRate];
        
        // NSLog(@"movie inited");
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDidEnd:) name:QTMovieDidEndNotification object:currentmovie];

        
        movieFinished = NO;
        
    }

}


-(void)stopCurrent {
	
	if ([self isCurrentMoviePlayable]) {
        [currentmovie setRate:0.0f];
	}
	
}

-(void)setRate {
    
    if (currentmovie) {
        movieFinished = NO;
        [currentmovie setRate:[self workingRate]];
    }
	
}

-(void)setVolume {
	
    if (currentmovie) {
        [currentmovie setVolume:[self workingVolume]];
    }
	
}

-(void)setVisualContextForCurrentMovie {
    
    if (HapQTMovieHasHapTrackPlayable(currentmovie))
    {
        
        if (![self isPlaybackHAPMovie]) {
            
            [self setIsPlaybackHAPMovie:YES];
            
        }
        
        _visualContext = _visualContextHAP;
        
        
    } else {
        
        NSSize currentMovieSize;
        [[currentmovie attributeForKey:QTMovieNaturalSizeAttribute] getValue:&currentMovieSize];
    
        
        NSMutableDictionary* pixelBufferDict = [NSMutableDictionary dictionary];
        [pixelBufferDict setValue:[NSNumber numberWithInt:currentMovieSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
        [pixelBufferDict setValue:[NSNumber numberWithInt:currentMovieSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
        //we should set this attribute again to fix a bug on 10.9
        [pixelBufferDict setValue:[NSNumber numberWithBool:YES] forKey:(NSString*)kCVPixelBufferOpenGLCompatibilityKey];
        QTVisualContextSetAttribute(_visualContextTexture,kQTVisualContextPixelBufferAttributesKey, (CFDictionaryRef)pixelBufferDict);
       
        
        
        if ([self isPlaybackHAPMovie]) {
            
            
            [self setIsPlaybackHAPMovie:NO];
            
        }
        
        _visualContext = _visualContextTexture;
        
    }
    
    //... and then reassociate so that movies which change their aperture or transport stream like the new size.
    SetMovieVisualContext([currentmovie quickTimeMovie], _visualContext);
    
}

-(void)getMovieSize {
	
	
	
	if (currentmovie != nil) {
		
		NSSize currentMovieSize;
        [[currentmovie attributeForKey:QTMovieNaturalSizeAttribute] getValue:&currentMovieSize];
        // from the v002 Movie Player - thanks Vade and Tom!
        // this is the MAGIC CODE that dings the QTVisualContext into outputting "square pixel" textures that QC is happy with.
 		[self setMovieSize:currentMovieSize];
        
        
	}
	
	
	self.movieOKToPlayBack =  ((!NSEqualSizes([self movieSize], NSZeroSize)) && (((currentmovie != nil) && ([[currentmovie attributeForKey:QTMovieLoadStateAttribute] longValue] >= QTMovieLoadStatePlayable))));
	
	//	NSLog(@"movieOKToPlayBack1: %d", self.movieOKToPlayBack);
	
}

-(BOOL)isCurrentMoviePlayable {
    
    if (![self movieChanged]) return YES;
		
	if (NSEqualSizes([self movieSize], NSZeroSize) || ([self movieChanged] == YES))  {
		[self getMovieSize];
		
		if ((!NSEqualSizes([self movieSize], NSZeroSize)) && (self.movieOKToPlayBack)) {
			[self setMovieChanged:NO];
            
		}
	}
	
	
	return self.movieOKToPlayBack;
	
}



-(void)setMoviePlayhead:(NSNumber *)newtime {
    
    
    if (currentmovie) {
    
        movieFinished = NO;

        QTTime duration = [currentmovie duration];
        NSNumber *scale = [currentmovie attributeForKey:QTMovieTimeScaleAttribute];
        
        QTTime currentTime = QTMakeTime([newtime floatValue] * duration.timeValue, [scale floatValue]);
        
        [currentmovie setCurrentTime:currentTime];

    }
	   
}

-(void)movieDidEnd:(NSNotification *)note {
    
    movieFinished = YES;
}

-(void)setMovieLoopMode {
    
    if (currentmovie) {
        
        movieFinished = NO;

    
        switch ([self workingLoopMode]) {
                //simple loop
            case 0:
                //it seems we don't need this
                //using this stops playback with backward playback mode when movie start time reached
                [currentmovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
                [currentmovie setAttribute:[NSNumber numberWithBool:NO] forKey:QTMovieLoopsBackAndForthAttribute];
                break;
                //mirrored loop
            case 1:
                //	NSLog(@"mirrored loop mode, go backwards!");
                [currentmovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
                [currentmovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsBackAndForthAttribute];
                break;
                // no loop, hold last
            case 2:
                //no loop
                [currentmovie setAttribute:[NSNumber numberWithBool:NO] forKey:QTMovieLoopsAttribute];
                [currentmovie setAttribute:[NSNumber numberWithBool:NO] forKey:QTMovieLoopsBackAndForthAttribute];
                
                break;
                // trigger next
        }

    }
    
}


- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	/*
	 Called by Quartz Composer whenever the plug-in instance needs to execute.
	 Only read from the plug-in inputs and produce a result (by writing to the plug-in outputs or rendering to the destination OpenGL context) within that method and nowhere else.
	 Return NO in case of failure during the execution (this will prevent rendering of the current frame to complete).
	 
	 The OpenGL context for rendering can be accessed and defined for CGL macros using:
	 CGLContextObj cgl_ctx = [context CGLContextObj];
	 */
    
	if ([self didValueForInputKeyChange:@"inputMoviePath"]) {
        
        NSString *path = self.inputMoviePath;
        
        if (![path isAbsolutePath]) {
            
            path = [NSString stringWithString:[NSString pathWithComponents:[NSArray arrayWithObjects:[[[context compositionURL] path] stringByDeletingLastPathComponent], path, nil]]];

        }
        
        if (![[NSThread currentThread] isMainThread]) {
        
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [self triggerNewFile:path];
                
            });
            

        } else {
        
            [self triggerNewFile:path];
            
        }
        
	}
    
	if ([self didValueForInputKeyChange:@"inputRate"]) {
		
		[self setWorkingRate:self.inputRate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setRate];
        });
		
	}
	
	if ([self didValueForInputKeyChange:@"inputVolume"]) {
		
		[self setWorkingVolume:self.inputVolume];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setVolume];
        });
		
		
	}
	
	
	if ([self didValueForInputKeyChange:@"inputLoopMode"]) {
		
		[self setWorkingLoopMode:self.inputLoopMode];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setMovieLoopMode];
            [self setRate];
        });

	}
	
		
#pragma mark Rendering
    
    
    
	if ([self isCurrentMoviePlayable]) {
				
		movieFinished = NO;
		
		
		if ([self didValueForInputKeyChange:@"inputPlayhead"]) {
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setMoviePlayhead:[NSNumber numberWithDouble:self.inputPlayhead]];
            });
            
			
		}
        
        if (provider) {
            [provider release];
            provider = NULL;
        }
        
		[self performSelector:@selector(grabActualFrame)];
        
        
		if (_latestTextureFrame != NULL)
		{
            
            if ([self isPlaybackHAPMovie]) {
                
                
                if (hapTexture == nil)
                {
                    hapTexture = [[HapPixelBufferTexture alloc] initWithContext:[context CGLContextObj]];
                }
                
                hapTexture.buffer = _latestTextureFrame;
                
                NSSize imageSize = NSMakeSize(hapTexture.width, hapTexture.height);
                NSSize textureSize = NSMakeSize(hapTexture.textureWidth, hapTexture.textureHeight);
                
                provider = [[CoGeHapImageProvider alloc] initWithTexture:hapTexture.textureName target:GL_TEXTURE_2D imageSize:imageSize textureSize:textureSize flipped:YES shader:hapTexture.shaderProgramObject];
                
                
            } else {
                
                
                provider = [[CoGeHapImageProvider alloc] initWithTexture:CVOpenGLTextureGetName(_latestTextureFrame) target:CVOpenGLTextureGetTarget(_latestTextureFrame) imageSize:[self movieSize] textureSize:[self movieSize] flipped:CVOpenGLTextureIsFlipped(_latestTextureFrame) shader:NULL];
                
                
            }
            
			
			
			
			
		} else {
            
            provider = NULL;
            
        }
		
		
		double actualtime = [self movieNormalizedTime];
		self.outputMovieTime = actualtime;
		
		
	} else {
		
 		
		provider = NULL;
		self.outputMovieTime = 0.0f;
		
	}
    
	
#pragma mark Outputs
	
	self.outputImage = provider;
	self.outputMovieFinished = movieFinished;
    
    if (_visualContext != NULL) {
        
        QTVisualContextTask(_visualContext);
        
    }
    
	return YES;
}


//this one from V002 MoviePlayer
- (void)grabActualFrame
{
    
	if (_visualContext != NULL) {
        
		if (QTVisualContextIsNewImageAvailable(_visualContext, NULL))
		{
			if (_latestTextureFrame != NULL)
			{
				CVBufferRelease(_latestTextureFrame);
				_latestTextureFrame = NULL;
			}
            
            CVReturn ret = QTVisualContextCopyImageForTime(_visualContext, NULL, NULL, &_latestTextureFrame);
			
			if (ret != kCVReturnSuccess) {
				NSLog(@"problem with QTVisualContextCopyImageForTime! %d", ret);
			
            } else {
                
                //   if (_latestTextureFrame != NULL) NSLog(@"OK!");
                
            }
		}
        
        
        
        
		
	}
	
    
}


-(double)movieNormalizedTime
{
	
    if (currentmovie) {
		
        QTTime duration = [currentmovie duration];
        QTTime currentTime = [currentmovie currentTime];
        return ((float)currentTime.timeValue/(float)duration.timeValue);
		
    }
	
    return 0.0f;

}


- (void) disableExecution:(id<QCPlugInContext>)context
{
	/*
	 Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
	 */
	
	if ([self isCurrentMoviePlayable]) {
       
        if (![[NSThread currentThread] isMainThread]) {
        
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self stopCurrent];
            });

        } else {
            
            [self stopCurrent];
        }
        
	}
	
    NSLog(@"disableExecution");
	
}

-(void)cleanUpOnStop {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [self stopActualMovie];
    
    
	if (_latestTextureFrame) {
		CVBufferRelease(_latestTextureFrame);
        _latestTextureFrame = NULL;
	}
	
	if (_visualContext != NULL) {
		_visualContext = NULL;
	}
	
	if (_visualContextHAP != NULL) {
        QTVisualContextRelease(_visualContextHAP);
		_visualContextHAP = NULL;
	}
    
    if (_visualContextTexture != NULL) {
        QTVisualContextRelease(_visualContextTexture);
		_visualContextTexture = NULL;
	}
    
    if (hapTexture != nil) {
        
        [hapTexture release];
        hapTexture = nil;
    }
    
    CGLReleaseContext(_context);
	
    NSLog(@"cleanup done!");
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/*
	 Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
	 */
	
	NSLog(@"stopExecution on CoGeHapPlayer");
	
    if (![[NSThread currentThread] isMainThread]) {

        dispatch_sync(dispatch_get_main_queue(), ^{
            [self cleanUpOnStop];
        });

    } else {
        
        [self cleanUpOnStop];
    }

}

@end

@implementation CoGeHapImageProvider

//
// Based on v002 Movie Player
//
-(id)initWithTexture:(GLuint)_tex target:(GLenum)_target imageSize:(NSSize)_size textureSize:(NSSize)_texsize flipped:(BOOL)flip shader:(GLhandleARB)_shader
{
	if(self = [super init])
	{
		imageBounds = NSMakeRect(0, 0, _size.width, _size.height);
		
		target = _target;
		textureName = _tex;
        textureSize = _texsize;
        imageSize = _size;
        isFlipped = flip;
        shader = _shader;
        
        _colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	}
	return self;
}

-(NSRect) imageBounds
{
	return imageBounds;
}

- (BOOL)shouldColorMatch
{
	return YES;
}

-(void)finalize {
    
    CGColorSpaceRelease(_colorspace);
    
    [super finalize];
}

-(void)dealloc {
    
    // if (textureName != 0) glDeleteTextures(1, &textureName);
    
    CGColorSpaceRelease(_colorspace);
    
    [super dealloc];
}

- (CGColorSpaceRef) imageColorSpace
{
	return _colorspace;
}

- (BOOL) canRenderWithCGLContext:(CGLContextObj)cgl_ctx
{
	return YES;
}


-(void)releaseRenderedTexture:(GLuint)name forCGLContext:(CGLContextObj)cgl_ctx
{
    //  glDeleteTextures(1, &name);
}

- (BOOL) renderWithCGLContext:(CGLContextObj)cgl_ctx forBounds:(NSRect)bounds
{
    
    
	glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_TRANSFORM_BIT);
	glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);
    
    //are this disables really needed?
    // glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glPushMatrix();
    
    //is this really needed?
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glPushMatrix();
    
    glViewport(0, 0, (GLsizei) bounds.size.width, (GLsizei) bounds.size.height);
    glOrtho(bounds.origin.x, bounds.origin.x+bounds.size.width, bounds.origin.y, bounds.origin.y+bounds.size.height, -1.0, 1.0);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    
    glClearColor(0.0,0.0,0.0,0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    
    glEnable(target);
    
    NSRect destRect = NSMakeRect(0,0,0,0);
    double bAspect = bounds.size.width/bounds.size.height;
    double aAspect = imageSize.width/imageSize.height;
    
    // if the rect i'm trying to fit stuff *into* is wider than the rect i'm resizing
    if (bAspect > aAspect)
    {
        destRect.size.height = bounds.size.height;
        destRect.size.width = destRect.size.height * aAspect;
    }
    // else if the rect i'm resizing is wider than the rect it's going into
    else if (bAspect < aAspect)
    {
        destRect.size.width = bounds.size.width;
        destRect.size.height = destRect.size.width / aAspect;
    }
    else
    {
        destRect.size.width = bounds.size.width;
        destRect.size.height = bounds.size.height;
    }
    destRect.origin.x = (bounds.size.width-destRect.size.width)/2.0+bounds.origin.x;
    destRect.origin.y = (bounds.size.height-destRect.size.height)/2.0+bounds.origin.y;
    
    GLfloat vertices[] =
    {
        destRect.origin.x,                          destRect.origin.y,
        destRect.origin.x+destRect.size.width,      destRect.origin.y,
        destRect.origin.x + destRect.size.width,    destRect.origin.y + destRect.size.height,
        destRect.origin.x,                          destRect.origin.y + destRect.size.height,
    };
    
    GLfloat texCoords[] =
    {
        0.0,        (isFlipped ? imageSize.height : 0.0),
        imageSize.width,   (isFlipped ? imageSize.height : 0.0),
        imageSize.width,   (isFlipped ? 0.0 : imageSize.height),
        0.0,        (isFlipped ? 0.0 : imageSize.height)
    };
    
    if (target == GL_TEXTURE_2D)
    {
        texCoords[1] /= (float)textureSize.height;
        texCoords[3] /= (float)textureSize.height;
        texCoords[5] /= (float)textureSize.height;
        texCoords[7] /= (float)textureSize.height;
        texCoords[2] /= (float)textureSize.width;
        texCoords[4] /= (float)textureSize.width;
    }
    
    glBindTexture(target,textureName);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glVertexPointer(2,GL_FLOAT,0,vertices);
    glTexCoordPointer(2,GL_FLOAT,0,texCoords);
    
    
    if (shader != NULL)
    {
        glUseProgramObjectARB(shader);
    }
    glDrawArrays(GL_QUADS,0,4);
    glDisableClientState( GL_TEXTURE_COORD_ARRAY );
    glDisableClientState(GL_VERTEX_ARRAY);
    
    
    if (shader != NULL)
    {
        glUseProgramObjectARB(NULL);
    }
    
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glPopClientAttrib();
    glPopAttrib();
    
	
	return YES;
}

@end

