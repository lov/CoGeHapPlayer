//
//  CoGeHapPlayerPlugIn.h
//  CoGeHapPlayer
//
//  Created by Tamas Nagy on 10/12/13.
//  Copyright (c) 2013 Tamas Nagy. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <QuickTime/QuickTime.h>
#import <QTKit/QTKit.h>
#import "HapSupport.h"
#import "HapPixelBufferTexture.h"

@interface CoGeHapPlayerPlugIn : QCPlugIn {

	QTMovie	*currentmovie;
	CVPixelBufferRef _latestTextureFrame;
	QTVisualContextRef _visualContext;
    
    QTVisualContextRef _visualContextTexture;
    QTVisualContextRef _visualContextHAP;
    
	id provider;
	
	NSSize movieSize;
	
	
	BOOL movieOKToPlayBack;
	
	BOOL movieFinished;
	
	CGLContextObj _context;
    
    HapPixelBufferTexture *hapTexture;
    
    float workingVolume;
	float workingRate;
	int workingLoopMode;
    BOOL isPlaybackHAPMovie;
    
	BOOL movieChanged;

}

@property (assign) NSString *inputMoviePath;
@property (assign) NSUInteger inputLoopMode;
@property (assign) double inputRate;
@property (assign) double inputPlayhead;
@property (assign) double inputVolume;

@property (assign) id <QCPlugInOutputImageProvider> outputImage;
@property (assign) BOOL outputMovieFinished;
@property (assign) double outputMovieTime;

@property (assign) NSSize movieSize;

@property (assign) float workingVolume;
@property (assign) float workingRate;
@property (assign) int workingLoopMode;
@property (assign) 	BOOL isPlaybackHAPMovie;
@property (assign) BOOL movieOKToPlayBack;
@property (assign) BOOL movieChanged;


@end

@interface CoGeHapImageProvider : NSObject <QCPlugInOutputImageProvider>
{
	NSRect imageBounds;
	GLfloat lowerLeft[2],lowerRight[2],upperRight[2],upperLeft[2];
	GLenum target;
	GLuint textureName;
    NSSize textureSize;
    NSSize imageSize;
    BOOL isFlipped;
    GLhandleARB shader;
    GLint previousFBO;
    GLint previousReadFBO;
    GLint previousDrawFBO;
    
    CGColorSpaceRef _colorspace;
    
}
-(id)initWithTexture:(GLuint)_tex target:(GLenum)_target imageSize:(NSSize)_size textureSize:(NSSize)_texsize flipped:(BOOL)flip shader:(GLhandleARB)_shader;

-(BOOL)shouldColorMatch;
-(NSRect) imageBounds;
-(CGColorSpaceRef)imageColorSpace;

-(BOOL)canRenderWithCGLContext:(CGLContextObj)cgl_ctx;
-(BOOL)renderWithCGLContext:(CGLContextObj)cgl_ctx forBounds:(NSRect)bounds;

@end
